// Cashu Key Derivation JavaScript implementation
// This file provides the core key derivation logic for web platform
//
// This implementation is based on the Cashu protocol's key derivation specification
// and is called from Dart via JS interop when running on web platforms.
//
// The implementation supports:
// - Modern derivation (v01): HMAC-SHA256 based
// - Legacy derivation (v00): BIP32 hierarchical deterministic
//
// Dependencies are loaded from esm.sh CDN:
// - @noble/hashes@1.3.3: Cryptographic hash functions (audited, widely used)
// - @scure/bip32@1.3.3: BIP32 hierarchical deterministic keys (audited, widely used)
//
// NOTE: These specific versions are pinned for reproducibility and security.
// Consider hosting these libraries locally in production for better reliability
// and to avoid runtime dependencies on external CDN infrastructure.

import { hmac } from 'https://esm.sh/@noble/hashes@1.3.3/hmac';
import { sha256 } from 'https://esm.sh/@noble/hashes@1.3.3/sha256';
import { HDKey } from 'https://esm.sh/@scure/bip32@1.3.3';

const STANDARD_DERIVATION_PATH = `m/129372'/0'`;
const SECP256K1_N = BigInt('0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141');

const DerivationType = {
  SECRET: 0,
  BLINDING_FACTOR: 1,
};

// Helper functions for bytes manipulation
const Bytes = {
  concat: (...arrays) => {
    const totalLength = arrays.reduce((acc, arr) => acc + arr.length, 0);
    const result = new Uint8Array(totalLength);
    let offset = 0;
    for (const arr of arrays) {
      result.set(arr, offset);
      offset += arr.length;
    }
    return result;
  },
  
  fromString: (str) => new TextEncoder().encode(str),
  
  fromHex: (hex) => {
    // Validate hex string
    if (!hex || hex.length % 2 !== 0) {
      throw new Error('Invalid hex string: must have even length');
    }
    if (!/^[0-9a-fA-F]*$/.test(hex)) {
      throw new Error('Invalid hex string: contains non-hex characters');
    }
    
    const bytes = new Uint8Array(hex.length / 2);
    for (let i = 0; i < hex.length; i += 2) {
      bytes[i / 2] = parseInt(hex.substring(i, i + 2), 16);
    }
    return bytes;
  },
  
  writeBigUint64BE: (value) => {
    const buffer = new ArrayBuffer(8);
    const view = new DataView(buffer);
    view.setBigUint64(0, BigInt(value), false); // false for big-endian
    return new Uint8Array(buffer);
  },
  
  toBigInt: (bytes) => {
    let result = 0n;
    for (let i = 0; i < bytes.length; i++) {
      result = (result << 8n) | BigInt(bytes[i]);
    }
    return result;
  },
  
  fromBigInt: (value) => {
    const hex = value.toString(16).padStart(64, '0');
    return Bytes.fromHex(hex);
  },
  
  toHex: (bytes) => {
    return Array.from(bytes)
      .map(b => b.toString(16).padStart(2, '0'))
      .join('');
  }
};

const isBase64String = (str) => {
  // Check if string matches Base64 format
  if (!/^[A-Za-z0-9+/]*={0,2}$/.test(str)) {
    return false;
  }
  // Additional length validation: Base64 length must be a multiple of 4
  if (str.length % 4 !== 0) {
    return false;
  }
  try {
    return btoa(atob(str)) === str;
  } catch (err) {
    return false;
  }
};

const getKeysetIdInt = (keysetId) => {
  // Validate that keysetId is a valid hex string
  if (!/^[0-9a-fA-F]+$/.test(keysetId)) {
    throw new Error('Invalid keysetId: must be a hex string');
  }
  
  const number = BigInt('0x' + keysetId);
  const modulus = BigInt(2147483647); // 2^31 - 1
  return Number(number % modulus);
};

const deriveSecret = (seed, keysetId, counter) => {
  if (!keysetId || keysetId.length < 2) {
    throw new Error('Invalid keysetId: must be at least 2 characters');
  }
  
  const isValidHex = /^[a-fA-F0-9]+$/.test(keysetId);
  if (!isValidHex && isBase64String(keysetId)) {
    return derive_deprecated(seed, keysetId, counter, DerivationType.SECRET);
  }

  if (isValidHex && keysetId.startsWith('00')) {
    return derive_deprecated(seed, keysetId, counter, DerivationType.SECRET);
  } else if (isValidHex && keysetId.startsWith('01')) {
    return derive(seed, keysetId, counter, DerivationType.SECRET);
  }
  throw new Error(`Unrecognized keyset ID format or version: ${keysetId.substring(0, 2)}`);
};

const deriveBlindingFactor = (seed, keysetId, counter) => {
  if (!keysetId || keysetId.length < 2) {
    throw new Error('Invalid keysetId: must be at least 2 characters');
  }
  
  const isValidHex = /^[a-fA-F0-9]+$/.test(keysetId);
  if (!isValidHex && isBase64String(keysetId)) {
    return derive_deprecated(seed, keysetId, counter, DerivationType.BLINDING_FACTOR);
  }

  if (isValidHex && keysetId.startsWith('00')) {
    return derive_deprecated(seed, keysetId, counter, DerivationType.BLINDING_FACTOR);
  } else if (isValidHex && keysetId.startsWith('01')) {
    return derive(seed, keysetId, counter, DerivationType.BLINDING_FACTOR);
  }
  throw new Error(`Unrecognized keyset ID format or version: ${keysetId.substring(0, 2)}`);
};

const derive = (seed, keysetId, counter, secretOrBlinding) => {
  let message = Bytes.concat(
    Bytes.fromString('Cashu_KDF_HMAC_SHA256'),
    Bytes.fromHex(keysetId),
    Bytes.writeBigUint64BE(BigInt(counter)),
  );

  switch (secretOrBlinding) {
    case DerivationType.SECRET:
      message = Bytes.concat(message, Bytes.fromHex('00'));
      break;
    case DerivationType.BLINDING_FACTOR:
      message = Bytes.concat(message, Bytes.fromHex('01'));
      break;
  }

  const hmacDigest = hmac(sha256, seed, message);

  if (secretOrBlinding === DerivationType.BLINDING_FACTOR) {
    const x = Bytes.toBigInt(hmacDigest);
    // Optimization: single subtraction instead of modulo
    // Probability of HMAC >= SECP256K1_N is ~2^-128
    if (x >= SECP256K1_N) {
      return Bytes.fromBigInt(x - SECP256K1_N);
    }
    if (x === 0n) {
      throw new Error('Derived invalid blinding scalar r == 0');
    }
    return hmacDigest;
  }

  return hmacDigest;
};

const derive_deprecated = (seed, keysetId, counter, secretOrBlinding) => {
  const hdkey = HDKey.fromMasterSeed(seed);
  const keysetIdInt = getKeysetIdInt(keysetId);
  const derivationPath = `${STANDARD_DERIVATION_PATH}/${keysetIdInt}'/${counter}'/${secretOrBlinding}`;
  const derived = hdkey.derive(derivationPath);
  if (derived.privateKey === null) {
    throw new Error('Could not derive private key');
  }
  return derived.privateKey;
};

// Wrapper function that returns both secret and blinding factor
const deriveSecretAndBlinding = (seed, keysetId, counter) => {
  const secret = deriveSecret(seed, keysetId, counter);
  const blinding = deriveBlindingFactor(seed, keysetId, counter);
  
  return {
    secretHex: Bytes.toHex(secret),
    blindingHex: Bytes.toHex(blinding),
  };
};

// Export for use from Dart
window.cashuKeyDerivation = {
  deriveSecret: (seedArray, keysetId, counter) => {
    const seed = new Uint8Array(seedArray);
    const result = deriveSecret(seed, keysetId, counter);
    return Bytes.toHex(result);
  },
  
  deriveBlindingFactor: (seedArray, keysetId, counter) => {
    const seed = new Uint8Array(seedArray);
    const result = deriveBlindingFactor(seed, keysetId, counter);
    return Bytes.toHex(result);
  },
  
  deriveSecretAndBlinding: (seedArray, keysetId, counter) => {
    const seed = new Uint8Array(seedArray);
    return deriveSecretAndBlinding(seed, keysetId, counter);
  }
};
