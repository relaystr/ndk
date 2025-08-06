import 'dart:async';
import 'dart:convert';

import '../../../data_layer/repositories/signers/bip340_event_signer.dart';
import 'models/bunker_event.dart';
import 'models/bunker_request.dart';
import 'models/bunker_connection.dart';
import '../../../shared/nips/nip01/bip340.dart';
import '../../entities/filter.dart';
import '../../entities/nip_01_event.dart';
import '../../repositories/event_signer.dart';
import '../broadcast/broadcast.dart';
import '../requests/requests.dart';

/// Bunkers usecase that handles NIP-46 remote signing protocol operations
class Bunkers {
  final Broadcast _broadcast;
  final Requests _requests;

  Bunkers({
    required Broadcast broadcast,
    required Requests requests,
  })  : _broadcast = broadcast,
        _requests = requests;

  /// Connects to a bunker using a bunker URL (bunker://)
  Stream<BunkerEvent> connectWithBunkerUrl(String bunkerUrl) async* {
    final uri = Uri.parse(bunkerUrl);
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

    final keyPair = Bip340.generatePrivateKey();
    final localEventSigner = Bip340EventSigner(
      privateKey: keyPair.privateKey,
      publicKey: keyPair.publicKey,
    );

    final request = BunkerRequest(
      method: BunkerRequestMethods.connect,
      params: [remotePubkey, secret],
    );

    final encryptedRequest = await localEventSigner.encryptNip44(
      plaintext: jsonEncode(request),
      recipientPubKey: remotePubkey,
    );

    final requestEvent = Nip01Event(
      pubKey: localEventSigner.publicKey,
      kind: BunkerRequest.kKind,
      tags: [
        ["p", remotePubkey],
      ],
      content: encryptedRequest!,
    );

    await localEventSigner.sign(requestEvent);
    _broadcast.broadcast(nostrEvent: requestEvent, specificRelays: relays);

    final subscription = _requests.subscription(
      explicitRelays: relays,
      filters: [
        Filter(
          authors: [remotePubkey],
          kinds: [BunkerRequest.kKind],
          pTags: [localEventSigner.publicKey],
          since: someTimeAgo(),
        ),
      ],
    );

    await for (final event in subscription.stream) {
      final decryptedContent = await localEventSigner.decryptNip44(
        ciphertext: event.content,
        senderPubKey: remotePubkey,
      );

      final response = jsonDecode(decryptedContent!);

      if (response["id"] != request.id) continue;

      if (response["result"] == "auth_url") {
        yield AuthRequired(response["error"]);
        continue;
      }

      if (response["result"] == "ack") {
        yield Connected(
          BunkerConnection(
            privateKey: localEventSigner.privateKey!,
            remotePubkey: remotePubkey,
            relays: relays,
          ),
        );
        await _requests.closeSubscription(subscription.requestId);
        break;
      }
    }
  }

  /// Creates a nostr connect URL and listens for connections
  // Stream<BunkerEvent> createNostrConnectSession({
  //   required List<String> relays,
  //   List<String>? perms,
  //   String? appName,
  //   String? appUrl,
  //   String? appImageUrl,
  // }) async* {
  //   if (relays.isEmpty) {
  //     throw ArgumentError("At least one relay is required");
  //   }
  //
  //   final keyPair = Bip340.generatePrivateKey();
  //   final secret = Helpers.getSecureRandomString(16);
  //
  //   final localEventSigner = Bip340EventSigner(
  //     privateKey: keyPair.privateKey,
  //     publicKey: keyPair.publicKey,
  //   );
  //
  //   final subscription = _requests.subscription(
  //     explicitRelays: relays,
  //     filters: [
  //       Filter(
  //         kinds: [BunkerRequest.kKind],
  //         pTags: [localEventSigner.publicKey],
  //         since: someTimeAgo(),
  //       ),
  //     ],
  //   );
  //
  //   // Yield the nostr connect URL as the first event
  //   final nostrConnectURL = _generateNostrConnectURL(
  //     publicKey: localEventSigner.publicKey,
  //     relays: relays,
  //     secret: secret,
  //     perms: perms,
  //     appName: appName,
  //     appUrl: appUrl,
  //     appImageUrl: appImageUrl,
  //   );
  //
  //   yield NostrConnectURLGenerated(nostrConnectURL);
  //
  //   await for (final event in subscription.stream) {
  //     final decryptedContent = await localEventSigner.decryptNip44(
  //       ciphertext: event.content,
  //       senderPubKey: event.pubKey,
  //     );
  //
  //     final response = jsonDecode(decryptedContent!);
  //
  //     if (response["result"] == "auth_url") {
  //       yield AuthRequired(response["error"]);
  //       continue;
  //     }
  //
  //     if (response["result"] == secret) {
  //       yield Connected(
  //         ConnectionSettings(
  //           privateKey: localEventSigner.privateKey!,
  //           remotePubkey: event.pubKey,
  //           relays: relays,
  //         ),
  //       );
  //       await _requests.closeSubscription(subscription.requestId);
  //       break;
  //     }
  //   }
  // }

  int someTimeAgo({Duration duration = const Duration(minutes: 5)}) {
    return (DateTime.now().millisecondsSinceEpoch ~/ 1000) - duration.inSeconds;
  }

  /// Creates a simple signer that delegates to this bunker instance
  EventSigner createSigner(BunkerConnection connectionSettings) {
    return _BunkerSigner(this, connectionSettings);
  }

  /// Send a remote signing request
  Future<String> sendSigningRequest(
      BunkerConnection settings, BunkerRequest request) async {
    final completer = Completer<String>();
    final requestId = request.id;

    final localSigner = Bip340EventSigner(
      privateKey: settings.privateKey,
      publicKey: Bip340.getPublicKey(settings.privateKey),
    );

    final encryptedRequest = await localSigner.encryptNip44(
      plaintext: jsonEncode(request),
      recipientPubKey: settings.remotePubkey,
    );

    final requestEvent = Nip01Event(
      pubKey: localSigner.publicKey,
      kind: BunkerRequest.kKind,
      tags: [
        ["p", settings.remotePubkey],
      ],
      content: encryptedRequest!,
    );

    await localSigner.sign(requestEvent);

    // Listen for response
    final subscription = _requests.subscription(
      filters: [
        Filter(
          // authors: [settings.remotePubkey],
          kinds: [BunkerRequest.kKind],
          // pTags: [localSigner.publicKey],
          // since: someTimeAgo(),
        ),
      ],
    );
    _broadcast.broadcast(
      nostrEvent: requestEvent,
      specificRelays: settings.relays,
    );

    await for (final event in subscription.stream) {
      final decryptedContent = await localSigner.decryptNip44(
        ciphertext: event.content,
        senderPubKey: settings.remotePubkey,
      );

      final response = jsonDecode(decryptedContent!);

    }
    late StreamSubscription streamSub;
    streamSub = subscription.stream.listen((event) async {
      final decryptedContent = await localSigner.decryptNip44(
        ciphertext: event.content,
        senderPubKey: settings.remotePubkey,
      );

      final response = jsonDecode(decryptedContent!);

      if (response["id"] == requestId) {
        streamSub.cancel();
        await _requests.closeSubscription(subscription.requestId);

        if (response["error"] != null) {
          completer.completeError(Exception(response["error"]));
        } else {
          completer.complete(response["result"]);
        }
      }
    });
    return completer.future;
  }

  String _generateNostrConnectURL({
    required String publicKey,
    required List<String> relays,
    required String secret,
    List<String>? perms,
    String? appName,
    String? appUrl,
    String? appImageUrl,
  }) {
    final params = <String>[];

    for (final relay in relays) {
      params.add('relay=${Uri.encodeComponent(relay)}');
    }

    params.add('secret=$secret');

    if (perms != null && perms.isNotEmpty) {
      params.add('perms=${perms.join(',')}');
    }

    if (appName != null) {
      params.add('name=${Uri.encodeComponent(appName)}');
    }

    if (appUrl != null) {
      params.add('url=${Uri.encodeComponent(appUrl)}');
    }

    if (appImageUrl != null) {
      params.add('image=${Uri.encodeComponent(appImageUrl)}');
    }

    return 'nostrconnect://$publicKey?${params.join('&')}';
  }
}

/// Simple signer implementation that delegates to Bunkers
class _BunkerSigner implements EventSigner {
  final Bunkers _bunkers;
  final BunkerConnection _settings;
  String? _cachedPublicKey;

  _BunkerSigner(this._bunkers, this._settings);

  @override
  bool canSign() => true;

  @override
  Future<String?> decrypt(String msg, String destPubKey, {String? id}) async {
    final request = BunkerRequest(
      method: BunkerRequestMethods.nip04Decrypt,
      params: [destPubKey, msg],
    );
    return await _bunkers.sendSigningRequest(_settings, request);
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
    return await _bunkers.sendSigningRequest(_settings, request);
  }

  @override
  Future<String?> encrypt(String msg, String destPubKey, {String? id}) async {
    final request = BunkerRequest(
      method: BunkerRequestMethods.nip04Encrypt,
      params: [destPubKey, msg],
    );
    return await _bunkers.sendSigningRequest(_settings, request);
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
    return await _bunkers.sendSigningRequest(_settings, request);
  }

  @override
  String getPublicKey() {
    if (_cachedPublicKey != null) return _cachedPublicKey!;

    // For bunker signers, derive the public key from the private key in connection settings
    // This is a reasonable approach since the connection settings contain our local keypair
    try {
      final publicKey = Bip340.getPublicKey(_settings.privateKey);
      _cachedPublicKey = publicKey;
      return publicKey;
    } catch (e) {
      throw Exception(
          'Failed to derive public key from connection settings: $e');
    }
  }

  Future<String> getPublicKeyAsync() async {
    final request = BunkerRequest(method: BunkerRequestMethods.getPublicKey);
    final publicKey = await _bunkers.sendSigningRequest(_settings, request);
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

    final request = BunkerRequest(
      method: BunkerRequestMethods.signEvent,
      params: [jsonEncode(eventMap)],
    );

    final signedEventJson =
        await _bunkers.sendSigningRequest(_settings, request);
    final signedEvent = jsonDecode(signedEventJson);

    event.id = signedEvent["id"];
    event.sig = signedEvent["sig"];
  }
}
