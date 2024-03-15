import 'package:dart_ndk/nips/nip01/event.dart';
import 'package:dart_ndk/nips/nip01/event_verifier.dart';

class MockEventVerifier implements EventVerifier {
  @override
  Future<bool> verify(Nip01Event event) async {
    return true;
  }
}
