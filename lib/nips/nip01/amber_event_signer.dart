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
    Map<dynamic, dynamic> map = await amber.signEvent(npub: publicKey, event: jsonEncode(event.toJson()));
    if (map!=null) {
      event.sig = map['signature'];
    }
  }

  @override
  String getPublicKey() {
    return publicKey;
  }

  @override
  Future<String?> decrypt(String msg, String destPubKey) async {
    Map<dynamic, dynamic> map = await amber.nip04Decrypt( ciphertext: msg, npub: publicKey, pubkey: destPubKey);
    return map['signature'];
  }

  @override
  Future<String?> encrypt(String msg, String destPubKey) async {
    Map<dynamic, dynamic> map = await amber.nip04Encrypt( plaintext: msg, npub: publicKey, pubkey: destPubKey);
    return map['signature'];
  }

  @override
  bool canSign() {
    return publicKey.isNotEmpty;
  }
}