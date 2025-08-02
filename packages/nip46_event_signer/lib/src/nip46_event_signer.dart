import 'dart:async';
import 'dart:convert';

import 'package:ndk/ndk.dart';
import 'package:nip01/nip01.dart';
import 'package:nip46_event_signer/nip46_event_signer.dart';
import 'package:nip46_event_signer/src/utils.dart';

class Nip46EventSigner implements EventSigner {
  final _streamController = StreamController<dynamic>.broadcast();
  Stream<dynamic> get stream => _streamController.stream;

  ConnectionSettings connectionSettings;

  Ndk? ndk;
  NdkResponse? subscription;

  final _pendingRequests = <String, Completer<dynamic>>{};

  String? _cachedPublicKey;

  late Bip340EventSigner localEventSigner;

  Nip46EventSigner({required this.connectionSettings}) {
    final keyPair = KeyPair.fromPrivateKey(
      privateKey: connectionSettings.privateKey,
    );

    localEventSigner = Bip340EventSigner(
      privateKey: keyPair.privateKey,
      publicKey: keyPair.publicKey,
    );

    ndk = Ndk(
      NdkConfig(
        eventVerifier: Bip340EventVerifier(),
        cache: MemCacheManager(),
        bootstrapRelays: connectionSettings.relays,
      ),
    );

    ndk!.accounts.loginExternalSigner(signer: localEventSigner);

    listenRelays();
  }

  Future<void> listenRelays() async {
    subscription = ndk!.requests.subscription(
      filters: [
        Filter(
          authors: [connectionSettings.remotePubkey],
          kinds: [24133],
          pTags: [localEventSigner.publicKey],
          since: someTimeAgo(),
        ),
      ],
    );

    subscription!.stream.listen(onEvent);
  }

  Future<void> onEvent(Nip01Event event) async {
    final decryptedContent = await localEventSigner.decryptNip44(
      ciphertext: event.content,
      senderPubKey: event.pubKey,
    );

    final response = jsonDecode(decryptedContent!);

    print(response);

    if (response["result"] == "auth_url") {
      _streamController.add(AuthRequired(response["error"]));
      return;
    }

    if (_pendingRequests[response["id"]] != null) {
      final completer = _pendingRequests.remove(response["id"])!;

      if (response["error"] != null && response["result"] != "auth_url") {
        completer.completeError(Exception(response["error"]));
      } else {
        completer.complete(response["result"]);
      }
    }
  }

  Future<String> remoteRequest({required Map<String, dynamic> request}) async {
    print(request);

    final completer = Completer<String>();
    _pendingRequests[request["id"]] = completer;

    final encryptedRequest = await localEventSigner.encryptNip44(
      plaintext: jsonEncode(request),
      recipientPubKey: connectionSettings.remotePubkey,
    );

    final requestEvent = Nip01Event(
      pubKey: localEventSigner.publicKey,
      kind: 24133,
      tags: [
        ["p", connectionSettings.remotePubkey],
      ],
      content: encryptedRequest!,
    );

    await localEventSigner.sign(requestEvent);
    ndk!.broadcast.broadcast(
      nostrEvent: requestEvent,
      specificRelays: connectionSettings.relays,
    );

    return completer.future;
  }

  @override
  bool canSign() {
    return true;
  }

  @override
  Future<String?> decrypt(String msg, String destPubKey, {String? id}) async {
    final request = {
      "id": id ?? generateRandomString(),
      "method": "nip04_decrypt",
      "params": [destPubKey, msg],
    };

    final decryptedText = await remoteRequest(request: request);
    return decryptedText;
  }

  @override
  Future<String?> decryptNip44({
    required String ciphertext,
    required String senderPubKey,
  }) async {
    final request = {
      "id": generateRandomString(),
      "method": "nip44_decrypt",
      "params": [senderPubKey, ciphertext],
    };

    final decryptedText = await remoteRequest(request: request);
    return decryptedText;
  }

  @override
  Future<String?> encrypt(String msg, String destPubKey, {String? id}) async {
    final request = {
      "id": id ?? generateRandomString(),
      "method": "nip04_encrypt",
      "params": [destPubKey, msg],
    };

    final encryptedText = await remoteRequest(request: request);
    return encryptedText;
  }

  @override
  Future<String?> encryptNip44({
    required String plaintext,
    required String recipientPubKey,
  }) async {
    final request = {
      "id": generateRandomString(),
      "method": "nip44_encrypt",
      "params": [recipientPubKey, plaintext],
    };

    final encryptedText = await remoteRequest(request: request);
    return encryptedText;
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

    final publicKey = await remoteRequest(request: request);

    _cachedPublicKey = publicKey;

    return publicKey;
  }

  @override
  Future<void> sign(Nip01Event event) async {
    final eventMap = {
      "kind": event.kind,
      "content": event.content,
      "tags": event.tags,
      "created_at": event.createdAt,
    };

    final request = {
      "id": generateRandomString(),
      "method": "sign_event",
      "params": [jsonEncode(eventMap)],
    };

    final signedEventJson = await remoteRequest(request: request);
    final signedEvent = jsonDecode(signedEventJson);

    event.id = signedEvent["id"];
    event.sig = signedEvent["sig"];
  }

  Future<String> ping() async {
    final request = {
      "id": generateRandomString(),
      "method": "ping",
      "params": [],
    };

    final response = await remoteRequest(request: request);
    return response;
  }

  void closeSubscription() async {
    if (subscription == null) return;
    await ndk!.requests.closeSubscription(subscription!.requestId);
  }

  void dispose() {
    _streamController.close();
    if (ndk == null) return;
    closeSubscription();
    ndk!.destroy();
  }
}
