import 'package:dart_ndk/nips/nip01/event.dart';

import 'bip340.dart';
import 'event_signer.dart';

class Bip340EventSigner implements EventSigner {

  String privateKey;

  Bip340EventSigner(this.privateKey);

  @override
  Future<void> sign(Nip01Event event) async {
    event.sig = Bip340.sign(event.id, privateKey);
  }
}