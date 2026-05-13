import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../../../domain_layer/entities/nip_01_event.dart';
import '../../../domain_layer/repositories/event_verifier.dart';
import '../../../src/rust_lib.dart' as rust_lib;

/// An implementation of [EventVerifier] that uses quantum-secure
/// CRYSTALS-Dilithium signatures via native Rust FFI.
class QsRustEventVerifier implements EventVerifier {
  /// The Dilithium security level (2, 3, or 5).
  final int level;

  /// Creates a new instance of [QsRustEventVerifier].
  ///
  /// [level] defaults to 2 (NIST Security Level 2, ~AES-128).
  QsRustEventVerifier({this.level = 2});

  @override
  Future<bool> verify(Nip01Event event) async {
    if (event.sig == null) {
      return false;
    }

    // Decode hex-encoded public key and signature to bytes
    final pkBytes = _hexToBytes(event.pubKey);
    final sigBytes = _hexToBytes(event.sig!);

    if (pkBytes == null || sigBytes == null) {
      return false;
    }

    // The message to verify is the event id (the hash of the serialized event)
    final msgBytes = _hexToBytes(event.id);
    if (msgBytes == null) {
      return false;
    }

    // Allocate native memory
    final pkPtr = calloc<Uint8>(pkBytes.length);
    final msgPtr = calloc<Uint8>(msgBytes.length);
    final sigPtr = calloc<Uint8>(sigBytes.length);

    try {
      // Copy bytes to native memory
      pkPtr.asTypedList(pkBytes.length).setAll(0, pkBytes);
      msgPtr.asTypedList(msgBytes.length).setAll(0, msgBytes);
      sigPtr.asTypedList(sigBytes.length).setAll(0, sigBytes);

      final result = rust_lib.qsVerify(
        level,
        pkPtr,
        pkBytes.length,
        msgPtr,
        msgBytes.length,
        sigPtr,
        sigBytes.length,
      );

      return result == 1;
    } finally {
      calloc.free(pkPtr);
      calloc.free(msgPtr);
      calloc.free(sigPtr);
    }
  }

  /// Converts a hex string to bytes. Returns null if invalid.
  static Uint8List? _hexToBytes(String hex) {
    if (hex.length % 2 != 0) return null;
    try {
      final bytes = Uint8List(hex.length ~/ 2);
      for (var i = 0; i < hex.length; i += 2) {
        bytes[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
      }
      return bytes;
    } catch (_) {
      return null;
    }
  }
}
