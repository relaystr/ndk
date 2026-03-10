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
    // Check if signature is present
    if (event.sig == null) {
      return false;
    }

    // Convert strings to native pointers
    final eventIdPtr = event.id.toNativeUtf8();
    final pubKeyPtr = event.pubKey.toNativeUtf8();
    final contentPtr = event.content.toNativeUtf8();
    final signaturePtr = event.sig!.toNativeUtf8();

    // Prepare tags data
    final tags = event.tags;
    final tagsCount = tags.length;

    // Calculate total number of strings across all tags
    int totalStrings = 0;
    for (final tag in tags) {
      totalStrings += tag.length;
    }

    // Allocate arrays for tags
    final tagsLengths = calloc<Uint32>(tagsCount == 0 ? 1 : tagsCount);
    final tagsData =
        calloc<Pointer<Utf8>>(totalStrings == 0 ? 1 : totalStrings);

    try {
      // Fill tag data
      int stringIndex = 0;
      for (int i = 0; i < tagsCount; i++) {
        tagsLengths[i] = tags[i].length;
        for (final element in tags[i]) {
          tagsData[stringIndex] = element.toNativeUtf8();
          stringIndex++;
        }
      }

      // Call the native function
      final result = rust_lib.verifyNostrEventNative(
        eventIdPtr,
        pubKeyPtr,
        event.createdAt,
        event.kind,
        tagsData,
        tagsLengths,
        tagsCount,
        contentPtr,
        signaturePtr,
      );

      return result == 1;
    } finally {
      // Free all allocated memory
      calloc.free(eventIdPtr);
      calloc.free(pubKeyPtr);
      calloc.free(contentPtr);
      calloc.free(signaturePtr);

      // Free tag string pointers
      for (int i = 0; i < totalStrings; i++) {
        calloc.free(tagsData[i]);
      }
      calloc.free(tagsData);
      calloc.free(tagsLengths);
    }
  }
}
