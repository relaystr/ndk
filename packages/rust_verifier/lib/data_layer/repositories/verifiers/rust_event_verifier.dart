import 'package:ndk/ndk.dart';

import '../../../rust_bridge/api/event_verifier.dart';
import '../rust_lib_initializer.dart';

/// An implementation of [EventVerifier] that uses Rust for event verification.
///
/// This class provides a bridge between Dart and Rust, allowing for efficient
/// verification of Nostr events using Rust's performance capabilities.
/// The rust code runs in a separate isolate further increasing the the smoothness of the main thread.
class RustEventVerifier implements EventVerifier {
  final RustLibInitializer _initializer = RustLibInitializer();

  /// Creates a new instance of [RustEventVerifier]
  RustEventVerifier();

  /// Verifies a Nostr event using the Rust implementation.
  ///
  /// This method waits for the Rust library to be initialized before
  /// performing the verification.
  ///
  /// [event] The [Nip01Event] to be verified.
  ///
  /// Returns a [Future<bool>] that resolves to true if the event is valid,
  /// false otherwise.

  @override
  Future<bool> verify(Nip01Event event) async {
    await _initializer.ensureInitialized();
    if (event.sig == null) {
      return false;
    }

    return verifyNostrEvent(
      eventIdHex: event.id,
      pubKeyHex: event.pubKey,
      createdAt: BigInt.from(event.createdAt),
      kind: event.kind,
      tags: event.tags,
      content: event.content,
      signatureHex: event.sig!,
    );
  }
}
