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

// ── Quantum-Secure Dilithium bindings ──────────────────────────────────

/// Frees a QsBuffer previously returned by the Rust library.
@Native<Void Function(QsBuffer)>(symbol: 'qs_free_buffer')
external void qsFreeBuffer(QsBuffer buf);

/// Generates a Dilithium keypair.
///
/// [level]: security level (2, 3, or 5).
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

/// Signs a message with a Dilithium secret key.
///
/// [level]: security level (2, 3, or 5).
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

/// Verifies a Dilithium signature.
///
/// [level]: security level (2, 3, or 5).
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
