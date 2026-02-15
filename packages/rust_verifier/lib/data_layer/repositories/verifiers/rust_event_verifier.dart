import 'dart:async';

import 'package:ndk/ndk.dart';

import '../../../rust_bridge/api/event_verifier.dart';
import '../../../rust_bridge/frb_generated.dart';

/// An implementation of [EventVerifier] that uses Rust for event verification.
///
/// This class provides a bridge between Dart and Rust, allowing for efficient
/// verification of Nostr events using Rust's performance capabilities.
/// The rust code runs in a separate isolate further increasing the the smoothness of the main thread.
class RustEventVerifier implements EventVerifier {
  /// A future that tracks the initialization status of the Rust library (shared across all instances)
  static Future<void>? _initFuture;

  /// Creates a new instance of [RustEventVerifier] and initializes the Rust library
  RustEventVerifier() {
    _initFuture ??= _init();
  }

  /// Initializes the Rust library.
  ///
  /// This method is called in the constructor and sets up the Rust environment
  /// for event verification.
  ///
  /// Returns a [Future] that completes when initialization is done.
  static Future<void> _init() async {
    await RustLib.init();
  }

  /// Waits for the Rust library to be fully initialized.
  ///
  /// Call this method before benchmarking to ensure initialization overhead
  /// is not included in performance measurements.
  Future<void> ensureInitialized() async {
    await _initFuture;
  }

  /// Verifies a Nostr event using the Rust implementation.
  ///
  /// Pleases ensure that the Rust library is initialized before calling this method!
  /// You can call [ensureInitialized] to wait for initialization to complete.
  ///
  /// [event] The [Nip01Event] to be verified.
  ///
  /// Returns a [Future<bool>] that resolves to true if the event is valid,
  /// false otherwise.

  @override
  Future<bool> verify(Nip01Event event) async {
    if (event.sig == null) {
      return false;
    }

    final result = await verifyNostrEvent(
      eventIdHex: event.id,
      pubKeyHex: event.pubKey,
      createdAt: BigInt.from(event.createdAt),
      kind: event.kind,
      tags: event.tags,
      content: event.content,
      signatureHex: event.sig!,
    );

    return result;
  }
}
