use hex::decode;
use secp256k1::{XOnlyPublicKey, SECP256K1};
use secp256k1::schnorr::Signature;
use sha2::{Digest, Sha256};

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}

pub fn verify_nostr_event(
    event_id_hex: &str,
    pub_key_hex: &str,
    created_at: u64,
    kind: u16,
    tags: Vec<Vec<String>>,
    content: &str,
    signature_hex: &str,
) -> bool {
    // check id
    let calc_id = hash_event_data(pub_key_hex, created_at, kind, tags, content);
    if calc_id != event_id_hex {
        return false;
    }
    // check signature
    return verify_schnorr_signature(pub_key_hex, event_id_hex, signature_hex);
}

#[test]
fn schnorr_signature_test_valid() {
    let pub_key_hex = "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798";
    let event_id = "a47c525970d21575c67e6f1e47674f1b82fc7edabb098fac4be21bb05425b389";
    let signature_hex = "b03ddc4930776698d39caa3df0cd887558ceea281eb9e2524daaba324906b2e3efc06f2f65a7fbba95c0b3ce9817df81f53d2d8da0124028446b0cc3a59ae6d9";

    let result = verify_schnorr_signature(pub_key_hex, event_id, signature_hex);
    print!("result: ${result}");

    assert!(result);
}

#[test]
fn schnorr_signature_test_invalid() {
    let pub_key_hex = "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798";
    let event_id = "a47c525970d21575c67e6f1e47674f1b82fc7edabb098fac4be21bb05425b389";
    // invalid sig
    let signature_hex = "a03ddc4930776698d39caa3df0cd887558ceea281eb9e2524daaba324906b2e3efc06f2f65a7fbba95c0b3ce9817df81f53d2d8da0124028446b0cc3a59ae6d9";

    let result = verify_schnorr_signature(pub_key_hex, event_id, signature_hex);
    print!("result: ${result}");

    assert!(!result);
}

pub fn verify_schnorr_signature(
    pub_key_hex: &str,
    event_id_hex: &str,
    signature_hex: &str,
) -> bool {
    let pub_key_bytes = match decode(pub_key_hex) {
        Ok(bytes) => bytes,
        Err(_) => {
            eprintln!("Invalid public key hex");
            return false;
        }
    };

    let event_id_bytes = match decode(event_id_hex) {
        Ok(bytes) => bytes,
        Err(_) => {
            eprintln!("Invalid event ID hex");
            return false;
        }
    };

    let signature_bytes = match decode(signature_hex) {
        Ok(bytes) => bytes,
        Err(_) => {
            eprintln!("Invalid signature hex");
            return false;
        }
    };

    if event_id_bytes.len() != 32 {
        eprintln!("Event ID is not 32 bytes");
        return false;
    }

    if pub_key_bytes.len() != 32 {
        eprintln!("Public key is not 32 bytes");
        return false;
    }

    if signature_bytes.len() != 64 {
        eprintln!("Signature is not 64 bytes");
        return false;
    }

    // Convert slices to fixed-size arrays
    let pub_key_array: [u8; 32] = match pub_key_bytes.try_into() {
        Ok(arr) => arr,
        Err(_) => {
            eprintln!("Failed to convert public key to array");
            return false;
        }
    };

    let signature_array: [u8; 64] = match signature_bytes.try_into() {
        Ok(arr) => arr,
        Err(_) => {
            eprintln!("Failed to convert signature to array");
            return false;
        }
    };

    // Create x-only public key (returns Result)
    let pubkey = match XOnlyPublicKey::from_byte_array(pub_key_array) {
        Ok(key) => key,
        Err(_) => {
            eprintln!("Invalid public key format");
            return false;
        }
    };

    // Create signature from bytes (returns Signature directly)
    let signature = Signature::from_byte_array(signature_array);

    // Verify the signature using the global context (more efficient than creating a new context)
    match SECP256K1.verify_schnorr(&signature, &event_id_bytes, &pubkey) {
        Ok(_) => true,
        Err(_) => {
            eprintln!("Signature verification failed");
            false
        }
    }
}

#[test]
fn hash_event_data_valid() {
    let valid_id = "2bd7b2af40868949001713ffdcf95e1b1659dbbabe659ef9299d0fe11e31421d";

    let pubkey = "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798";
    let created_at = 1726215220;
    let kind = 1;
    let tags: Vec<Vec<String>> = vec![];
    let content = "hello world";

    let result = hash_event_data(pubkey, created_at, kind, tags, content);
    println!("result: {}", result);

    assert_eq!(result, valid_id);
}

#[test]
fn hash_event_data_invalid() {
    let valid_id = "2bd7b2af40868949001713ffdcf95e1b1659dbbabe659ef9299d0fe11e31421d";

    let pubkey = "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798";
    let created_at = 1726215220;
    let kind = 1;
    let tags: Vec<Vec<String>> = vec![];
    let content = "invalid";

    let result = hash_event_data(pubkey, created_at, kind, tags, content);
    println!("result: {}", result);

    assert_ne!(result, valid_id);
}

/**
 * hashes the given params, in nostr this is the id
 * [return] hash / nostrId
 */
pub fn hash_event_data(
    pubkey: &str,
    created_at: u64,
    kind: u16,
    tags: Vec<Vec<String>>,
    content: &str,
) -> String {
    // Manually build JSON string to avoid serde_json overhead
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
            // Escape special characters in JSON strings
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
    // Escape special characters in content
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

#[test]
fn profile_verify_schnorr_signature() {
    use std::time::Instant;

    let pub_key_hex = "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798";
    let event_id = "a47c525970d21575c67e6f1e47674f1b82fc7edabb098fac4be21bb05425b389";
    let signature_hex = "b03ddc4930776698d39caa3df0cd887558ceea281eb9e2524daaba324906b2e3efc06f2f65a7fbba95c0b3ce9817df81f53d2d8da0124028446b0cc3a59ae6d9";

    // Warmup run
    verify_schnorr_signature(pub_key_hex, event_id, signature_hex);

    // Profile single run
    let start = Instant::now();
    let result = verify_schnorr_signature(pub_key_hex, event_id, signature_hex);
    let duration = start.elapsed();
    
    println!("Single signature verification: {:?}", duration);
    assert!(result);

    // Profile multiple runs
    let iterations = 1000;
    let start = Instant::now();
    for _ in 0..iterations {
        verify_schnorr_signature(pub_key_hex, event_id, signature_hex);
    }
    let duration = start.elapsed();
    
    println!("Total time for {} iterations: {:?}", iterations, duration);
    println!("Average time per verification: {:?}", duration / iterations);
}

#[test]
fn profile_verify_nostr_event() {
    use std::time::Instant;

    let event_id = "40965bc361b5371f19ecf906706536d822e1a93ab8e23088d7faaf7f2d8628b1";
    let pub_key_hex = "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798";
    let created_at = 1770803371;
    let kind = 1;
    let tags: Vec<Vec<String>> = vec![];
    let content = "hello world";
    let signature_hex = "7d7642631a987cc8300835d66ac0a2f555f34075d887a1386ef1a090534ab35675722be96d2616a8e1bd42568259868b2f77b33363b6349acdec28291d357af6";

    // Warmup run
    verify_nostr_event(event_id, pub_key_hex, created_at, kind, tags.clone(), content, signature_hex);

    // Profile single run
    let start = Instant::now();
    let result = verify_nostr_event(event_id, pub_key_hex, created_at, kind, tags.clone(), content, signature_hex);
    let duration = start.elapsed();
    
    println!("Single full event verification: {:?}", duration);
    assert!(result);

    // Profile multiple runs
    let iterations = 1000;
    let start = Instant::now();
    for _ in 0..iterations {
        verify_nostr_event(event_id, pub_key_hex, created_at, kind, tags.clone(), content, signature_hex);
    }
    let duration = start.elapsed();
    
    println!("Total time for {} iterations: {:?}", iterations, duration);
    println!("Average time per full verification: {:?}", duration / iterations);
}
