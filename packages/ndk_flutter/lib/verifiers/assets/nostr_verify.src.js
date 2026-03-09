import { schnorr } from '@noble/curves/secp256k1.js';
import { sha256 } from '@noble/hashes/sha2.js';
import { bytesToHex } from '@noble/hashes/utils.js';

/**
 * Serialize a Nostr event for hashing (NIP-01)
 */
function serializeEvent(event) {
  return JSON.stringify([
    0,
    event.pubkey,
    event.created_at,
    event.kind,
    event.tags,
    event.content
  ]);
}

/**
 * Compute the event ID (SHA256 hash of serialized event)
 */
function getEventHash(event) {
  const serialized = serializeEvent(event);
  const encoder = new TextEncoder();
  const data = encoder.encode(serialized);
  return bytesToHex(sha256(data));
}

/**
 * Verify a Nostr event signature
 * @param {Object} event - Nostr event with id, pubkey, sig, created_at, kind, tags, content
 * @returns {Promise<boolean>} - true if valid, false otherwise
 */
async function verifyEvent(event) {
  try {
    // Verify the event ID matches the hash
    const expectedId = getEventHash(event);
    if (event.id !== expectedId) {
      return false;
    }

    // Verify the Schnorr signature
    const signatureBytes = hexToBytes(event.sig);
    const messageBytes = hexToBytes(event.id);
    const publicKeyBytes = hexToBytes(event.pubkey);

    return schnorr.verify(signatureBytes, messageBytes, publicKeyBytes);
  } catch (e) {
    console.error('Event verification error:', e);
    return false;
  }
}

/**
 * Verify a Schnorr signature directly
 * @param {string} signatureHex - 64-byte signature in hex
 * @param {string} messageHash - 32-byte message hash in hex
 * @param {string} publicKeyHex - 32-byte public key in hex
 * @returns {Promise<boolean>}
 */
async function verifySignature(signatureHex, messageHash, publicKeyHex) {
  try {
    const signatureBytes = hexToBytes(signatureHex);
    const messageBytes = hexToBytes(messageHash);
    const publicKeyBytes = hexToBytes(publicKeyHex);

    return schnorr.verify(signatureBytes, messageBytes, publicKeyBytes);
  } catch (e) {
    console.error('Signature verification error:', e);
    return false;
  }
}

/**
 * Convert hex string to Uint8Array
 */
function hexToBytes(hex) {
  const bytes = new Uint8Array(hex.length / 2);
  for (let i = 0; i < bytes.length; i++) {
    bytes[i] = parseInt(hex.substr(i * 2, 2), 16);
  }
  return bytes;
}

// Expose to global scope for Dart JS interop
window.NostrVerifier = {
  verifyEvent,
  verifySignature
};
