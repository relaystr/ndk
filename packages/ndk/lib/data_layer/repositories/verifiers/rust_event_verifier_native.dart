import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../../domain_layer/entities/nip_01_event.dart';
import '../../../domain_layer/entities/nip_01_utils.dart';
import '../../../domain_layer/repositories/event_verifier.dart';
import '../../../src/rust_lib.dart' as rust_lib;

/// An implementation of [EventVerifier] that uses native Rust for event verification.
///
/// This class provides a bridge between Dart and Rust via FFI using native assets,
/// allowing for efficient verification of Nostr events using Rust's performance capabilities.
class RustEventVerifier implements EventVerifier {
  /// Creates a new instance of [RustEventVerifier].
  RustEventVerifier();

  @override
  Future<bool> verify(Nip01Event event) async {
    final signature = event.sig;
    if (signature == null ||
        !_isHex(event.id, 64) ||
        !_isHex(event.pubKey, 64) ||
        !_isHex(signature, 128) ||
        !Nip01Utils.isIdValid(event)) {
      return false;
    }

    // The validated event id commits to every event field. Only the fixed-size
    // Schnorr inputs need to cross FFI. One packed allocation replaces the
    // previous allocation per field, tag, and nested Rust String.
    const packedLength = 64 + 64 + 128;
    final packed = malloc<Uint8>(packedLength);

    try {
      final bytes = packed.asTypedList(packedLength);
      _copyAscii(event.id, bytes, 0);
      _copyAscii(event.pubKey, bytes, 64);
      _copyAscii(signature, bytes, 128);
      return rust_lib.verifySchnorrSignaturePackedNative(
            packed,
            packedLength,
          ) ==
          1;
    } finally {
      malloc.free(packed);
    }
  }

  static bool _isHex(String value, int expectedLength) {
    if (value.length != expectedLength) return false;
    for (final codeUnit in value.codeUnits) {
      final digit = codeUnit >= 0x30 && codeUnit <= 0x39;
      final lower = codeUnit >= 0x61 && codeUnit <= 0x66;
      final upper = codeUnit >= 0x41 && codeUnit <= 0x46;
      if (!digit && !lower && !upper) return false;
    }
    return true;
  }

  static void _copyAscii(String source, List<int> target, int offset) {
    final codeUnits = source.codeUnits;
    for (var index = 0; index < codeUnits.length; index++) {
      target[offset + index] = codeUnits[index];
    }
  }
}
