import { schnorr, secp256k1 } from '@noble/curves/secp256k1.js';
import { sha256 } from '@noble/hashes/sha2.js';
import { bytesToHex } from '@noble/hashes/utils.js';
import { chacha20 } from '@noble/ciphers/chacha.js';

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
 * Sign a message hash with a private key (BIP-340 Schnorr)
 * @param {string} privateKeyHex - 32-byte private key in hex
 * @param {string} messageHashHex - 32-byte message hash in hex
 * @returns {Promise<string>} - 64-byte signature in hex
 */
async function signEvent(privateKeyHex, messageHashHex) {
  try {
    const privateKeyBytes = hexToBytes(privateKeyHex);
    const messageBytes = hexToBytes(messageHashHex);
    const signatureBytes = schnorr.sign(messageBytes, privateKeyBytes);
    return bytesToHex(signatureBytes);
  } catch (e) {
    console.error('Event signing error:', e);
    throw e;
  }
}

// ---------------------------------------------------------------------------
// Crypto helpers
// ---------------------------------------------------------------------------

function hexToBytes(hex) {
  const bytes = new Uint8Array(hex.length / 2);
  for (let i = 0; i < bytes.length; i++) {
    bytes[i] = parseInt(hex.substr(i * 2, 2), 16);
  }
  return bytes;
}

function bytesToBase64(bytes) {
  let binary = '';
  for (let i = 0; i < bytes.length; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary);
}

function base64ToBytes(base64) {
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
}

function getSharedSecret(privateKeyHex, publicKeyHex) {
  const privateKeyBytes = hexToBytes(privateKeyHex);
  // @noble/curves expects compressed (33-byte) or uncompressed (65-byte) public keys.
  // Dart package:elliptic uses raw 32-byte X coordinates, so we prepend '02' if needed.
  let normalizedPubHex = publicKeyHex;
  if (publicKeyHex.length === 64) {
    normalizedPubHex = '02' + publicKeyHex;
  }
  const publicKeyBytes = hexToBytes(normalizedPubHex);
  // getSharedSecret returns a compressed point (33 bytes). Slice off the prefix
  // to get the X coordinate (32 bytes), matching package:elliptic behaviour.
  const shared = secp256k1.getSharedSecret(privateKeyBytes, publicKeyBytes, true);
  return shared.slice(1, 33);
}

async function hmacSha256(key, data) {
  const cryptoKey = await crypto.subtle.importKey(
    'raw', key, { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']
  );
  const signature = await crypto.subtle.sign('HMAC', cryptoKey, data);
  return new Uint8Array(signature);
}

async function hkdfExtract(ikm, salt) {
  return hmacSha256(salt, ikm);
}

async function hkdfExpand(prk, info, length) {
  const hashLen = 32;
  const n = Math.ceil(length / hashLen);
  let okm = new Uint8Array(0);
  let previous = new Uint8Array(0);
  for (let i = 1; i <= n; i++) {
    const data = new Uint8Array(previous.length + info.length + 1);
    data.set(previous, 0);
    data.set(info, previous.length);
    data[data.length - 1] = i;
    previous = await hmacSha256(prk, data);
    const newOkm = new Uint8Array(okm.length + previous.length);
    newOkm.set(okm, 0);
    newOkm.set(previous, okm.length);
    okm = newOkm;
  }
  return okm.slice(0, length);
}

function equalBytes(a, b) {
  if (a.length !== b.length) return false;
  for (let i = 0; i < a.length; i++) {
    if (a[i] !== b[i]) return false;
  }
  return true;
}

// ---------------------------------------------------------------------------
// NIP-04
// ---------------------------------------------------------------------------

/**
 * Encrypt a NIP-04 message
 * @param {string} privateKeyHex
 * @param {string} publicKeyHex
 * @param {string} plaintext
 * @returns {Promise<string>}
 */
async function nip04Encrypt(privateKeyHex, publicKeyHex, plaintext) {
  const sharedSecret = getSharedSecret(privateKeyHex, publicKeyHex);
  const key = await crypto.subtle.importKey(
    'raw', sharedSecret, { name: 'AES-CBC' }, false, ['encrypt']
  );
  const iv = crypto.getRandomValues(new Uint8Array(16));
  const encoder = new TextEncoder();
  const encrypted = await crypto.subtle.encrypt(
    { name: 'AES-CBC', iv }, key, encoder.encode(plaintext)
  );
  const encryptedBytes = new Uint8Array(encrypted);
  return `${bytesToBase64(encryptedBytes)}?iv=${bytesToBase64(iv)}`;
}

/**
 * Decrypt a NIP-04 message
 * @param {string} privateKeyHex
 * @param {string} publicKeyHex
 * @param {string} ciphertext
 * @returns {Promise<string>}
 */
async function nip04Decrypt(privateKeyHex, publicKeyHex, ciphertext) {
  const [dataB64, ivB64] = ciphertext.split('?iv=');
  if (!ivB64) throw new Error('Invalid NIP-04 ciphertext');

  const sharedSecret = getSharedSecret(privateKeyHex, publicKeyHex);
  const key = await crypto.subtle.importKey(
    'raw', sharedSecret, { name: 'AES-CBC' }, false, ['decrypt']
  );
  const iv = base64ToBytes(ivB64);
  const data = base64ToBytes(dataB64);
  const decrypted = await crypto.subtle.decrypt(
    { name: 'AES-CBC', iv }, key, data
  );
  return new TextDecoder().decode(decrypted);
}

// ---------------------------------------------------------------------------
// NIP-44 helpers
// ---------------------------------------------------------------------------

function calcPaddedLen(unpaddedLen) {
  if (unpaddedLen < 1 || unpaddedLen > 65535) throw new Error('Invalid plaintext length');
  const nextPower = 2 ** ((unpaddedLen - 1).toString(2).length);
  const chunk = nextPower <= 256 ? 32 : nextPower / 8;
  if (unpaddedLen <= 32) return 32;
  return chunk * Math.ceil(unpaddedLen / chunk);
}

function pad(plaintext) {
  const unpaddedLen = plaintext.length;
  const paddedLen = calcPaddedLen(unpaddedLen);
  const padded = new Uint8Array(paddedLen + 2);
  padded[0] = (unpaddedLen >> 8) & 0xFF;
  padded[1] = unpaddedLen & 0xFF;
  padded.set(plaintext, 2);
  return padded;
}

function unpad(padded) {
  const unpaddedLen = (padded[0] << 8) + padded[1];
  if (unpaddedLen === 0 || unpaddedLen > padded.length - 2) throw new Error('Invalid padding');
  return padded.slice(2, 2 + unpaddedLen);
}

// ---------------------------------------------------------------------------
// NIP-44
// ---------------------------------------------------------------------------

/**
 * Encrypt a NIP-44 message
 * @param {string} privateKeyHex
 * @param {string} publicKeyHex
 * @param {string} plaintext
 * @returns {Promise<string>}
 */
async function nip44Encrypt(privateKeyHex, publicKeyHex, plaintext) {
  const sharedSecret = getSharedSecret(privateKeyHex, publicKeyHex);
  const salt = new TextEncoder().encode('nip44-v2');
  const conversationKey = await hkdfExtract(sharedSecret, salt);
  const nonce = crypto.getRandomValues(new Uint8Array(32));

  const hkdfOutput = await hkdfExpand(conversationKey, nonce, 76);
  const chachaKey = hkdfOutput.slice(0, 32);
  const chachaNonce = hkdfOutput.slice(32, 44);
  const hmacKey = hkdfOutput.slice(44, 76);

  const encoder = new TextEncoder();
  const paddedPlaintext = pad(encoder.encode(plaintext));
  const ciphertext = chacha20(chachaKey, chachaNonce, paddedPlaintext);
  const mac = await hmacSha256(
    hmacKey,
    new Uint8Array([...nonce, ...ciphertext])
  );

  const payload = new Uint8Array(1 + 32 + ciphertext.length + 32);
  payload[0] = 0x02;
  payload.set(nonce, 1);
  payload.set(ciphertext, 33);
  payload.set(mac, 33 + ciphertext.length);

  return bytesToBase64(payload);
}

/**
 * Decrypt a NIP-44 message
 * @param {string} privateKeyHex
 * @param {string} publicKeyHex
 * @param {string} payloadB64
 * @returns {Promise<string>}
 */
async function nip44Decrypt(privateKeyHex, publicKeyHex, payloadB64) {
  const payload = base64ToBytes(payloadB64);
  if (payload.length < 65 || payload.length > 87472) throw new Error('Invalid payload size');
  if (payload[0] !== 0x02) throw new Error('Unsupported version');

  const nonce = payload.slice(1, 33);
  const mac = payload.slice(payload.length - 32);
  const ciphertext = payload.slice(33, payload.length - 32);

  const sharedSecret = getSharedSecret(privateKeyHex, publicKeyHex);
  const salt = new TextEncoder().encode('nip44-v2');
  const conversationKey = await hkdfExtract(sharedSecret, salt);

  const hkdfOutput = await hkdfExpand(conversationKey, nonce, 76);
  const chachaKey = hkdfOutput.slice(0, 32);
  const chachaNonce = hkdfOutput.slice(32, 44);
  const hmacKey = hkdfOutput.slice(44, 76);

  const calculatedMac = await hmacSha256(
    hmacKey,
    new Uint8Array([...nonce, ...ciphertext])
  );
  if (!equalBytes(calculatedMac, mac)) throw new Error('Invalid MAC');

  const paddedPlaintext = chacha20(chachaKey, chachaNonce, ciphertext);
  const plaintext = unpad(paddedPlaintext);
  return new TextDecoder().decode(plaintext);
}

// Expose to global scope for Dart JS interop
window.NostrCrypto = {
  verifyEvent,
  verifySignature,
  signEvent,
  nip04Encrypt,
  nip04Decrypt,
  nip44Encrypt,
  nip44Decrypt,
};
