import 'dart:async';
import 'dart:convert';

import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import '../../../domain_layer/usecases/bunkers/models/bunker_request.dart';

class Nip46EventSigner implements EventSigner {
  BunkerConnection connection;
  Requests requests;
  Broadcast broadcast;
  Function(String)? authCallback;

  NdkResponse? subscription;

  final _pendingRequests = <String, Completer<dynamic>>{};

  late Future<void> _listenFuture;

  String? cachedPublicKey;

  late Bip340EventSigner localEventSigner;

  Nip46EventSigner({
    required this.connection,
    required this.requests,
    required this.broadcast,
    this.authCallback,
    this.cachedPublicKey,
  }) {
    final privKey = connection.privateKey;
    final pubKey = Bip340.getPublicKey(privKey);

    final privKeyHr = Helpers.encodeBech32(privKey, 'nsec');
    final pubKeyHr = Helpers.encodeBech32(pubKey, 'npub');

    final keyPair = KeyPair(privKey, pubKey, privKeyHr, pubKeyHr);

    localEventSigner = Bip340EventSigner(
      privateKey: keyPair.privateKey,
      publicKey: keyPair.publicKey,
    );

    _listenFuture = listenRelays();
  }

  Future<void> listenRelays() async {
    subscription = requests.subscription(
      explicitRelays: connection.relays,
      filter: Filter(
        authors: [connection.remotePubkey],
        kinds: [BunkerRequest.kKind],
        pTags: [localEventSigner.publicKey],
      ),
    );

    subscription!.stream.listen(onEvent);
  }

  Future<void> onEvent(Nip01Event event) async {
    final decryptedContent = await localEventSigner.decryptNip44(
      ciphertext: event.content,
      senderPubKey: event.pubKey,
    );

    final response = jsonDecode(decryptedContent!);

    if (response["result"] == "auth_url") {
      if (authCallback != null) {
        authCallback!(response["error"]);
      }
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

  Future<String> remoteRequest({required BunkerRequest request}) async {
    await _listenFuture;

    final completer = Completer<String>();
    _pendingRequests[request.id] = completer;

    final encryptedRequest = await localEventSigner.encryptNip44(
      plaintext: jsonEncode(request),
      recipientPubKey: connection.remotePubkey,
    );

    final requestEvent = Nip01Event(
      createdAt: 0,
      pubKey: localEventSigner.publicKey,
      kind: BunkerRequest.kKind,
      tags: [
        ["p", connection.remotePubkey],
      ],
      content: encryptedRequest!,
    );

    final signedEvent = await localEventSigner.sign(requestEvent);
    final broadcastRes = broadcast.broadcast(
      nostrEvent: signedEvent,
      specificRelays: connection.relays,
    );
    await broadcastRes.broadcastDoneFuture;

    return completer.future;
  }

  @override
  bool canSign() {
    return true;
  }

  @override
  Future<String?> decrypt(String msg, String destPubKey, {String? id}) async {
    final request = BunkerRequest(
      method: BunkerRequestMethods.nip04Decrypt,
      params: [destPubKey, msg],
    );

    final decryptedText = await remoteRequest(request: request);
    return decryptedText;
  }

  @override
  Future<String?> decryptNip44({
    required String ciphertext,
    required String senderPubKey,
  }) async {
    final request = BunkerRequest(
      method: BunkerRequestMethods.nip44Decrypt,
      params: [senderPubKey, ciphertext],
    );

    final decryptedText = await remoteRequest(request: request);
    return decryptedText;
  }

  @override
  Future<String?> encrypt(String msg, String destPubKey, {String? id}) async {
    final request = BunkerRequest(
      method: BunkerRequestMethods.nip04Encrypt,
      params: [destPubKey, msg],
    );

    final encryptedText = await remoteRequest(request: request);
    return encryptedText;
  }

  @override
  Future<String?> encryptNip44({
    required String plaintext,
    required String recipientPubKey,
  }) async {
    final request = BunkerRequest(
      method: BunkerRequestMethods.nip44Encrypt,
      params: [recipientPubKey, plaintext],
    );

    final encryptedText = await remoteRequest(request: request);
    return encryptedText;
  }

  @override
  String getPublicKey() {
    if (cachedPublicKey != null) return cachedPublicKey!;
    throw Exception('Use getPublicKeyAsync() first to cache the user pubkey');
  }

  Future<String> getPublicKeyAsync() async {
    final request = BunkerRequest(method: BunkerRequestMethods.getPublicKey);

    final publicKey = await remoteRequest(request: request);

    cachedPublicKey = publicKey;

    return publicKey;
  }

  @override
  Future<Nip01Event> sign(Nip01Event event) async {
    final eventMap = {
      "kind": event.kind,
      "content": event.content,
      "tags": event.tags,
      "created_at": event.createdAt,
    };

    final request = BunkerRequest(
      method: BunkerRequestMethods.signEvent,
      params: [jsonEncode(eventMap)],
    );

    final signedEventJson = await remoteRequest(request: request);
    final signedEvent = jsonDecode(signedEventJson);

    return event.copyWith(id: signedEvent["id"], sig: signedEvent["sig"]);
  }

  Future<String> ping() async {
    final request = BunkerRequest(method: BunkerRequestMethods.ping);

    final response = await remoteRequest(request: request);
    return response;
  }

  void dispose() async {
    if (subscription == null) return;
    await requests.closeSubscription(subscription!.requestId);
  }
}
