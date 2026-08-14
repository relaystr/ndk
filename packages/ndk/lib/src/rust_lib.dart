import 'dart:ffi';

import 'package:ffi/ffi.dart';

// ── QsBuffer struct ────────────────────────────────────────────────────

final class QsBuffer extends Struct {
  external Pointer<Uint8> data;

  @IntPtr()
  external int len;
}

// ── Existing Nostr / Schnorr bindings ──────────────────────────────────

/// Verifies a Nostr event signature.
/// Returns 1 if valid, 0 if invalid.
@Native<
    Int32 Function(
      Pointer<Utf8>, // eventIdHex
      Pointer<Utf8>, // pubKeyHex
      Uint64, // createdAt
      Uint32, // kind
      Pointer<Pointer<Utf8>>, // tagsData
      Pointer<Uint32>, // tagsLengths
      Uint32, // tagsCount
      Pointer<Utf8>, // content
      Pointer<Utf8>, // signatureHex
    )>(symbol: 'verify_nostr_event')
external int verifyNostrEventNative(
  Pointer<Utf8> eventIdHex,
  Pointer<Utf8> pubKeyHex,
  int createdAt,
  int kind,
  Pointer<Pointer<Utf8>> tagsData,
  Pointer<Uint32> tagsLengths,
  int tagsCount,
  Pointer<Utf8> content,
  Pointer<Utf8> signatureHex,
);

// ── Quantum-Secure ML-DSA (FIPS 204) bindings ──────────────────────────
//
// These were CRYSTALS-Dilithium. NIST altered the algorithm during
// standardisation, so Dilithium keys and signatures are not interoperable with
// FIPS 204 ML-DSA. [level] now takes the ML-DSA parameter numbers - 44, 65 or 87 -
// and the old Dilithium values 2, 3 and 5 are rejected rather than remapped, so a
// caller that was not updated fails loudly instead of silently getting different
// security properties than it asked for.

/// Frees a QsBuffer previously returned by the Rust library.
@Native<Void Function(QsBuffer)>(symbol: 'qs_free_buffer')
external void qsFreeBuffer(QsBuffer buf);

/// Generates a random ML-DSA keypair.
///
/// Prefer [qsDeriveKeypairFromSeed] for anything representing an identity: a
/// random key cannot be restored from a mnemonic, so losing it loses the identity.
///
/// [level]: ML-DSA parameter set (44, 65, or 87).
/// [outPk], [outSk]: pointers to QsBuffer structs that will be filled.
/// Returns 1 on success, 0 on failure.
@Native<
    Int32 Function(
      Uint32, // level
      Pointer<QsBuffer>, // outPk
      Pointer<QsBuffer>, // outSk
    )>(symbol: 'qs_generate_keypair')
external int qsGenerateKeypair(
  int level,
  Pointer<QsBuffer> outPk,
  Pointer<QsBuffer> outSk,
);

/// Signs a message with an ML-DSA secret key (empty FIPS 204 context).
///
/// [level]: ML-DSA parameter set (44, 65, or 87).
/// [skPtr]/[skLen]: secret key bytes.
/// [msgPtr]/[msgLen]: message bytes.
/// [outSig]: pointer to QsBuffer that will receive the signature.
/// Returns 1 on success, 0 on failure.
@Native<
    Int32 Function(
      Uint32, // level
      Pointer<Uint8>, // skPtr
      IntPtr, // skLen
      Pointer<Uint8>, // msgPtr
      IntPtr, // msgLen
      Pointer<QsBuffer>, // outSig
    )>(symbol: 'qs_sign')
external int qsSign(
  int level,
  Pointer<Uint8> skPtr,
  int skLen,
  Pointer<Uint8> msgPtr,
  int msgLen,
  Pointer<QsBuffer> outSig,
);

/// Verifies an ML-DSA signature (empty FIPS 204 context).
///
/// [level]: ML-DSA parameter set (44, 65, or 87).
/// Returns 1 if valid, 0 if invalid.
@Native<
    Int32 Function(
      Uint32, // level
      Pointer<Uint8>, // pkPtr
      IntPtr, // pkLen
      Pointer<Uint8>, // msgPtr
      IntPtr, // msgLen
      Pointer<Uint8>, // sigPtr
      IntPtr, // sigLen
    )>(symbol: 'qs_verify')
external int qsVerify(
  int level,
  Pointer<Uint8> pkPtr,
  int pkLen,
  Pointer<Uint8> msgPtr,
  int msgLen,
  Pointer<Uint8> sigPtr,
  int sigLen,
);

/// Derives an ML-DSA keypair deterministically from a 64-byte BIP-39 seed.
///
/// The key is a sibling of the secp256k1 key derived from the same mnemonic, not a
/// child of it, so one mnemonic restores both and breaking secp256k1 does not reach
/// this key.
///
/// [seedPtr]/[seedLen] must be a 64-byte BIP-39 seed. Passing a 32-byte secp256k1
/// private key is rejected: deriving from it would be circular.
/// Returns 1 on success, 0 on failure.
@Native<
    Int32 Function(
      Uint32, // level
      Pointer<Uint8>, // seedPtr
      IntPtr, // seedLen
      Uint32, // account
      Pointer<QsBuffer>, // outPk
      Pointer<QsBuffer>, // outSk
    )>(symbol: 'qs_derive_keypair_from_seed')
external int qsDeriveKeypairFromSeed(
  int level,
  Pointer<Uint8> seedPtr,
  int seedLen,
  int account,
  Pointer<QsBuffer> outPk,
  Pointer<QsBuffer> outSk,
);
