import 'dart:ffi';

import 'package:ffi/ffi.dart';

/// FFI bindings to the native Rust library.
/// This file is referenced by the native assets build hook.

/// Verifies a Nostr event signature.
///
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

/// Verifies a Schnorr signature.
///
/// Returns 1 if valid, 0 if invalid.
@Native<
    Int32 Function(
      Pointer<Utf8>, // pubKeyHex
      Pointer<Utf8>, // eventIdHex
      Pointer<Utf8>, // signatureHex
    )>(symbol: 'verify_schnorr_signature')
external int verifySchnorrSignatureNative(
  Pointer<Utf8> pubKeyHex,
  Pointer<Utf8> eventIdHex,
  Pointer<Utf8> signatureHex,
);
