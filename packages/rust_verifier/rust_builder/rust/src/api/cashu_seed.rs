use bip32::{DerivationPath, ExtendedPrivateKey};
use bip39::Mnemonic;
use hex;
use std::str::FromStr;

pub struct CashuSeedDeriveSecretResultRust {
    pub secret_hex: String,
    pub blinding_hex: String,
}

const DERIVATION_PURPOSE: u32 = 129372;
const DERIVATION_COIN_TYPE: u32 = 0;

/// Convert a keyset ID (hex string) to an integer for use in derivation path
/// Performs: BigInt.parse(keysetId, radix: 16) % (2^31 - 1)
pub fn keyset_id_to_int(keyset_id: &str) -> Result<u32, String> {
    // Parse hex string to u64
    let number = u64::from_str_radix(keyset_id, 16)
        .map_err(|e| format!("Failed to parse keyset_id as hex: {}", e))?;

    // Modulus is 2^31 - 1 = 2147483647
    let modulus: u64 = 2147483647;
    let keyset_id_int = (number % modulus) as u32;

    Ok(keyset_id_int)
}

/// Generate a new BIP39 seed phrase
/// Returns a 24-word mnemonic by default (32 bytes of entropy)
pub fn generate_seed_phrase() -> Result<String, String> {
    use bip39::Language;
    use rand_core::OsRng;

    let mut entropy = [0u8; 32]; // 32 bytes = 256 bits = 24 words
    rand_core::RngCore::fill_bytes(&mut OsRng, &mut entropy);

    let mnemonic = Mnemonic::from_entropy_in(Language::English, &entropy)
        .map_err(|e| format!("Failed to generate mnemonic: {}", e))?;

    Ok(mnemonic.to_string())
}

/// Derive a secret and blinding factor from a BIP39 seed phrase
///
/// # Arguments
/// * `seed_phrase` - BIP39 mnemonic phrase (space-separated words)
/// * `passphrase` - Optional passphrase (use empty string if none)
/// * `counter` - Counter value for derivation
/// * `keyset_id` - Keyset ID as hex string
///
/// # Returns
/// Result containing secret_hex and blinding_hex, or an error message
pub fn derive_secret_rust(
    seed_phrase: &str,
    passphrase: &str,
    counter: u32,
    keyset_id: &str,
) -> Result<CashuSeedDeriveSecretResultRust, String> {
    use bip32::ChildNumber;
    use bip39::Language;

    // Parse the mnemonic
    let mnemonic = Mnemonic::parse_in_normalized(Language::English, seed_phrase)
        .map_err(|e| format!("Invalid seed phrase: {}", e))?;

    // Convert keyset_id to int
    let keyset_id_int = keyset_id_to_int(keyset_id)?;

    // Generate seed from mnemonic (with optional passphrase)
    let seed = mnemonic.to_seed(passphrase);

    // Create master key from seed
    let master_key = ExtendedPrivateKey::<k256::SecretKey>::new(seed)
        .map_err(|e| format!("Failed to create master key: {}", e))?;

    // Build derivation path components: m/129372'/0'/keyset_id_int'/counter'
    // Constants are safe to unwrap; dynamic values use proper error handling
    let path_components = [
        ChildNumber::new(DERIVATION_PURPOSE, true).unwrap(),
        ChildNumber::new(DERIVATION_COIN_TYPE, true).unwrap(),
        ChildNumber::new(keyset_id_int, true).map_err(|e| format!("Invalid keyset_id: {}", e))?,
        ChildNumber::new(counter, true).map_err(|e| format!("Invalid counter: {}", e))?,
    ];

    // Derive common parent path once (avoiding duplicate derivations)
    let mut parent_key = master_key;
    for &child_number in &path_components {
        parent_key = parent_key
            .derive_child(child_number)
            .map_err(|e| format!("Failed to derive parent key: {}", e))?;
    }

    // Derive final keys (non-hardened /0 and /1)
    let derived_secret = parent_key
        .derive_child(ChildNumber::new(0, false).unwrap())
        .map_err(|e| format!("Failed to derive secret key: {}", e))?;

    let derived_blinding = parent_key
        .derive_child(ChildNumber::new(1, false).unwrap())
        .map_err(|e| format!("Failed to derive blinding key: {}", e))?;

    // Get private key bytes and encode to hex
    let secret_hex = hex::encode(derived_secret.private_key().to_bytes());
    let blinding_hex = hex::encode(derived_blinding.private_key().to_bytes());

    Ok(CashuSeedDeriveSecretResultRust {
        secret_hex,
        blinding_hex,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_keyset_id_to_int() {
        // Test a simple hex value
        let result = keyset_id_to_int("1a").unwrap();
        assert_eq!(result, 26);

        // Test modulo operation with a large value
        let large_hex = "FFFFFFFFFFFFFFFF"; // u64::MAX = 18446744073709551615
        let result = keyset_id_to_int(large_hex).unwrap();
        // 18446744073709551615 % 2147483647 = 3
        assert_eq!(result, 3);
    }

    #[test]
    fn test_generate_seed_phrase() {
        use bip39::Language;

        let phrase = generate_seed_phrase().unwrap();
        // Should generate 24 words
        assert_eq!(phrase.split_whitespace().count(), 24);

        // Should be valid
        assert!(Mnemonic::parse_in_normalized(Language::English, &phrase).is_ok());
    }

    #[test]
    fn test_derive_secret() {
        // Use a known test mnemonic
        let seed_phrase = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";
        let passphrase = "";
        let counter = 0;
        let keyset_id = "1a";

        let result = derive_secret_rust(seed_phrase, passphrase, counter, keyset_id);
        assert!(result.is_ok());

        let derived = result.unwrap();
        // Verify hex strings are valid and have correct length (64 chars = 32 bytes)
        assert_eq!(derived.secret_hex.len(), 64);
        assert_eq!(derived.blinding_hex.len(), 64);
        assert!(hex::decode(&derived.secret_hex).is_ok());
        assert!(hex::decode(&derived.blinding_hex).is_ok());

        // Test with different counter produces different results
        let result2 = derive_secret_rust(seed_phrase, passphrase, 1, keyset_id).unwrap();
        assert_ne!(derived.secret_hex, result2.secret_hex);
        assert_ne!(derived.blinding_hex, result2.blinding_hex);
    }

    #[test]
    fn test_derive_secret_with_passphrase() {
        let seed_phrase = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";
        let result1 = derive_secret_rust(seed_phrase, "", 0, "1a").unwrap();
        let result2 = derive_secret_rust(seed_phrase, "test_passphrase", 0, "1a").unwrap();

        // Different passphrase should produce different results
        assert_ne!(result1.secret_hex, result2.secret_hex);
        assert_ne!(result1.blinding_hex, result2.blinding_hex);
    }

    #[test]
    fn test_derive_secret_matches_dart_implementation() {
        // Test values from the Dart implementation test
        let mnemonic =
            "half depart obvious quality work element tank gorilla view sugar picture humble";
        let keyset_id = "009a1f293253e41e";

        // Expected values from Dart implementation
        let expected_secrets = [
            "485875df74771877439ac06339e284c3acfcd9be7abf3bc20b516faeadfe77ae",
            "8f2b39e8e594a4056eb1e6dbb4b0c38ef13b1b2c751f64f810ec04ee35b77270",
            "bc628c79accd2364fd31511216a0fab62afd4a18ff77a20deded7b858c9860c8",
            "59284fd1650ea9fa17db2b3acf59ecd0f2d52ec3261dd4152785813ff27a33bf",
            "576c23393a8b31cc8da6688d9c9a96394ec74b40fdaf1f693a6bb84284334ea0",
        ];

        let expected_blinding_factors = [
            "ad00d431add9c673e843d4c2bf9a778a5f402b985b8da2d5550bf39cda41d679",
            "967d5232515e10b81ff226ecf5a9e2e2aff92d66ebc3edf0987eb56357fd6248",
            "b20f47bb6ae083659f3aa986bfa0435c55c6d93f687d51a01f26862d9b9a4899",
            "fb5fca398eb0b1deb955a2988b5ac77d32956155f1c002a373535211a2dfdc29",
            "5f09bfbfe27c439a597719321e061e2e40aad4a36768bb2bcc3de547c9644bf9",
        ];

        // Test keysetId conversion
        let keyset_id_int = keyset_id_to_int(keyset_id).unwrap();
        assert_eq!(keyset_id_int, 864559728);

        // Test derivation for counters 0-4
        for i in 0..5 {
            let result = derive_secret_rust(mnemonic, "", i, keyset_id).unwrap();
            assert_eq!(
                result.secret_hex, expected_secrets[i as usize],
                "Secret mismatch for counter {}",
                i
            );
            assert_eq!(
                result.blinding_hex, expected_blinding_factors[i as usize],
                "Blinding factor mismatch for counter {}",
                i
            );
        }
    }
}
