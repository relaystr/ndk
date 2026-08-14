//! Post-quantum hybrid encryption for Nostr direct messages.
//!
//! This is the confidentiality half of the post-quantum problem, and it is the half
//! worth solving now. A Nostr pubkey is published to every relay it touches, and
//! NIP-44 derives its conversation key from a secp256k1 ECDH secret — so anyone
//! archiving encrypted events today can decrypt all of them the day secp256k1 falls.
//! That is "harvest now, decrypt later", and unlike forgery it can be pre-empted:
//! a message protected today stays confidential permanently.
//!
//! The signature half — which `qs_*` in `lib.rs` addresses with Dilithium — cannot be
//! pre-empted. It only helps once the ecosystem stops accepting secp256k1 signatures.
//! The two are complementary, not alternatives.
//!
//! # Wire format
//!
//! ```text
//! version   1 byte    0x01
//! alg       1 byte    0x01 = ML-KEM-1024 + NIP-44 conversation key, XChaCha20-Poly1305
//! kem_ct    1568      ML-KEM-1024 ciphertext
//! nonce     24        XChaCha20-Poly1305 nonce
//! sealed    variable  AEAD(padded plaintext), includes the 16-byte tag
//! ```
//!
//! base64-encoded for transport.
//!
//! # Interoperability
//!
//! Byte-compatible with `@nostr-wot/pq` (TypeScript), which is what the Nostr WoT
//! browser extension ships. `tests` below pin the derivation, the hybrid key and a
//! complete envelope produced by that implementation, so a change here that breaks
//! cross-client messaging fails the suite rather than reaching users.
//!
//! One deliberate asymmetry: we decode base64 strictly (canonical, padded), while the
//! TypeScript side decodes leniently. Every canonical encoder interoperates; a
//! non-canonically-encoded envelope is rejected here and accepted there. Strict on
//! receive is the safer side of that difference to be on.
//!
//! # Design notes
//!
//! - **Hybrid, never bare.** The ML-KEM shared secret is combined with the classic
//!   NIP-44 conversation key through HKDF, so the result is no weaker than either
//!   input. A break in a comparatively young lattice scheme must not be able to make
//!   Nostr messaging *worse* than it is today.
//! - **Its own version byte, not NIP-44's**, so this can be adopted, renumbered or
//!   superseded without squatting a number in a registry it does not own.
//! - **The framing is authenticated.** Version, algorithm and both pubkeys go into the
//!   AEAD's associated data, so a ciphertext cannot be replayed into another
//!   conversation, have its direction swapped, or have its algorithm byte downgraded.
//! - **Length is padded** with NIP-44's scheme, so ciphertext size does not leak
//!   message size on a public relay.
//! - **One generic error.** Every failure path returns 0. Distinguishing bad padding
//!   from a bad tag from a wrong key hands an attacker an oracle.

use std::ffi::{c_char, CStr};
use std::slice;

use base64::{engine::general_purpose::STANDARD as B64, Engine};
use chacha20poly1305::aead::{Aead, KeyInit, Payload};
use chacha20poly1305::{Key, XChaCha20Poly1305, XNonce};
use hkdf::Hkdf;
use ml_kem::kem::Decapsulate;
use ml_kem::{Ciphertext, EncapsulateDeterministic, EncodedSizeUser, KemCore, MlKem1024, B32};
use sha2::Sha256;
use zeroize::Zeroize;

use crate::{write_buffer, QsBuffer};

/// Derivation profile. Bump when the derivation changes.
const PROFILE: &str = "nip-pqc/v1";

const ENVELOPE_VERSION: u8 = 0x01;
const ALG_MLKEM1024_XCHACHA: u8 = 0x01;

const KEM_PUBLIC_KEY_BYTES: usize = 1568;
const KEM_CIPHERTEXT_BYTES: usize = 1568;
const NONCE_BYTES: usize = 24;
const TAG_BYTES: usize = 16;
const HEADER_BYTES: usize = 2 + KEM_CIPHERTEXT_BYTES + NONCE_BYTES;
const CONVERSATION_KEY_BYTES: usize = 32;
const MAX_PLAINTEXT_BYTES: usize = 65535;
/// A BIP-39 seed is always 64 bytes, whatever the mnemonic length.
const SEED_BYTES: usize = 64;
const PUBKEY_HEX_LEN: usize = 64;

// ── Key derivation ──────────────────────────────────────────────────────────

fn hkdf_derive(ikm: &[u8], info: &str, len: usize) -> Vec<u8> {
    let hk = Hkdf::<Sha256>::new(None, ikm);
    let mut out = vec![0u8; len];
    // Only fails when `len` exceeds 255 * HashLen; ours are fixed and small.
    hk.expand(info.as_bytes(), &mut out)
        .expect("HKDF output length is within bounds");
    out
}

/// The `info` string for the ML-KEM seed at a NIP-06 account index.
fn kem_info(account: u32) -> String {
    format!("{PROFILE}/ml-kem-1024/{account}")
}

/// Combine the post-quantum shared secret with the classic NIP-44 conversation key.
///
/// The KEM secret MUST NOT be used alone.
fn hybrid_key(shared: &[u8], conversation_key: &[u8]) -> Vec<u8> {
    let mut ikm = Vec::with_capacity(shared.len() + conversation_key.len());
    ikm.extend_from_slice(shared);
    ikm.extend_from_slice(conversation_key);
    let key = hkdf_derive(&ikm, &format!("{PROFILE}/hybrid"), 32);
    ikm.zeroize();
    key
}

/// Derive an ML-KEM-1024 keypair from a BIP-39 seed.
///
/// The seed, NOT a secp256k1 private key. Deriving from the private key would be
/// circular: an adversary who recovers it from the published pubkey repeats the
/// derivation and obtains this key too. Because HKDF is one-way, deriving both keys
/// independently from the seed means breaking secp256k1 reveals nothing here.
fn derive_kem_keypair(seed: &[u8], account: u32) -> Option<(Vec<u8>, Vec<u8>)> {
    // A BIP-39 seed is always 64 bytes. Requiring exactly that blocks the misuse this
    // whole design exists to prevent: passing the 32-byte secp256k1 private key (or a
    // 33-byte pubkey) as the seed, which would make recovering the post-quantum key
    // exactly as hard as breaking secp256k1 — i.e. not hard at all, once it breaks.
    //
    // It cannot detect a 12-word origin: PBKDF2 stretches any mnemonic to 64 bytes, so
    // a 128-bit mnemonic yields a well-formed seed carrying only 128 bits. That check
    // belongs at the mnemonic layer, and the caller must enforce 24 words before
    // deriving keys it intends to advertise as seed-derived.
    if seed.len() != SEED_BYTES {
        return None;
    }
    let mut kem_seed = hkdf_derive(seed, &kem_info(account), 64);
    let d = B32::try_from(&kem_seed[0..32]).ok()?;
    let z = B32::try_from(&kem_seed[32..64]).ok()?;
    let (dk, ek) = MlKem1024::generate_deterministic(&d, &z);
    kem_seed.zeroize();
    Some((ek.as_bytes().to_vec(), dk.as_bytes().to_vec()))
}

// ── Padding (NIP-44 scheme) ─────────────────────────────────────────────────

fn calc_padded_len(len: usize) -> usize {
    // Load-bearing: the shift below overflows for len-1 >= 2^63. Both callers bound
    // len to MAX_PLAINTEXT_BYTES first, so this documents the guard rather than adding one.
    debug_assert!(len <= MAX_PLAINTEXT_BYTES);
    if len <= 32 {
        return 32;
    }
    let next_power = 1usize << (usize::BITS - (len - 1).leading_zeros());
    let chunk = if next_power <= 256 { 32 } else { next_power / 8 };
    chunk * ((len - 1) / chunk + 1)
}

fn pad(plaintext: &[u8]) -> Option<Vec<u8>> {
    if plaintext.is_empty() || plaintext.len() > MAX_PLAINTEXT_BYTES {
        return None;
    }
    let mut out = vec![0u8; 2 + calc_padded_len(plaintext.len())];
    out[0..2].copy_from_slice(&(plaintext.len() as u16).to_be_bytes());
    out[2..2 + plaintext.len()].copy_from_slice(plaintext);
    Some(out)
}

fn unpad(padded: &[u8]) -> Option<Vec<u8>> {
    if padded.len() < 2 {
        return None;
    }
    let len = u16::from_be_bytes([padded[0], padded[1]]) as usize;
    if len == 0 || len > MAX_PLAINTEXT_BYTES || padded.len() < 2 + len {
        return None;
    }
    // The declared length must match the padding the sender should have produced.
    if padded.len() != 2 + calc_padded_len(len) {
        return None;
    }
    Some(padded[2..2 + len].to_vec())
}

// ── Associated data ─────────────────────────────────────────────────────────

/// An x-only secp256k1 pubkey as it appears on the wire: 64 lowercase hex characters.
///
/// The associated data joins both pubkeys with `:`, so an unvalidated party string
/// containing a colon would make distinct conversations produce identical associated
/// data — sealing as `("aaaa:bbbb", "cccc")` would open as `("aaaa", "bbbb:cccc")`,
/// defeating exactly the binding this construction advertises. Validating is
/// wire-compatible: it rejects nothing a conforming implementation would ever send.
///
/// Case matters too. Uppercase hex produces different associated data, so it would
/// interoperate with nothing; rejecting it turns a silent cross-client failure into a
/// loud one at the boundary.
fn is_xonly_hex(s: &str) -> bool {
    s.len() == PUBKEY_HEX_LEN && s.bytes().all(|b| matches!(b, b'0'..=b'9' | b'a'..=b'f'))
}

/// Bind the framing to the ciphertext: both pubkeys so a ciphertext cannot be replayed
/// into another conversation, and the algorithm byte so it cannot be downgraded.
fn associated_data(alg: u8, sender: &str, recipient: &str, kem_ct: &[u8]) -> Vec<u8> {
    let mut ad =
        format!("{PROFILE}/env:{ENVELOPE_VERSION}:{alg}:{sender}:{recipient}:").into_bytes();
    ad.extend_from_slice(kem_ct);
    ad
}

// ── Seal / open ─────────────────────────────────────────────────────────────

fn seal(
    recipient_kem_key: &[u8],
    conversation_key: &[u8],
    sender: &str,
    recipient: &str,
    plaintext: &[u8],
) -> Option<String> {
    if recipient_kem_key.len() != KEM_PUBLIC_KEY_BYTES
        || conversation_key.len() != CONVERSATION_KEY_BYTES
        || !is_xonly_hex(sender)
        || !is_xonly_hex(recipient)
    {
        return None;
    }

    let ek_enc = ml_kem::Encoded::<<MlKem1024 as KemCore>::EncapsulationKey>::try_from(
        recipient_kem_key,
    )
    .ok()?;
    let ek = <MlKem1024 as KemCore>::EncapsulationKey::from_bytes(&ek_enc);

    // ML-KEM security depends on `m` being uniformly random. The crate's deterministic
    // feature is enabled for seed-based keygen, so we supply the randomness ourselves.
    let mut m_bytes = [0u8; 32];
    getrandom::getrandom(&mut m_bytes).ok()?;
    let m = B32::try_from(&m_bytes[..]).ok()?;
    let (ct, mut shared) = ek.encapsulate_deterministic(&m).ok()?;
    m_bytes.zeroize();

    let mut nonce_bytes = [0u8; NONCE_BYTES];
    getrandom::getrandom(&mut nonce_bytes).ok()?;

    let mut key = hybrid_key(shared.as_slice(), conversation_key);
    shared.as_mut_slice().zeroize();
    let aead = XChaCha20Poly1305::new(Key::from_slice(&key));
    let ad = associated_data(ALG_MLKEM1024_XCHACHA, sender, recipient, ct.as_slice());
    let mut padded = pad(plaintext)?;
    let sealed = aead
        .encrypt(
            XNonce::from_slice(&nonce_bytes),
            Payload { msg: &padded, aad: &ad },
        )
        .ok();
    padded.zeroize();
    key.zeroize();
    let sealed = sealed?;

    let mut out = Vec::with_capacity(HEADER_BYTES + sealed.len());
    out.push(ENVELOPE_VERSION);
    out.push(ALG_MLKEM1024_XCHACHA);
    out.extend_from_slice(ct.as_slice());
    out.extend_from_slice(&nonce_bytes);
    out.extend_from_slice(&sealed);
    Some(B64.encode(out))
}

fn open(
    payload: &str,
    kem_secret_key: &[u8],
    conversation_key: &[u8],
    sender: &str,
    recipient: &str,
) -> Option<Vec<u8>> {
    if conversation_key.len() != CONVERSATION_KEY_BYTES
        || !is_xonly_hex(sender)
        || !is_xonly_hex(recipient)
    {
        return None;
    }
    let bytes = B64.decode(payload).ok()?;
    if bytes.len() < HEADER_BYTES + TAG_BYTES
        || bytes[0] != ENVELOPE_VERSION
        || bytes[1] != ALG_MLKEM1024_XCHACHA
    {
        return None;
    }

    let kem_ct = &bytes[2..2 + KEM_CIPHERTEXT_BYTES];
    let nonce = &bytes[2 + KEM_CIPHERTEXT_BYTES..HEADER_BYTES];
    let sealed = &bytes[HEADER_BYTES..];

    let dk_enc =
        ml_kem::Encoded::<<MlKem1024 as KemCore>::DecapsulationKey>::try_from(kem_secret_key)
            .ok()?;
    let dk = <MlKem1024 as KemCore>::DecapsulationKey::from_bytes(&dk_enc);
    let ct = Ciphertext::<MlKem1024>::try_from(kem_ct).ok()?;
    let mut shared = dk.decapsulate(&ct).ok()?;

    let mut key = hybrid_key(shared.as_slice(), conversation_key);
    shared.as_mut_slice().zeroize();
    let aead = XChaCha20Poly1305::new(Key::from_slice(&key));
    let ad = associated_data(ALG_MLKEM1024_XCHACHA, sender, recipient, kem_ct);
    let opened = aead
        .decrypt(XNonce::from_slice(nonce), Payload { msg: sealed, aad: &ad })
        .ok();
    key.zeroize();
    let mut opened = opened?;
    let out = unpad(&opened);
    opened.zeroize();
    out
}

fn is_envelope(payload: &str) -> bool {
    match B64.decode(payload) {
        Ok(b) => {
            b.len() >= HEADER_BYTES + TAG_BYTES
                && b[0] == ENVELOPE_VERSION
                && b[1] == ALG_MLKEM1024_XCHACHA
        }
        Err(_) => false,
    }
}

// ── FFI ─────────────────────────────────────────────────────────────────────

/// Derives an ML-KEM-1024 keypair from a BIP-39 seed at a NIP-06 account index.
///
/// Writes the public key into `out_pk` and the secret key into `out_sk`, returns 1.
/// Returns 0 on failure.
///
/// # Safety
/// `seed_ptr` must be valid for `seed_len` bytes; `out_pk` and `out_sk` must be valid
/// pointers to `QsBuffer`.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pq_derive_kem_keypair(
    seed_ptr: *const u8,
    seed_len: usize,
    account: u32,
    out_pk: *mut QsBuffer,
    out_sk: *mut QsBuffer,
) -> i32 {
    if seed_ptr.is_null() || out_pk.is_null() || out_sk.is_null() || seed_len == 0 {
        return 0;
    }
    let seed = unsafe { slice::from_raw_parts(seed_ptr, seed_len) };
    match derive_kem_keypair(seed, account) {
        Some((pk, sk)) => {
            unsafe {
                write_buffer(out_pk, pk);
                write_buffer(out_sk, sk);
            }
            1
        }
        None => 0,
    }
}

/// Seals a message into a post-quantum envelope.
///
/// `sender_ptr` and `recipient_ptr` are NUL-terminated hex x-only pubkeys; both are
/// bound into the AEAD's associated data. Writes the base64 envelope (as UTF-8 bytes)
/// into `out` and returns 1. Returns 0 on any failure.
///
/// # Safety
/// All pointers must be valid for their indicated lengths, and the two `c_char`
/// pointers must be NUL-terminated.
#[unsafe(no_mangle)]
#[allow(clippy::too_many_arguments)]
pub unsafe extern "C" fn pq_seal(
    kem_pk_ptr: *const u8,
    kem_pk_len: usize,
    conv_ptr: *const u8,
    conv_len: usize,
    sender_ptr: *const c_char,
    recipient_ptr: *const c_char,
    msg_ptr: *const u8,
    msg_len: usize,
    out: *mut QsBuffer,
) -> i32 {
    if kem_pk_ptr.is_null()
        || conv_ptr.is_null()
        || sender_ptr.is_null()
        || recipient_ptr.is_null()
        || msg_ptr.is_null()
        || out.is_null()
    {
        return 0;
    }
    let kem_pk = unsafe { slice::from_raw_parts(kem_pk_ptr, kem_pk_len) };
    let conv = unsafe { slice::from_raw_parts(conv_ptr, conv_len) };
    let msg = unsafe { slice::from_raw_parts(msg_ptr, msg_len) };
    let sender = match unsafe { CStr::from_ptr(sender_ptr) }.to_str() {
        Ok(s) => s,
        Err(_) => return 0,
    };
    let recipient = match unsafe { CStr::from_ptr(recipient_ptr) }.to_str() {
        Ok(s) => s,
        Err(_) => return 0,
    };

    match seal(kem_pk, conv, sender, recipient, msg) {
        Some(envelope) => {
            unsafe { write_buffer(out, envelope.into_bytes()) };
            1
        }
        None => 0,
    }
}

/// Opens a post-quantum envelope.
///
/// `payload_ptr` is a NUL-terminated base64 envelope. Writes the plaintext into `out`
/// and returns 1. Returns 0 on any failure — deliberately without distinguishing why,
/// since a caller that learns whether padding or the tag failed has an oracle.
///
/// # Safety
/// All pointers must be valid for their indicated lengths, and the `c_char` pointers
/// must be NUL-terminated.
#[unsafe(no_mangle)]
#[allow(clippy::too_many_arguments)]
pub unsafe extern "C" fn pq_open(
    payload_ptr: *const c_char,
    kem_sk_ptr: *const u8,
    kem_sk_len: usize,
    conv_ptr: *const u8,
    conv_len: usize,
    sender_ptr: *const c_char,
    recipient_ptr: *const c_char,
    out: *mut QsBuffer,
) -> i32 {
    if payload_ptr.is_null()
        || kem_sk_ptr.is_null()
        || conv_ptr.is_null()
        || sender_ptr.is_null()
        || recipient_ptr.is_null()
        || out.is_null()
    {
        return 0;
    }
    let payload = match unsafe { CStr::from_ptr(payload_ptr) }.to_str() {
        Ok(s) => s,
        Err(_) => return 0,
    };
    let sender = match unsafe { CStr::from_ptr(sender_ptr) }.to_str() {
        Ok(s) => s,
        Err(_) => return 0,
    };
    let recipient = match unsafe { CStr::from_ptr(recipient_ptr) }.to_str() {
        Ok(s) => s,
        Err(_) => return 0,
    };
    let kem_sk = unsafe { slice::from_raw_parts(kem_sk_ptr, kem_sk_len) };
    let conv = unsafe { slice::from_raw_parts(conv_ptr, conv_len) };

    match open(payload, kem_sk, conv, sender, recipient) {
        Some(plaintext) => {
            unsafe { write_buffer(out, plaintext) };
            1
        }
        None => 0,
    }
}

/// Cheap check that a string looks like a post-quantum envelope.
///
/// Lets a client route an incoming seal without spending a decapsulation on every
/// ordinary NIP-17 message.
///
/// # Safety
/// `payload_ptr` must be a valid NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pq_is_envelope(payload_ptr: *const c_char) -> i32 {
    if payload_ptr.is_null() {
        return 0;
    }
    match unsafe { CStr::from_ptr(payload_ptr) }.to_str() {
        Ok(s) => i32::from(is_envelope(s)),
        Err(_) => 0,
    }
}

// ── Tests ───────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;
    use sha2::Digest;

    /// Vector generated by `@nostr-wot/pq` (TypeScript). Seed is bytes 0..64.
    fn reference_seed() -> Vec<u8> {
        (0u8..64).collect()
    }

    fn reference_conversation_key() -> Vec<u8> {
        (0..32).map(|i| 0xa0u8 + (i % 16) as u8).collect()
    }

    const REF_KEM_SEED_HEX: &str = "e8470470d31203eea7b3cf15eff4fb8298a0f2facb74951742be17c19e1d605fa1a4bf447d843dec60d38a200a41cfa18e3d7d3b5031e8f9665784e3349d3a4e";
    const REF_KEM_PK_SHA256: &str =
        "6ba86585af9cb643eae9f935feedf6d67d4b9d1ebde77bf59b6aa32b5eacd8be";
    const REF_HYBRID_KEY_HEX: &str =
        "824fefe4f53ab2babdbdba76a8ef90fb8a545892efab109b8cc272d3ee23c59f";
    const REF_SHARED_SECRET_HEX: &str =
        "2c81d58cec77812863f0917037eaa5692c4e46507725ba142d79199cf09c429e";
    const REF_SENDER: &str =
        "1111111111111111111111111111111111111111111111111111111111111111";
    const REF_RECIPIENT: &str =
        "2222222222222222222222222222222222222222222222222222222222222222";

    /// The derivation must match the TypeScript reference exactly, or keys restored
    /// from the same mnemonic on different clients would not be the same keys.
    #[test]
    fn kem_seed_matches_reference() {
        let kem_seed = hkdf_derive(&reference_seed(), &kem_info(0), 64);
        assert_eq!(hex::encode(&kem_seed), REF_KEM_SEED_HEX);
    }

    #[test]
    fn keypair_matches_reference() {
        let (pk, sk) = derive_kem_keypair(&reference_seed(), 0).unwrap();
        assert_eq!(pk.len(), KEM_PUBLIC_KEY_BYTES);
        assert_eq!(hex::encode(sha2::Sha256::digest(&pk)), REF_KEM_PK_SHA256);
        assert!(!sk.is_empty());
    }

    #[test]
    fn hybrid_key_matches_reference() {
        let shared = hex::decode(REF_SHARED_SECRET_HEX).unwrap();
        let key = hybrid_key(&shared, &reference_conversation_key());
        assert_eq!(hex::encode(key), REF_HYBRID_KEY_HEX);
    }

    /// Padding must match NIP-44 so ciphertext length leaks no more than Nostr already does.
    #[test]
    fn padding_matches_nip44() {
        assert_eq!(calc_padded_len(1), 32);
        assert_eq!(calc_padded_len(32), 32);
        assert_eq!(calc_padded_len(33), 64);
        assert_eq!(calc_padded_len(64), 64);
        assert_eq!(calc_padded_len(65), 96);
        assert_eq!(calc_padded_len(256), 256);
        assert_eq!(calc_padded_len(257), 320);
    }

    /// Messages of different small sizes must produce identical wire sizes.
    #[test]
    fn padding_hides_message_length() {
        let (pk, _) = derive_kem_keypair(&reference_seed(), 0).unwrap();
        let conv = reference_conversation_key();
        let sizes: Vec<usize> = [1usize, 2, 20, 32]
            .iter()
            .map(|n| {
                seal(&pk, &conv, REF_SENDER, REF_RECIPIENT, &vec![b'x'; *n])
                    .unwrap()
                    .len()
            })
            .collect();
        assert!(sizes.windows(2).all(|w| w[0] == w[1]), "sizes: {sizes:?}");
    }

    #[test]
    fn round_trip() {
        let (pk, sk) = derive_kem_keypair(&reference_seed(), 0).unwrap();
        let conv = reference_conversation_key();
        let msg = b"post-quantum interop vector";
        let env = seal(&pk, &conv, REF_SENDER, REF_RECIPIENT, msg).unwrap();
        assert!(is_envelope(&env));
        let out = open(&env, &sk, &conv, REF_SENDER, REF_RECIPIENT).unwrap();
        assert_eq!(out, msg);
    }

    /// If this passed with a wrong conversation key, the construction would not be
    /// hybrid — the post-quantum secret would be carrying the whole thing.
    #[test]
    fn wrong_conversation_key_fails() {
        let (pk, sk) = derive_kem_keypair(&reference_seed(), 0).unwrap();
        let conv = reference_conversation_key();
        let env = seal(&pk, &conv, REF_SENDER, REF_RECIPIENT, b"hello").unwrap();
        let wrong = vec![0u8; 32];
        assert!(open(&env, &sk, &wrong, REF_SENDER, REF_RECIPIENT).is_none());
    }

    /// And if it passed with a wrong ML-KEM key, the classic key would be carrying it.
    #[test]
    fn wrong_kem_key_fails() {
        let (pk, _) = derive_kem_keypair(&reference_seed(), 0).unwrap();
        let (_, other_sk) = derive_kem_keypair(&reference_seed(), 1).unwrap();
        let conv = reference_conversation_key();
        let env = seal(&pk, &conv, REF_SENDER, REF_RECIPIENT, b"hello").unwrap();
        assert!(open(&env, &other_sk, &conv, REF_SENDER, REF_RECIPIENT).is_none());
    }

    /// The framing is in the AEAD's associated data, so a ciphertext must not open
    /// under a different conversation or a swapped direction.
    #[test]
    fn swapped_parties_fail() {
        let (pk, sk) = derive_kem_keypair(&reference_seed(), 0).unwrap();
        let conv = reference_conversation_key();
        let env = seal(&pk, &conv, REF_SENDER, REF_RECIPIENT, b"hello").unwrap();
        assert!(open(&env, &sk, &conv, REF_RECIPIENT, REF_SENDER).is_none());
        assert!(open(&env, &sk, &conv, REF_SENDER, REF_SENDER).is_none());
    }

    #[test]
    fn tampered_ciphertext_fails() {
        let (pk, sk) = derive_kem_keypair(&reference_seed(), 0).unwrap();
        let conv = reference_conversation_key();
        let env = seal(&pk, &conv, REF_SENDER, REF_RECIPIENT, b"hello").unwrap();
        let mut raw = B64.decode(&env).unwrap();
        let last = raw.len() - 1;
        raw[last] ^= 0x01;
        assert!(open(&B64.encode(raw), &sk, &conv, REF_SENDER, REF_RECIPIENT).is_none());
    }

    /// A downgraded algorithm byte must not be accepted.
    #[test]
    fn downgraded_alg_byte_fails() {
        let (pk, sk) = derive_kem_keypair(&reference_seed(), 0).unwrap();
        let conv = reference_conversation_key();
        let env = seal(&pk, &conv, REF_SENDER, REF_RECIPIENT, b"hello").unwrap();
        let mut raw = B64.decode(&env).unwrap();
        raw[1] = 0x02;
        assert!(open(&B64.encode(raw), &sk, &conv, REF_SENDER, REF_RECIPIENT).is_none());
    }

    /// A classic NIP-44 payload must not be mistaken for one of ours.
    #[test]
    fn classic_payload_is_not_an_envelope() {
        assert!(!is_envelope("AkVsrGqLCq0lLYbYCS9lBSuBK4WEHiCcQ7CIzOOTbAvw"));
        assert!(!is_envelope("not base64 at all !!"));
        assert!(!is_envelope(""));
    }

    #[test]
    fn empty_message_is_rejected() {
        let (pk, _) = derive_kem_keypair(&reference_seed(), 0).unwrap();
        let conv = reference_conversation_key();
        assert!(seal(&pk, &conv, REF_SENDER, REF_RECIPIENT, b"").is_none());
    }

    #[test]
    fn bad_key_lengths_are_rejected() {
        let (pk, _) = derive_kem_keypair(&reference_seed(), 0).unwrap();
        let conv = reference_conversation_key();
        assert!(seal(&pk[..100], &conv, REF_SENDER, REF_RECIPIENT, b"hi").is_none());
        assert!(seal(&pk, &conv[..16], REF_SENDER, REF_RECIPIENT, b"hi").is_none());
    }

    /// Different accounts must produce different keys, or one mnemonic would collapse
    /// every identity onto the same post-quantum key.
    #[test]
    fn accounts_are_separated() {
        let (pk0, _) = derive_kem_keypair(&reference_seed(), 0).unwrap();
        let (pk1, _) = derive_kem_keypair(&reference_seed(), 1).unwrap();
        assert_ne!(pk0, pk1);
    }

    /// The one test that pins every interop-relevant byte at once: an envelope produced
    /// by `@nostr-wot/pq` must open here. Keygen and hybrid-key vectors prove the
    /// derivation; only this proves the encapsulation, associated data, padding and
    /// AEAD framing agree end to end.
    #[test]
    fn opens_envelope_produced_by_typescript_reference() {
        let envelope = include_str!("../tests/vectors/pq_envelope_v1.b64").trim();
        let (_, sk) = derive_kem_keypair(&reference_seed(), 0).unwrap();
        let out = open(
            envelope,
            &sk,
            &reference_conversation_key(),
            REF_SENDER,
            REF_RECIPIENT,
        )
        .expect("TypeScript-produced envelope must open");
        assert_eq!(String::from_utf8(out).unwrap(), "post-quantum interop vector");
    }

    /// A colon in a party string would let two different conversations produce identical
    /// associated data, defeating the binding. Rejecting non-hex closes it.
    #[test]
    fn colon_injection_in_party_is_rejected() {
        let (pk, _) = derive_kem_keypair(&reference_seed(), 0).unwrap();
        let conv = reference_conversation_key();
        let a = format!("{}:{}", &REF_SENDER[..32], &REF_SENDER[33..]);
        assert_eq!(a.len(), 64, "same length, so only the charset check catches it");
        assert!(seal(&pk, &conv, &a, REF_RECIPIENT, b"hi").is_none());
        assert!(seal(&pk, &conv, REF_SENDER, &a, b"hi").is_none());
    }

    #[test]
    fn malformed_party_pubkeys_are_rejected() {
        let (pk, _) = derive_kem_keypair(&reference_seed(), 0).unwrap();
        let conv = reference_conversation_key();
        // Uppercase would change the associated data and interoperate with nothing.
        // (REF_SENDER is all digits, so it needs a party string containing letters.)
        let lower = "ab".repeat(32);
        assert!(seal(&pk, &conv, &lower, REF_RECIPIENT, b"hi").is_some());
        assert!(seal(&pk, &conv, &lower.to_uppercase(), REF_RECIPIENT, b"hi").is_none());
        assert!(seal(&pk, &conv, "", REF_RECIPIENT, b"hi").is_none());
        assert!(seal(&pk, &conv, "abcd", REF_RECIPIENT, b"hi").is_none());
        assert!(seal(&pk, &conv, &"z".repeat(64), REF_RECIPIENT, b"hi").is_none());
    }

    /// Anything that is not a 64-byte BIP-39 seed is refused — in particular a 32-byte
    /// secp256k1 private key, which would make this derivation circular.
    #[test]
    fn non_bip39_seeds_are_rejected() {
        assert!(derive_kem_keypair(&[], 0).is_none());
        assert!(derive_kem_keypair(&[0x42; 32], 0).is_none(), "a secp256k1 private key");
        assert!(derive_kem_keypair(&[0x42; 33], 0).is_none(), "a compressed pubkey");
        assert!(derive_kem_keypair(&[0x42; 63], 0).is_none());
        assert!(derive_kem_keypair(&[0x42; 64], 0).is_some());
    }

    #[test]
    fn large_message_round_trips() {
        let (pk, sk) = derive_kem_keypair(&reference_seed(), 0).unwrap();
        let conv = reference_conversation_key();
        let msg = vec![b'z'; 16 * 1024];
        let env = seal(&pk, &conv, REF_SENDER, REF_RECIPIENT, &msg).unwrap();
        assert_eq!(open(&env, &sk, &conv, REF_SENDER, REF_RECIPIENT).unwrap(), msg);
    }
}
