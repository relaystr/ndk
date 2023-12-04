import 'dart:convert';

import 'package:amberflutter/amberflutter.dart';
import 'package:dart_ndk/nips/nip01/event.dart';

import 'event_signer.dart';

class AmberEventSigner implements EventSigner {
  final amber = Amberflutter();

  final String publicKey;

  AmberEventSigner(this.publicKey);

  @override
  Future<void> sign(Nip01Event event) async {
    String? signedEvent = await amber.signEvent(publicKey, jsonEncode(event.toJson()));
    if (signedEvent!=null) {
      Nip01Event signed = Nip01Event.fromJson(jsonDecode(signedEvent));
      event.sig = signed.sig;
    }
  }

  @override
  String getPublicKey() {
    return publicKey;
  }

  @override
  Future<String?> decrypt(String msg, String destPubKey) async {
    return await amber.nip04Decrypt(msg, publicKey, destPubKey);
  }

  @override
  Future<String?> encrypt(String msg, String destPubKey) async {
    return await amber.nip04Encrypt(msg, publicKey, destPubKey);
  }


  @override
  bool canSign() {
    return publicKey.isNotEmpty;
  }

  @override
  String? getPrivateKey() {
    throw UnimplementedError();
  }
}