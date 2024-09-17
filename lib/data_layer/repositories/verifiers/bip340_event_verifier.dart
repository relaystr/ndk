import 'package:bip340/bip340.dart' as bip340;

import '../../../domain_layer/entities/nip_01_event.dart';
import '../../../domain_layer/repositories/event_verifier.dart';

class Bip340EventVerifier implements EventVerifier {
  bool doVerification;

  Bip340EventVerifier({this.doVerification = true});

  @override
  Future<bool> verify(Nip01Event event) async {
    return !doVerification || bip340.verify(event.pubKey, event.id, event.sig);
  }
}
