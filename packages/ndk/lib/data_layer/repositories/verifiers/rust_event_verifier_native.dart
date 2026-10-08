import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../../domain_layer/entities/nip_01_event.dart';
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
        !_isHex(signature, 128)) {
      return false;
    }

    // Id derivation, NIP-13 proof-of-work, and Schnorr verification all happen
    // in one native call. The fixed-size id/pubkey/signature triplet is packed
    // into a single allocation; tags and content are variable-length and must
    // still cross the FFI boundary since the id hash is derived from them.
    const packedLength = 64 + 64 + 128;
    final packed = malloc<Uint8>(packedLength);

    var tagsDataPtr = nullptr as Pointer<Pointer<Utf8>>;
    var tagsLengthsPtr = nullptr as Pointer<Uint32>;
    final tagItemPointers = <Pointer<Utf8>>[];
    Pointer<Utf8>? contentPtr;

    // Every allocation below must happen inside the try block: if one throws
    // (e.g. native OOM) partway through, prior allocations must still be freed.
    try {
      final tagsCount = event.tags.length;
      if (tagsCount > 0) {
        var flatCount = 0;
        for (final tag in event.tags) {
          flatCount += tag.length;
        }
        tagsDataPtr = malloc<Pointer<Utf8>>(flatCount > 0 ? flatCount : 1);
        tagsLengthsPtr = malloc<Uint32>(tagsCount);

        var offset = 0;
        for (var i = 0; i < tagsCount; i++) {
          final tag = event.tags[i];
          tagsLengthsPtr[i] = tag.length;
          for (final item in tag) {
            final itemPtr = item.toNativeUtf8();
            tagItemPointers.add(itemPtr);
            tagsDataPtr[offset] = itemPtr;
            offset++;
          }
        }
      }

      contentPtr = event.content.toNativeUtf8();

      final bytes = packed.asTypedList(packedLength);
      _copyAscii(event.id, bytes, 0);
      _copyAscii(event.pubKey, bytes, 64);
      _copyAscii(signature, bytes, 128);

      return rust_lib.verifyNostrEventPackedNative(
            packed,
            packedLength,
            event.createdAt,
            event.kind,
            tagsDataPtr,
            tagsLengthsPtr,
            tagsCount,
            contentPtr,
          ) ==
          1;
    } finally {
      malloc.free(packed);
      if (contentPtr != null) malloc.free(contentPtr);
      for (final itemPtr in tagItemPointers) {
        malloc.free(itemPtr);
      }
      if (tagsDataPtr != nullptr) malloc.free(tagsDataPtr);
      if (tagsLengthsPtr != nullptr) malloc.free(tagsLengthsPtr);
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
