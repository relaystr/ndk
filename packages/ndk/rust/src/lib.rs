use std::ffi::{c_char, CStr};
use std::slice;

use fips204::traits::{KeyGen, SerDes, Signer, Verifier};
use fips204::{ml_dsa_44, ml_dsa_65, ml_dsa_87};
use hex::decode;
use hkdf::Hkdf;
use secp256k1::{schnorr::Signature, XOnlyPublicKey, SECP256K1};
use sha2::{Digest, Sha256};
use zeroize::Zeroize;

/// Verifies a Nostr event signature.
///
/// # Safety
/// All string pointers must be valid null-terminated C strings.
/// tags_data must point to a valid array of tag strings.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn verify_nostr_event(
    event_id_hex: *const c_char,
    pub_key_hex: *const c_char,
    created_at: u64,
    kind: u32,
    tags_data: *const *const c_char,
    tags_lengths: *const u32,
    tags_count: u32,
    content: *const c_char,
    signature_hex: *const c_char,
) -> i32 {
    // Convert C strings to Rust strings
    let event_id = match unsafe { CStr::from_ptr(event_id_hex) }.to_str() {
        Ok(s) => s,
        Err(_) => return 0,
    };
    let pub_key = match unsafe { CStr::from_ptr(pub_key_hex) }.to_str() {
        Ok(s) => s,
        Err(_) => return 0,
    };
    let content_str = match unsafe { CStr::from_ptr(content) }.to_str() {
        Ok(s) => s,
        Err(_) => return 0,
    };
    let signature = match unsafe { CStr::from_ptr(signature_hex) }.to_str() {
        Ok(s) => s,
        Err(_) => return 0,
    };

    // Parse tags from flat array
    // tags_lengths contains the length of each tag (number of elements)
    // tags_data contains all tag strings concatenated
    let tags = if tags_count > 0 && !tags_data.is_null() && !tags_lengths.is_null() {
        let lengths = unsafe { slice::from_raw_parts(tags_lengths, tags_count as usize) };
        let mut result: Vec<Vec<String>> = Vec::with_capacity(tags_count as usize);
        let mut offset = 0usize;

        for &len in lengths {
            let mut tag: Vec<String> = Vec::with_capacity(len as usize);
            for i in 0..len as usize {
                let ptr = unsafe { *tags_data.add(offset + i) };
                if ptr.is_null() {
                    return 0;
                }
                match unsafe { CStr::from_ptr(ptr) }.to_str() {
                    Ok(s) => tag.push(s.to_string()),
                    Err(_) => return 0,
                }
            }
            result.push(tag);
            offset += len as usize;
        }
        result
    } else {
        Vec::new()
    };

    // Check id
    let calc_id = hash_event_data_internal(pub_key, created_at, kind as u16, &tags, content_str);
    if calc_id != event_id {
        return 0;
    }

    // Check signature
    if verify_schnorr_signature_internal(pub_key, event_id, signature) {
        1
    } else {
        0
    }
}

/// Verifies a Schnorr signature.
///
/// # Safety
/// All pointers must be valid null-terminated C strings.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn verify_schnorr_signature(
    pub_key_hex: *const c_char,
    event_id_hex: *const c_char,
    signature_hex: *const c_char,
) -> i32 {
    let pub_key = match unsafe { CStr::from_ptr(pub_key_hex) }.to_str() {
        Ok(s) => s,
        Err(_) => return 0,
    };
    let event_id = match unsafe { CStr::from_ptr(event_id_hex) }.to_str() {
        Ok(s) => s,
        Err(_) => return 0,
    };
    let signature = match unsafe { CStr::from_ptr(signature_hex) }.to_str() {
        Ok(s) => s,
        Err(_) => return 0,
    };

    if verify_schnorr_signature_internal(pub_key, event_id, signature) {
        1
    } else {
        0
    }
}

fn verify_schnorr_signature_internal(
    pub_key_hex: &str,
    event_id_hex: &str,
    signature_hex: &str,
) -> bool {
    let pub_key_bytes = match decode(pub_key_hex) {
        Ok(bytes) => bytes,
        Err(_) => return false,
    };

    let event_id_bytes = match decode(event_id_hex) {
        Ok(bytes) => bytes,
        Err(_) => return false,
    };

    let signature_bytes = match decode(signature_hex) {
        Ok(bytes) => bytes,
        Err(_) => return false,
    };

    if event_id_bytes.len() != 32 || pub_key_bytes.len() != 32 || signature_bytes.len() != 64 {
        return false;
    }

    let pub_key_array: [u8; 32] = match pub_key_bytes.try_into() {
        Ok(arr) => arr,
        Err(_) => return false,
    };

    let signature_array: [u8; 64] = match signature_bytes.try_into() {
        Ok(arr) => arr,
        Err(_) => return false,
    };

    let pubkey = match XOnlyPublicKey::from_byte_array(pub_key_array) {
        Ok(key) => key,
        Err(_) => return false,
    };

    let signature = Signature::from_byte_array(signature_array);

    SECP256K1
        .verify_schnorr(&signature, &event_id_bytes, &pubkey)
        .is_ok()
}

fn hash_event_data_internal(
    pubkey: &str,
    created_at: u64,
    kind: u16,
    tags: &[Vec<String>],
    content: &str,
) -> String {
    let mut serialized_event = String::with_capacity(256);
    serialized_event.push_str("[0,\"");
    serialized_event.push_str(pubkey);
    serialized_event.push_str("\",");
    serialized_event.push_str(&created_at.to_string());
    serialized_event.push(',');
    serialized_event.push_str(&kind.to_string());
    serialized_event.push_str(",[");

    for (i, tag) in tags.iter().enumerate() {
        if i > 0 {
            serialized_event.push(',');
        }
        serialized_event.push('[');
        for (j, item) in tag.iter().enumerate() {
            if j > 0 {
                serialized_event.push(',');
            }
            serialized_event.push('"');
            for c in item.chars() {
                match c {
                    '"' => serialized_event.push_str("\\\""),
                    '\\' => serialized_event.push_str("\\\\"),
                    '\n' => serialized_event.push_str("\\n"),
                    '\r' => serialized_event.push_str("\\r"),
                    '\t' => serialized_event.push_str("\\t"),
                    _ => serialized_event.push(c),
                }
            }
            serialized_event.push('"');
        }
        serialized_event.push(']');
    }

    serialized_event.push_str("],\"");
    for c in content.chars() {
        match c {
            '"' => serialized_event.push_str("\\\""),
            '\\' => serialized_event.push_str("\\\\"),
            '\n' => serialized_event.push_str("\\n"),
            '\r' => serialized_event.push_str("\\r"),
            '\t' => serialized_event.push_str("\\t"),
            _ => serialized_event.push(c),
        }
    }
    serialized_event.push_str("\"]");

    let mut hasher = Sha256::new();
    hasher.update(serialized_event.as_bytes());
    let result = hasher.finalize();

    format!("{:x}", result)
}

// ── Quantum-Secure ML-DSA (FIPS 204) Functions ─────────────────────────
//
// These were CRYSTALS-Dilithium (the round-3 NIST submission). NIST changed the
// algorithm during standardisation, so Dilithium and ML-DSA are not wire-compatible:
// keys and signatures produced by the old code cannot be verified by any FIPS 204
// implementation, and vice versa. Anything published with the previous keys is
// therefore unverifiable by the wider ecosystem, which defeats the point of signing.
//
// `level` selects the parameter set and now takes the ML-DSA numbers — 44, 65 or 87 —
// rather than Dilithium's 2, 3 and 5. The old values are rejected rather than
// remapped, so a caller that was not updated fails loudly instead of silently
// producing keys with different security properties than it asked for.

/// Domain-separation profile for seed-derived keys. Shared with the ML-KEM derivation.
const PQ_PROFILE: &str = "nip-pqc/v1";

/// A BIP-39 seed is always 64 bytes, whatever the mnemonic length.
const SEED_BYTES: usize = 64;

/// Represents a buffer returned to the caller.
/// The caller must free it with `qs_free_buffer`.
#[repr(C)]
pub struct QsBuffer {
    pub data: *mut u8,
    pub len: usize,
}

/// Frees a buffer previously returned by a qs_ function.
///
/// The contents are zeroized before the allocation is released: these buffers carry
/// secret keys, and a freed-but-not-wiped secret is recoverable from a core dump, a
/// swap file, or a later heap read.
///
/// # Safety
/// `buf` must be a QsBuffer previously returned by this library, and must not be
/// freed twice.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn qs_free_buffer(buf: QsBuffer) {
    if !buf.data.is_null() && buf.len > 0 {
        let mut v = unsafe { Vec::from_raw_parts(buf.data, buf.len, buf.len) };
        v.zeroize();
    }
}

/// Derives the 32-byte ML-DSA key seed (xi) from a BIP-39 seed.
///
/// Domain-separated per algorithm and account so the signing key is a *sibling* of the
/// secp256k1 key rather than a child of it. Deriving from the Nostr private key would
/// be circular: an adversary who recovers it from the published pubkey would repeat the
/// derivation and obtain this key too.
fn derive_dsa_xi(seed: &[u8], level: u32, account: u32) -> Option<[u8; 32]> {
    // A BIP-39 seed is always 64 bytes; requiring exactly that blocks passing a
    // 32-byte secp256k1 private key as the seed.
    if seed.len() != SEED_BYTES {
        return None;
    }
    let info = format!("{PQ_PROFILE}/ml-dsa-{level}/{account}");
    let hk = Hkdf::<Sha256>::new(None, seed);
    let mut xi = [0u8; 32];
    hk.expand(info.as_bytes(), &mut xi).ok()?;
    Some(xi)
}

/// Generates a random ML-DSA keypair.
///
/// `level` selects the parameter set: 44, 65 or 87.
///
/// Prefer `qs_derive_keypair_from_seed` for anything that represents an identity — a
/// randomly generated key cannot be restored from a mnemonic, so losing it loses the
/// identity permanently.
///
/// On success, writes the public key into `out_pk` and the secret key into `out_sk`
/// and returns 1. On failure returns 0.
///
/// # Safety
/// `out_pk` and `out_sk` must be valid, non-aliasing pointers to `QsBuffer`.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn qs_generate_keypair(
    level: u32,
    out_pk: *mut QsBuffer,
    out_sk: *mut QsBuffer,
) -> i32 {
    if out_pk.is_null() || out_sk.is_null() {
        return 0;
    }
    macro_rules! gen {
        ($m:ident) => {{
            match $m::KG::try_keygen() {
                Ok((pk, sk)) => {
                    let mut sk_bytes = sk.into_bytes().to_vec();
                    unsafe {
                        write_buffer(out_pk, pk.into_bytes().to_vec());
                        write_buffer(out_sk, sk_bytes.clone());
                    }
                    sk_bytes.zeroize();
                    1
                }
                Err(_) => 0,
            }
        }};
    }
    match level {
        44 => gen!(ml_dsa_44),
        65 => gen!(ml_dsa_65),
        87 => gen!(ml_dsa_87),
        _ => 0,
    }
}

/// Derives an ML-DSA keypair deterministically from a 64-byte BIP-39 seed.
///
/// One mnemonic therefore restores the signing key, and — because the ML-KEM
/// derivation in `pq.rs` uses the same seed with a different domain string — the
/// encryption key too.
///
/// # Safety
/// `seed_ptr` must be valid for `seed_len` bytes; `out_pk` and `out_sk` must be valid,
/// non-aliasing pointers to `QsBuffer`.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn qs_derive_keypair_from_seed(
    level: u32,
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
    let mut xi = match derive_dsa_xi(seed, level, account) {
        Some(x) => x,
        None => return 0,
    };
    macro_rules! derive {
        ($m:ident) => {{
            let (pk, sk) = $m::KG::keygen_from_seed(&xi);
            let mut sk_bytes = sk.into_bytes().to_vec();
            unsafe {
                write_buffer(out_pk, pk.into_bytes().to_vec());
                write_buffer(out_sk, sk_bytes.clone());
            }
            sk_bytes.zeroize();
            1
        }};
    }
    let rc = match level {
        44 => derive!(ml_dsa_44),
        65 => derive!(ml_dsa_65),
        87 => derive!(ml_dsa_87),
        _ => 0,
    };
    xi.zeroize();
    rc
}

/// Signs a message with an ML-DSA secret key, using an empty FIPS 204 context string.
///
/// `level` selects the parameter set: 44, 65 or 87.
///
/// # Safety
/// All pointers must be valid for their indicated lengths.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn qs_sign(
    level: u32,
    sk_ptr: *const u8,
    sk_len: usize,
    msg_ptr: *const u8,
    msg_len: usize,
    out_sig: *mut QsBuffer,
) -> i32 {
    if sk_ptr.is_null() || msg_ptr.is_null() || out_sig.is_null() {
        return 0;
    }
    let sk_bytes = unsafe { slice::from_raw_parts(sk_ptr, sk_len) };
    let msg = unsafe { slice::from_raw_parts(msg_ptr, msg_len) };

    macro_rules! sign {
        ($m:ident) => {{
            let arr: [u8; $m::SK_LEN] = match sk_bytes.try_into() {
                Ok(a) => a,
                Err(_) => return 0,
            };
            let sk = match $m::PrivateKey::try_from_bytes(arr) {
                Ok(k) => k,
                Err(_) => return 0,
            };
            match sk.try_sign(msg, &[]) {
                Ok(sig) => {
                    unsafe { write_buffer(out_sig, sig.to_vec()) };
                    1
                }
                Err(_) => 0,
            }
        }};
    }
    match level {
        44 => sign!(ml_dsa_44),
        65 => sign!(ml_dsa_65),
        87 => sign!(ml_dsa_87),
        _ => 0,
    }
}

/// Verifies an ML-DSA signature against an empty FIPS 204 context string.
///
/// Returns 1 when the signature is valid, 0 otherwise — including for malformed
/// inputs, which are indistinguishable from an invalid signature by design.
///
/// # Safety
/// All pointers must be valid for their indicated lengths.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn qs_verify(
    level: u32,
    pk_ptr: *const u8,
    pk_len: usize,
    msg_ptr: *const u8,
    msg_len: usize,
    sig_ptr: *const u8,
    sig_len: usize,
) -> i32 {
    if pk_ptr.is_null() || msg_ptr.is_null() || sig_ptr.is_null() {
        return 0;
    }
    let pk_bytes = unsafe { slice::from_raw_parts(pk_ptr, pk_len) };
    let msg = unsafe { slice::from_raw_parts(msg_ptr, msg_len) };
    let sig_bytes = unsafe { slice::from_raw_parts(sig_ptr, sig_len) };

    macro_rules! verify {
        ($m:ident) => {{
            let pk_arr: [u8; $m::PK_LEN] = match pk_bytes.try_into() {
                Ok(a) => a,
                Err(_) => return 0,
            };
            let sig_arr: [u8; $m::SIG_LEN] = match sig_bytes.try_into() {
                Ok(a) => a,
                Err(_) => return 0,
            };
            let pk = match $m::PublicKey::try_from_bytes(pk_arr) {
                Ok(k) => k,
                Err(_) => return 0,
            };
            i32::from(pk.verify(msg, &sig_arr, &[]))
        }};
    }
    match level {
        44 => verify!(ml_dsa_44),
        65 => verify!(ml_dsa_65),
        87 => verify!(ml_dsa_87),
        _ => 0,
    }
}

/// Helper: move a Vec<u8> into a QsBuffer, leaking the memory for the caller.
///
/// The Vec is converted to a boxed slice first. `qs_free_buffer` reconstructs the
/// allocation with `Vec::from_raw_parts(data, len, len)`, which is undefined behaviour
/// unless capacity equals length — and nothing about `Vec` guarantees that in general.
/// It happens to hold for every value passed here today, so this is a latent trap
/// rather than a live bug: the next contributor to build an output with `push` or
/// `extend` would introduce heap corruption in the free path with no compiler
/// diagnostic. `into_boxed_slice` reallocates to the exact size and removes the trap.
pub(crate) unsafe fn write_buffer(out: *mut QsBuffer, data: Vec<u8>) {
    let data = data.into_boxed_slice();
    let len = data.len();
    let ptr = Box::leak(data).as_mut_ptr();
    unsafe {
        (*out).data = ptr;
        (*out).len = len;
    }
}

// ── Tests ──────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn schnorr_signature_test_valid() {
        let pub_key_hex = "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798";
        let event_id = "a47c525970d21575c67e6f1e47674f1b82fc7edabb098fac4be21bb05425b389";
        let signature_hex = "b03ddc4930776698d39caa3df0cd887558ceea281eb9e2524daaba324906b2e3efc06f2f65a7fbba95c0b3ce9817df81f53d2d8da0124028446b0cc3a59ae6d9";
        assert!(verify_schnorr_signature_internal(
            pub_key_hex,
            event_id,
            signature_hex
        ));
    }

    #[test]
    fn schnorr_signature_test_invalid() {
        let pub_key_hex = "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798";
        let event_id = "a47c525970d21575c67e6f1e47674f1b82fc7edabb098fac4be21bb05425b389";
        let signature_hex = "a03ddc4930776698d39caa3df0cd887558ceea281eb9e2524daaba324906b2e3efc06f2f65a7fbba95c0b3ce9817df81f53d2d8da0124028446b0cc3a59ae6d9";
        assert!(!verify_schnorr_signature_internal(
            pub_key_hex,
            event_id,
            signature_hex
        ));
    }

    #[test]
    fn hash_event_data_valid() {
        let valid_id = "2bd7b2af40868949001713ffdcf95e1b1659dbbabe659ef9299d0fe11e31421d";
        let pubkey = "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798";
        let created_at = 1726215220;
        let kind = 1;
        let tags: Vec<Vec<String>> = vec![];
        let content = "hello world";
        assert_eq!(
            hash_event_data_internal(pubkey, created_at, kind, &tags, content),
            valid_id
        );
    }

    #[test]
    fn hash_event_data_invalid() {
        let valid_id = "2bd7b2af40868949001713ffdcf95e1b1659dbbabe659ef9299d0fe11e31421d";
        let pubkey = "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798";
        let created_at = 1726215220;
        let kind = 1;
        let tags: Vec<Vec<String>> = vec![];
        let content = "invalid";
        assert_ne!(
            hash_event_data_internal(pubkey, created_at, kind, &tags, content),
            valid_id
        );
    }

    #[test]
    fn qs_mldsa_roundtrip_all_levels() {
        for level in [44u32, 65, 87] {
            let seed = [7u8; 64];
            let xi = derive_dsa_xi(&seed, level, 0).unwrap();
            let msg = b"hello quantum world";
            match level {
                44 => {
                    let (pk, sk) = ml_dsa_44::KG::keygen_from_seed(&xi);
                    let sig = sk.try_sign(msg, &[]).unwrap();
                    assert!(pk.verify(msg, &sig, &[]));
                }
                65 => {
                    let (pk, sk) = ml_dsa_65::KG::keygen_from_seed(&xi);
                    let sig = sk.try_sign(msg, &[]).unwrap();
                    assert!(pk.verify(msg, &sig, &[]));
                }
                _ => {
                    let (pk, sk) = ml_dsa_87::KG::keygen_from_seed(&xi);
                    let sig = sk.try_sign(msg, &[]).unwrap();
                    assert!(pk.verify(msg, &sig, &[]));
                }
            }
        }
    }

    #[test]
    fn qs_mldsa_bad_sig_fails() {
        let (pk, sk) = ml_dsa_87::KG::keygen_from_seed(&[3u8; 32]);
        let msg = b"hello quantum world";
        let mut sig = sk.try_sign(msg, &[]).unwrap();
        sig[0] ^= 0xff;
        assert!(!pk.verify(msg, &sig, &[]));
    }

    /// Pinned against `@noble/post-quantum`'s `ml_dsa87`, the implementation the
    /// TypeScript reference uses. The seed is HKDF-derived from bytes 0..64 with
    /// info "nip-pqc/v1/ml-dsa-87/0", exactly as `dsaInfo` does there.
    ///
    /// This is what the previous CRYSTALS-Dilithium code could never satisfy: the
    /// round-3 submission and FIPS 204 are different algorithms, so its keys and
    /// signatures were verifiable only by itself.
    #[test]
    fn qs_mldsa87_matches_fips204_reference_vector() {
        let seed: Vec<u8> = (0u8..64).collect();
        let xi = derive_dsa_xi(&seed, 87, 0).unwrap();
        assert_eq!(
            hex::encode(xi),
            "3d8443c4983bf876911077a0038d5e5084ca107d0d4b6a9438cbf051f79e3917"
        );
        let (pk, _) = ml_dsa_87::KG::keygen_from_seed(&xi);
        let pk_bytes = pk.into_bytes();
        assert_eq!(pk_bytes.len(), ml_dsa_87::PK_LEN);
        assert_eq!(
            hex::encode(Sha256::digest(pk_bytes.as_slice())),
            "dcc0c445e54e2130ded2c1fa04e8aed2fcd80dfaefe2897b41fec827e6cdb609"
        );
    }

    /// A BIP-39 seed is 64 bytes; a secp256k1 private key is 32. Accepting the latter
    /// would make the derivation circular.
    #[test]
    fn qs_seed_derivation_rejects_non_bip39_seeds() {
        assert!(derive_dsa_xi(&[], 87, 0).is_none());
        assert!(derive_dsa_xi(&[0x42; 32], 87, 0).is_none());
        assert!(derive_dsa_xi(&[0x42; 64], 87, 0).is_some());
    }

    /// Same seed, different account or parameter set, different key.
    #[test]
    fn qs_seed_derivation_is_domain_separated() {
        let seed = [9u8; 64];
        let a = derive_dsa_xi(&seed, 87, 0).unwrap();
        assert_ne!(a, derive_dsa_xi(&seed, 87, 1).unwrap());
        assert_ne!(a, derive_dsa_xi(&seed, 65, 0).unwrap());
    }

    /// The Dilithium level numbers must not silently mean something else now.
    #[test]
    fn qs_rejects_legacy_dilithium_levels() {
        unsafe {
            for level in [2u32, 3, 5] {
                let mut pk = QsBuffer {
                    data: std::ptr::null_mut(),
                    len: 0,
                };
                let mut sk = QsBuffer {
                    data: std::ptr::null_mut(),
                    len: 0,
                };
                assert_eq!(qs_generate_keypair(level, &mut pk, &mut sk), 0);
                assert!(pk.data.is_null());
            }
        }
    }

    #[test]
    fn qs_ffi_roundtrip() {
        unsafe {
            let mut pk = QsBuffer {
                data: std::ptr::null_mut(),
                len: 0,
            };
            let mut sk = QsBuffer {
                data: std::ptr::null_mut(),
                len: 0,
            };

            assert_eq!(qs_generate_keypair(87, &mut pk, &mut sk), 1);
            assert!(!pk.data.is_null());
            assert!(!sk.data.is_null());
            assert_eq!(pk.len, ml_dsa_87::PK_LEN);
            assert_eq!(sk.len, ml_dsa_87::SK_LEN);

            let msg = b"test message";
            let mut sig = QsBuffer {
                data: std::ptr::null_mut(),
                len: 0,
            };
            assert_eq!(
                qs_sign(87, sk.data, sk.len, msg.as_ptr(), msg.len(), &mut sig),
                1
            );
            assert_eq!(sig.len, ml_dsa_87::SIG_LEN);

            assert_eq!(
                qs_verify(
                    87,
                    pk.data,
                    pk.len,
                    msg.as_ptr(),
                    msg.len(),
                    sig.data,
                    sig.len
                ),
                1
            );

            let bad_msg = b"wrong message";
            assert_eq!(
                qs_verify(
                    87,
                    pk.data,
                    pk.len,
                    bad_msg.as_ptr(),
                    bad_msg.len(),
                    sig.data,
                    sig.len
                ),
                0
            );

            qs_free_buffer(pk);
            qs_free_buffer(sk);
            qs_free_buffer(sig);
        }
    }

    /// The seed-derived FFI path must agree with direct derivation, and be stable
    /// across calls — that is what makes a mnemonic able to restore the key.
    #[test]
    fn qs_ffi_seed_derivation_is_deterministic() {
        unsafe {
            let seed = [11u8; 64];
            let mut first: Option<Vec<u8>> = None;
            for _ in 0..2 {
                let mut pk = QsBuffer {
                    data: std::ptr::null_mut(),
                    len: 0,
                };
                let mut sk = QsBuffer {
                    data: std::ptr::null_mut(),
                    len: 0,
                };
                assert_eq!(
                    qs_derive_keypair_from_seed(87, seed.as_ptr(), seed.len(), 0, &mut pk, &mut sk),
                    1
                );
                let bytes = std::slice::from_raw_parts(pk.data, pk.len).to_vec();
                match &first {
                    None => first = Some(bytes),
                    Some(f) => assert_eq!(*f, bytes),
                }
                qs_free_buffer(pk);
                qs_free_buffer(sk);
            }
        }
    }
}
