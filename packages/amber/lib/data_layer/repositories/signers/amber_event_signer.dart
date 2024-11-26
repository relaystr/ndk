import 'dart:convert';

import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip19/nip19.dart';

import '../../data_sources/amber_flutter.dart';

/// amber (external app) https://github.com/greenart7c3/Amber singer
class AmberEventSigner implements EventSigner {
  final AmberFlutterDS amberFlutterDS;

  final String publicKey;

  /// get a amber event signer
  AmberEventSigner({
    required this.publicKey,
    required this.amberFlutterDS,
  });

  @override
  Future<void> sign(Nip01Event event) async {
    final npub = publicKey.startsWith('npub')
        ? publicKey
        : Nip19.encodePubKey(publicKey);
    Map<dynamic, dynamic> map = await amberFlutterDS.amber.signEvent(
        currentUser: npub, eventJson: jsonEncode(event.toJson()), id: event.id);
    event.sig = map['signature'];
  }

  @override
  String getPublicKey() {
    return publicKey;
  }

  @override
  Future<String?> decrypt(String msg, String destPubKey, {String? id}) async {
    final npub = publicKey.startsWith('npub')
        ? publicKey
        : Nip19.encodePubKey(publicKey);
    Map<dynamic, dynamic> map = await amberFlutterDS.amber.nip04Decrypt(
        ciphertext: msg, currentUser: npub, pubKey: destPubKey, id: id);
    return map['signature'];
  }

  @override
  Future<String?> encrypt(String msg, String destPubKey, {String? id}) async {
    final npub = publicKey.startsWith('npub')
        ? publicKey
        : Nip19.encodePubKey(publicKey);
    Map<dynamic, dynamic> map = await amberFlutterDS.amber.nip04Encrypt(
        plaintext: msg, currentUser: npub, pubKey: destPubKey, id: id);
    return map['signature'];
  }

  @override
  bool canSign() {
    return publicKey.isNotEmpty;
  }
}
