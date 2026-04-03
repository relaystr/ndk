use std::ffi::{c_char, CStr};
use std::slice;

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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn schnorr_signature_test_valid() {
        let pub_key_hex = "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798";
        let event_id = "a47c525970d21575c67e6f1e47674f1b82fc7edabb098fac4be21bb05425b389";
        let signature_hex = "b03ddc4930776698d39caa3df0cd887558ceea281eb9e2524daaba324906b2e3efc06f2f65a7fbba95c0b3ce9817df81f53d2d8da0124028446b0cc3a59ae6d9";

        assert!(verify_schnorr_signature_internal(pub_key_hex, event_id, signature_hex));
    }

    #[test]
    fn schnorr_signature_test_invalid() {
        let pub_key_hex = "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798";
        let event_id = "a47c525970d21575c67e6f1e47674f1b82fc7edabb098fac4be21bb05425b389";
        let signature_hex = "a03ddc4930776698d39caa3df0cd887558ceea281eb9e2524daaba324906b2e3efc06f2f65a7fbba95c0b3ce9817df81f53d2d8da0124028446b0cc3a59ae6d9";

        assert!(!verify_schnorr_signature_internal(pub_key_hex, event_id, signature_hex));
    }

    #[test]
    fn hash_event_data_valid() {
        let valid_id = "2bd7b2af40868949001713ffdcf95e1b1659dbbabe659ef9299d0fe11e31421d";
        let pubkey = "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798";
        let created_at = 1726215220;
        let kind = 1;
        let tags: Vec<Vec<String>> = vec![];
        let content = "hello world";

        assert_eq!(hash_event_data_internal(pubkey, created_at, kind, &tags, content), valid_id);
    }

    #[test]
    fn hash_event_data_invalid() {
        let valid_id = "2bd7b2af40868949001713ffdcf95e1b1659dbbabe659ef9299d0fe11e31421d";
        let pubkey = "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798";
        let created_at = 1726215220;
        let kind = 1;
        let tags: Vec<Vec<String>> = vec![];
        let content = "invalid";

        assert_ne!(hash_event_data_internal(pubkey, created_at, kind, &tags, content), valid_id);
    }
}
