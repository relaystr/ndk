use hex::decode;
use k256::schnorr::{Signature, VerifyingKey};
use serde_json::json;
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

    // Create verifying key from the x-only public key bytes
    let verifying_key = match VerifyingKey::from_bytes(&pub_key_bytes) {
        Ok(key) => key,
        Err(_) => {
            eprintln!("Invalid public key format");
            return false;
        }
    };

    // Create signature from bytes
    let signature = match Signature::try_from(signature_bytes.as_slice()) {
        Ok(sig) => sig,
        Err(_) => {
            eprintln!("Invalid signature format");
            return false;
        }
    };

    // Verify the signature
    match verifying_key.verify_raw(&event_id_bytes, &signature) {
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
    let event = json!([0, pubkey, created_at, kind, tags, content]);

    let serialized_event = serde_json::to_string(&event).expect("Serialization error");

    let mut hasher = Sha256::new();
    hasher.update(serialized_event.as_bytes());
    let result = hasher.finalize();

    format!("{:x}", result)
}
