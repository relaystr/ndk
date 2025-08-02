import 'dart:async';
import 'dart:convert';

import 'package:ndk/ndk.dart';
import 'package:nip01/nip01.dart';
import 'package:nip46_event_signer/src/models/connection_settings.dart';
import 'package:nip46_event_signer/src/utils.dart';

class Nip46EventSigner implements EventSigner {
  Ndk ndk;

  String? _cachedPublicKey;

  late String remotePubkey;
  late List<String> relays;
  late Bip340EventSigner localEventSigner;

  late NdkResponse subscription;

  Nip46EventSigner({required this.ndk, required ConnectionSettings settings}) {
    final keyPair = KeyPair.fromPrivateKey(privateKey: settings.privateKey);
    localEventSigner = Bip340EventSigner(
      privateKey: keyPair.privateKey,
      publicKey: keyPair.publicKey,
    );

    remotePubkey = settings.remotePubkey;
    relays = settings.relays;

    listenBunker();
  }

  final oneMinuteAgo =
      (DateTime.now().millisecondsSinceEpoch ~/ 1000) -
      Duration(hours: 1).inSeconds;
  Future<void> listenBunker() async {
    subscription = ndk.requests.subscription(
      explicitRelays: relays,
      filters: [
        Filter(
          kinds: [24133],
          pTags: [localEventSigner.publicKey],
          since: oneMinuteAgo,
        ),
      ],
    );
  }

  Future<String> remoteRequest({
    required String remotePubkey,
    required List<String> relays,
    required Map<String, dynamic> request,
  }) async {
    print(request["id"]);

    final encryptedRequest = await localEventSigner.encryptNip44(
      plaintext: jsonEncode(request),
      recipientPubKey: remotePubkey,
    );

    final requestEvent = Nip01Event(
      pubKey: localEventSigner.publicKey,
      kind: 24133,
      tags: [
        ["p", remotePubkey],
      ],
      content: encryptedRequest!,
    );

    await localEventSigner.sign(requestEvent);
    ndk.broadcast.broadcast(nostrEvent: requestEvent, specificRelays: relays);

    await for (final event in subscription.stream) {
      final decryptedContent = await localEventSigner.decryptNip44(
        ciphertext: event.content,
        senderPubKey: remotePubkey,
      );

      final response = jsonDecode(decryptedContent!);

      print('${DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000)}: $response');

      if (response["result"] == "auth_url") {
        // print(response["error"]);
      }

      if (response["id"] != request["id"]) continue;

      // return response["result"];
    }

    throw Exception('No response received');
  }

  @override
  bool canSign() {
    // TODO: implement canSign
    throw UnimplementedError();
  }

  @override
  Future<String?> decrypt(String msg, String destPubKey, {String? id}) {
    // TODO: implement decrypt
    throw UnimplementedError();
  }

  @override
  Future<String?> decryptNip44({
    required String ciphertext,
    required String senderPubKey,
  }) {
    // TODO: implement decryptNip44
    throw UnimplementedError();
  }

  @override
  Future<String?> encrypt(String msg, String destPubKey, {String? id}) {
    // TODO: implement encrypt
    throw UnimplementedError();
  }

  @override
  Future<String?> encryptNip44({
    required String plaintext,
    required String recipientPubKey,
  }) {
    // TODO: implement encryptNip44
    throw UnimplementedError();
  }

  @override
  String getPublicKey() {
    if (_cachedPublicKey != null) return _cachedPublicKey!;
    throw Exception('Use getPublicKeyAsync() first to cache the user pubkey');
  }

  Future<String> getPublicKeyAsync() async {
    final request = {
      "id": generateRandomString(),
      "method": "get_public_key",
      "params": [],
    };

    final publicKey = await remoteRequest(
      relays: relays,
      remotePubkey: remotePubkey,
      request: request,
    );

    _cachedPublicKey = publicKey;

    return publicKey;
  }

  @override
  Future<void> sign(Nip01Event event) {
    // TODO: implement sign
    throw UnimplementedError();
  }
}
