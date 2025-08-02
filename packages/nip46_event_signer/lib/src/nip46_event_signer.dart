import 'dart:async';
import 'dart:convert';

import 'package:ndk/ndk.dart';
import 'package:nip01/nip01.dart';
import 'package:nip46_event_signer/src/utils.dart';

class Nip46EventSigner implements EventSigner {
  Ndk ndk;

  String? _cachedPublicKey;
  late Bip340EventSigner localEventSigner;
  String? remotePubkey;
  List<String>? relays;

  NdkResponse? bunkerResponse;
  NdkResponse? nostrConnectResponse;

  String? nostrConnectURL;
  String? bunkerURL;

  Nip46EventSigner(this.ndk) {
    final keyPair = KeyPair.generate();
    localEventSigner = Bip340EventSigner(
      privateKey: keyPair.privateKey,
      publicKey: keyPair.publicKey,
    );
  }

  String getNostrConnectURL({
    required List<String> relays,
    List<String>? perms,
    String? name,
    String? url,
    String? image,
  }) {
    if (nostrConnectURL != null) return nostrConnectURL!;

    final pubkey = localEventSigner.publicKey;

    final secret = generateRandomString();

    final params = <String>[];

    for (final relay in relays) {
      params.add('relay=${Uri.encodeComponent(relay)}');
    }

    params.add('secret=$secret');

    if (perms != null && perms.isNotEmpty) {
      params.add('perms=${perms.join(',')}');
    }

    if (name != null) {
      params.add('name=${Uri.encodeComponent(name)}');
    }

    if (url != null) {
      params.add('url=${Uri.encodeComponent(url)}');
    }

    if (image != null) {
      params.add('image=${Uri.encodeComponent(image)}');
    }

    nostrConnectURL = 'nostrconnect://$pubkey?${params.join('&')}';

    listenNostrConnect(relays: relays);

    return nostrConnectURL!;
  }

  Future<void> bunkerConnect(String url) async {
    bunkerURL = url;

    final uri = Uri.parse(url);
    if (uri.scheme != 'bunker') {
      throw ArgumentError('Invalid bunker URL scheme');
    }

    final remotePubkey = uri.host;
    final relays = uri.queryParametersAll['relay'] ?? [];
    final secret = uri.queryParameters['secret'];

    if (relays.isEmpty) {
      throw ArgumentError('At least one relay is required in bunker URL');
    }

    if (secret == null) {
      throw ArgumentError('Secret parameter is required in bunker URL');
    }

    listenBunker(relays: relays);

    final request = {
      "id": generateRandomString(),
      "method": "connect",
      "params": [remotePubkey, secret],
    };

    await remoteRequest(
      relays: relays,
      remotePubkey: remotePubkey,
      request: request,
      subscription: bunkerResponse!,
    );
  }

  Future<void> listenNostrConnect({required List<String> relays}) async {
    if (nostrConnectResponse != null) return;

    nostrConnectResponse = ndk.requests.subscription(
      explicitRelays: relays,
      filters: [
        Filter(
          kinds: [24133],
          pTags: [localEventSigner.publicKey],
          since: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ),
      ],
    );

    await for (final event in nostrConnectResponse!.stream) {
      final decryptedContent = await localEventSigner.decryptNip44(
        ciphertext: event.content,
        senderPubKey: event.pubKey,
      );

      final response = jsonDecode(decryptedContent!);

      if (response["method"] != "connect") continue;
      
      remotePubkey = event.pubKey;
      // TODO emit event
      break;
    }
  }

  Future<void> listenBunker({required List<String> relays}) async {
    if (bunkerResponse != null) return;

    bunkerResponse = ndk.requests.subscription(
      explicitRelays: relays,
      filters: [
        Filter(
          kinds: [24133],
          pTags: [localEventSigner.publicKey],
          since: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ),
      ],
    );
  }

  Future<String> remoteRequest({
    required String remotePubkey,
    required List<String> relays,
    required Map<String, dynamic> request,
    required NdkResponse subscription,
    Duration timeout = const Duration(seconds: 30),
  }) async {
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

    ndk.broadcast.broadcast(nostrEvent: requestEvent, specificRelays: relays);

    final completer = Completer<String>();
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.completeError(
          TimeoutException(
            'Remote request timed out after ${timeout.inSeconds} seconds',
          ),
        );
      }
    });

    final streamSubscription = subscription.stream.listen((event) async {
      try {
        final decryptedContent = await localEventSigner.decryptNip44(
          ciphertext: event.content,
          senderPubKey: remotePubkey,
        );

        final response = jsonDecode(decryptedContent!);

        if (response["id"] != request["id"]) return;

        timer.cancel();

        if (response["error"] != null) {
          completer.completeError(Exception(response["error"]));
        } else {
          completer.complete(response["result"]);
        }
      } catch (e) {
        timer.cancel();
        completer.completeError(e);
      }
    });

    try {
      return await completer.future;
    } finally {
      timer.cancel();
      await streamSubscription.cancel();
    }
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
    if (remotePubkey == null) {
      throw StateError('No bunker connected');
    }

    final request = {
      "id": generateRandomString(),
      "method": "get_public_key",
      "params": [],
    };

    final publicKey = await remoteRequest(
      relays: relays!,
      remotePubkey: remotePubkey!,
      request: request,
      subscription: bunkerResponse!,
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
