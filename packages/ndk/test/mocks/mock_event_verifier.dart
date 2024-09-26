import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/domain_layer/repositories/event_verifier.dart';

/// A mock implementation of [EventVerifier] for testing purposes.
///
/// This class allows for simulating event verification results without
/// performing actual cryptographic operations. It's useful for testing
/// and development scenarios where consistent, predictable verification
/// results are needed.
class MockEventVerifier implements EventVerifier {
  /// The result that will be returned by the [verify] method.
  bool _result = true;

  /// Creates a new instance of [MockEventVerifier].
  ///
  /// [result] Optional parameter to set the verification result.
  /// If set to false, [verify] will always return false. Defaults to true.
  MockEventVerifier({bool result = true}) {
    _result = result;
  }

  /// Simulates the verification of a Nostr event
  ///
  /// This method always returns the value set in the constructor,
  /// regardless of the event's actual content
  @override
  Future<bool> verify(Nip01Event event) async {
    return _result;
  }
}
