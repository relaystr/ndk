import 'package:dart_ndk/domain_layer/entities/nip_01_event.dart';
import 'package:dart_ndk/domain_layer/repositories/event_verifier_repository.dart';

class MockEventVerifier implements EventVerifierRepository {
  bool _result = true;

  /// If [result] is false, [verify] will always return false. Default is true.
  MockEventVerifier({bool result = true}) {
    _result = result;
  }

  @override
  Future<bool> verify(Nip01Event event) async {
    return _result;
  }
}
