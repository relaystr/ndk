import 'package:dart_ndk/nips/nip01/event.dart';
import 'package:dart_ndk/nips/nip01/helpers.dart';

import 'bip340.dart';
import 'event_signer.dart';

class Bip340EventSigner implements EventSigner {

  String? privateKey;
  String publicKey;

  Bip340EventSigner(this.privateKey, this.publicKey);

  @override
  Future<void> sign(Nip01Event event) async {
    if (Helpers.isNotBlank(privateKey)) {
      event.sig = Bip340.sign(event.id, privateKey!);
    }
  }

  @override
  String getPublicKey() {
    return publicKey;
  }

  @override
  Future<void> decrypt(String msg) {
    // TODO: implement decrypt
    throw UnimplementedError();
  }

  @override
  bool canSign() {
    return Helpers.isNotBlank(privateKey);
  }

  @override
  String? getPrivateKey() {
    return privateKey;
  }
}