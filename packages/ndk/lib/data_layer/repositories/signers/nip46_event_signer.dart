import 'dart:async';
import 'dart:convert';

import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:rxdart/rxdart.dart';

import '../../../domain_layer/usecases/bunkers/models/bunker_request.dart';

/// Internal class to track a pending request with its completer and metadata
class _PendingRequestEntry {
  final Completer<String> completer;
  final PendingSignerRequest request;
  _PendingRequestEntry(this.completer, this.request);
}

class Nip46EventSigner implements EventSigner {
  BunkerConnection connection;
  Requests requests;
  Broadcast broadcast;
  Function(String)? authCallback;

  NdkResponse? subscription;

  final _pendingRequests = <String, _PendingRequestEntry>{};
  final _pendingRequestsController =
      BehaviorSubject<List<PendingSignerRequest>>.seeded([]);

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

    listenRelays();
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
      final entry = _pendingRequests.remove(response["id"])!;
      _notifyPendingRequestsChange();

      if (response["error"] != null && response["result"] != "auth_url") {
        entry.completer.completeError(SignerRequestRejectedException(
          requestId: response["id"],
          originalMessage: response["error"],
        ));
      } else {
        entry.completer.complete(response["result"]);
      }
    }
  }

  void _notifyPendingRequestsChange() {
    _pendingRequestsController
        .add(_pendingRequests.values.map((e) => e.request).toList());
  }

  Future<String> remoteRequest({
    required BunkerRequest request,
    Nip01Event? event,
    String? plaintext,
    String? ciphertext,
    String? counterpartyPubkey,
  }) async {
    final completer = Completer<String>();
    final pendingRequest = PendingSignerRequest(
      id: request.id,
      method: request.method,
      createdAt: DateTime.now(),
      signerPubkey: cachedPublicKey ?? '',
      event: event,
      plaintext: plaintext,
      ciphertext: ciphertext,
      counterpartyPubkey: counterpartyPubkey,
    );
    _pendingRequests[request.id] = _PendingRequestEntry(
      completer,
      pendingRequest,
    );
    _notifyPendingRequestsChange();

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
      method: SignerMethod.nip04Decrypt,
      params: [destPubKey, msg],
    );

    final decryptedText = await remoteRequest(
      request: request,
      ciphertext: msg,
      counterpartyPubkey: destPubKey,
    );
    return decryptedText;
  }

  @override
  Future<String?> decryptNip44({
    required String ciphertext,
    required String senderPubKey,
  }) async {
    final request = BunkerRequest(
      method: SignerMethod.nip44Decrypt,
      params: [senderPubKey, ciphertext],
    );

    final decryptedText = await remoteRequest(
      request: request,
      ciphertext: ciphertext,
      counterpartyPubkey: senderPubKey,
    );
    return decryptedText;
  }

  @override
  Future<String?> encrypt(String msg, String destPubKey, {String? id}) async {
    final request = BunkerRequest(
      method: SignerMethod.nip04Encrypt,
      params: [destPubKey, msg],
    );

    final encryptedText = await remoteRequest(
      request: request,
      plaintext: msg,
      counterpartyPubkey: destPubKey,
    );
    return encryptedText;
  }

  @override
  Future<String?> encryptNip44({
    required String plaintext,
    required String recipientPubKey,
  }) async {
    final request = BunkerRequest(
      method: SignerMethod.nip44Encrypt,
      params: [recipientPubKey, plaintext],
    );

    final encryptedText = await remoteRequest(
      request: request,
      plaintext: plaintext,
      counterpartyPubkey: recipientPubKey,
    );
    return encryptedText;
  }

  @override
  String getPublicKey() {
    if (cachedPublicKey != null) return cachedPublicKey!;
    throw Exception('Use getPublicKeyAsync() first to cache the user pubkey');
  }

  Future<String> getPublicKeyAsync() async {
    final request = BunkerRequest(method: SignerMethod.getPublicKey);

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
      method: SignerMethod.signEvent,
      params: [jsonEncode(eventMap)],
    );

    final signedEventJson = await remoteRequest(
      request: request,
      event: event,
    );
    final signedEvent = jsonDecode(signedEventJson);

    return event.copyWith(id: signedEvent["id"], sig: signedEvent["sig"]);
  }

  Future<String> ping() async {
    final request = BunkerRequest(method: SignerMethod.ping);

    final response = await remoteRequest(request: request);
    return response;
  }

  @override
  Stream<List<PendingSignerRequest>> get pendingRequestsStream =>
      _pendingRequestsController.stream;

  @override
  List<PendingSignerRequest> get pendingRequests =>
      _pendingRequests.values.map((e) => e.request).toList();

  @override
  bool cancelRequest(String requestId) {
    final entry = _pendingRequests.remove(requestId);
    if (entry != null) {
      entry.completer.completeError(SignerRequestCancelledException(requestId));
      _notifyPendingRequestsChange();
      return true;
    }
    return false;
  }

  @override
  Future<void> dispose() async {
    if (subscription != null) {
      await requests.closeSubscription(subscription!.requestId);
    }
    await _pendingRequestsController.close();
  }
}
