import 'package:bip340/bip340.dart' as bip340;
import 'package:dart_ndk/nips/nip01/event.dart';
import 'package:dart_ndk/domain_layer/repositories/event_verifier_repository.dart';

class Bip340EventVerifierRepositoryImpl implements EventVerifierRepository {
  @override
  Future<bool> verify(Nip01Event event) async {
    return bip340.verify(event.pubKey, event.id, event.sig);
  }
}