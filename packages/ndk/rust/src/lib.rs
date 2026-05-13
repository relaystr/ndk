use std::ffi::{c_char, CStr};
use std::slice;

use crystals_dilithium::{dilithium2, dilithium3, dilithium5};
use hex::decode;
use secp256k1::{schnorr::Signature, XOnlyPublicKey, SECP256K1};
use sha2::{Digest, Sha256};

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

// ── Quantum-Secure Dilithium Functions ─────────────────────────────────

/// Represents a buffer returned to the caller.
/// The caller must free it with `qs_free_buffer`.
#[repr(C)]
pub struct QsBuffer {
    pub data: *mut u8,
    pub len: usize,
}

/// Frees a buffer previously returned by a qs_ function.
///
/// # Safety
/// `buf` must be a QsBuffer previously returned by this library.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn qs_free_buffer(buf: QsBuffer) {
    if !buf.data.is_null() && buf.len > 0 {
        let _ = unsafe { Vec::from_raw_parts(buf.data, buf.len, buf.len) };
    }
}

/// Generates a Dilithium keypair.
///
/// `level` selects the security level: 2, 3, or 5.
///
/// On success, writes the public key into `out_pk` and the secret key into
/// `out_sk` and returns 1. On failure returns 0.
///
/// # Safety
/// `out_pk` and `out_sk` must be valid pointers to `QsBuffer`.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn qs_generate_keypair(
    level: u32,
    out_pk: *mut QsBuffer,
    out_sk: *mut QsBuffer,
) -> i32 {
    if out_pk.is_null() || out_sk.is_null() {
        return 0;
    }

    match level {
        2 => {
            let keypair = match dilithium2::Keypair::generate(None) {
                Ok(kp) => kp,
                Err(_) => return 0,
            };
            let pk = keypair.public.to_bytes().to_vec();
            let sk = keypair.to_bytes().to_vec(); // full keypair bytes (secret + public)
            write_buffer(out_pk, pk);
            write_buffer(out_sk, sk);
            1
        }
        3 => {
            let keypair = match dilithium3::Keypair::generate(None) {
                Ok(kp) => kp,
                Err(_) => return 0,
            };
            let pk = keypair.public.to_bytes().to_vec();
            let sk = keypair.to_bytes().to_vec();
            write_buffer(out_pk, pk);
            write_buffer(out_sk, sk);
            1
        }
        5 => {
            let keypair = match dilithium5::Keypair::generate(None) {
                Ok(kp) => kp,
                Err(_) => return 0,
            };
            let pk = keypair.public.to_bytes().to_vec();
            let sk = keypair.to_bytes().to_vec();
            write_buffer(out_pk, pk);
            write_buffer(out_sk, sk);
            1
        }
        _ => 0,
    }
}

/// Signs a message with a Dilithium secret key.
///
/// `level` selects the security level: 2, 3, or 5.
/// `sk_ptr` / `sk_len` is the secret key bytes.
/// `msg_ptr` / `msg_len` is the message bytes.
///
/// On success, writes the signature into `out_sig` and returns 1.
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

    match level {
        2 => {
            if sk_len != dilithium2::KEYPAIRBYTES {
                return 0;
            }
            let keypair = match dilithium2::Keypair::from_bytes(sk_bytes) {
                Ok(kp) => kp,
                Err(_) => return 0,
            };
            let sig = keypair.sign(msg);
            write_buffer(out_sig, sig.to_vec());
            1
        }
        3 => {
            if sk_len != dilithium3::KEYPAIRBYTES {
                return 0;
            }
            let keypair = match dilithium3::Keypair::from_bytes(sk_bytes) {
                Ok(kp) => kp,
                Err(_) => return 0,
            };
            let sig = keypair.sign(msg);
            write_buffer(out_sig, sig.to_vec());
            1
        }
        5 => {
            if sk_len != dilithium5::KEYPAIRBYTES {
                return 0;
            }
            let keypair = match dilithium5::Keypair::from_bytes(sk_bytes) {
                Ok(kp) => kp,
                Err(_) => return 0,
            };
            let sig = keypair.sign(msg);
            write_buffer(out_sig, sig.to_vec());
            1
        }
        _ => 0,
    }
}

/// Verifies a Dilithium signature.
///
/// `level` selects the security level: 2, 3, or 5.
///
/// Returns 1 if valid, 0 if invalid.
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

    match level {
        2 => {
            if pk_len != dilithium2::PUBLICKEYBYTES || sig_len != dilithium2::SIGNBYTES {
                return 0;
            }
            let pubkey = match dilithium2::PublicKey::from_bytes(pk_bytes) {
                Ok(pk) => pk,
                Err(_) => return 0,
            };
            let mut sig_arr = [0u8; dilithium2::SIGNBYTES];
            sig_arr.copy_from_slice(sig_bytes);
            if pubkey.verify(msg, &sig_arr) {
                1
            } else {
                0
            }
        }
        3 => {
            if pk_len != dilithium3::PUBLICKEYBYTES || sig_len != dilithium3::SIGNBYTES {
                return 0;
            }
            let pubkey = match dilithium3::PublicKey::from_bytes(pk_bytes) {
                Ok(pk) => pk,
                Err(_) => return 0,
            };
            let mut sig_arr = [0u8; dilithium3::SIGNBYTES];
            sig_arr.copy_from_slice(sig_bytes);
            if pubkey.verify(msg, &sig_arr) {
                1
            } else {
                0
            }
        }
        5 => {
            if pk_len != dilithium5::PUBLICKEYBYTES || sig_len != dilithium5::SIGNBYTES {
                return 0;
            }
            let pubkey = match dilithium5::PublicKey::from_bytes(pk_bytes) {
                Ok(pk) => pk,
                Err(_) => return 0,
            };
            let mut sig_arr = [0u8; dilithium5::SIGNBYTES];
            sig_arr.copy_from_slice(sig_bytes);
            if pubkey.verify(msg, &sig_arr) {
                1
            } else {
                0
            }
        }

        _ => 0,
    }
}

/// Helper: move a Vec<u8> into a QsBuffer, leaking the memory for the caller.
unsafe fn write_buffer(out: *mut QsBuffer, data: Vec<u8>) {
    let len = data.len();
    let ptr = data.leak().as_mut_ptr();
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
    fn qs_dilithium2_roundtrip() {
        let keypair = dilithium2::Keypair::generate(None).unwrap();
        let msg = b"hello quantum world";
        let sig = keypair.secret.sign(msg);
        assert!(keypair.public.verify(msg, &sig));
    }

    #[test]
    fn qs_dilithium3_roundtrip() {
        let keypair = dilithium3::Keypair::generate(None).unwrap();
        let msg = b"hello quantum world";
        let sig = keypair.secret.sign(msg);
        assert!(keypair.public.verify(msg, &sig));
    }

    #[test]
    fn qs_dilithium5_roundtrip() {
        let keypair = dilithium5::Keypair::generate(None).unwrap();
        let msg = b"hello quantum world";
        let sig = keypair.secret.sign(msg);
        assert!(keypair.public.verify(msg, &sig));
    }

    #[test]
    fn qs_dilithium2_bad_sig_fails() {
        let keypair = dilithium2::Keypair::generate(None).unwrap();
        let msg = b"hello quantum world";
        let mut sig = keypair.secret.sign(msg);
        sig[0] ^= 0xff;
        assert!(!keypair.public.verify(msg, &sig));
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

            let ret = qs_generate_keypair(2, &mut pk, &mut sk);
            assert_eq!(ret, 1);
            assert!(!pk.data.is_null());
            assert!(!sk.data.is_null());

            let msg = b"test message";
            let mut sig = QsBuffer {
                data: std::ptr::null_mut(),
                len: 0,
            };

            let ret = qs_sign(2, sk.data, sk.len, msg.as_ptr(), msg.len(), &mut sig);
            assert_eq!(ret, 1);

            let ret = qs_verify(
                2,
                pk.data,
                pk.len,
                msg.as_ptr(),
                msg.len(),
                sig.data,
                sig.len,
            );
            assert_eq!(ret, 1);

            // wrong message should fail
            let bad_msg = b"wrong message";
            let ret = qs_verify(
                2,
                pk.data,
                pk.len,
                bad_msg.as_ptr(),
                bad_msg.len(),
                sig.data,
                sig.len,
            );
            assert_eq!(ret, 0);

            qs_free_buffer(pk);
            qs_free_buffer(sk);
            qs_free_buffer(sig);
        }
    }
}
