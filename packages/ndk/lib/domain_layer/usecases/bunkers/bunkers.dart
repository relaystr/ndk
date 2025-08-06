import 'dart:async';
import 'dart:convert';

import 'package:ndk/domain_layer/usecases/bunkers/models/nostr_connect.dart';

import '../../../data_layer/repositories/signers/bip340_event_signer.dart';
import '../../../data_layer/repositories/signers/nip46_event_signer.dart';
import '../../../shared/nips/nip01/helpers.dart';
import 'models/bunker_request.dart';
import 'models/bunker_connection.dart';
import '../../../shared/nips/nip01/bip340.dart';
import '../../entities/filter.dart';
import '../../entities/nip_01_event.dart';
import '../broadcast/broadcast.dart';
import '../requests/requests.dart';

/// Bunkers usecase that handles NIP-46 remote signing protocol operations
class Bunkers {
  final Broadcast _broadcast;
  final Requests _requests;

  Bunkers({
    required Broadcast broadcast,
    required Requests requests,
  })
      : _broadcast = broadcast,
        _requests = requests;

  /// Connects to a bunker using a bunker URL (bunker://)
  Future<BunkerConnection?> connectWithBunkerUrl(String bunkerUrl) async {
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
    BunkerConnection? result;

    await for (final event in subscription.stream.timeout(
        Duration(seconds: 20))) {
      final decryptedContent = await localEventSigner.decryptNip44(
        ciphertext: event.content,
        senderPubKey: remotePubkey,
      );

      final response = jsonDecode(decryptedContent!);

      if (response["id"] != request.id) continue;

      if (response["result"] == "auth_url") {
        // _streamController.add(AuthRequired(response["error"]));
        // TODO what can we do about this?
        continue;
      }

      if (response["result"] == "ack") {
        result = BunkerConnection(
          privateKey: localEventSigner.privateKey!,
          remotePubkey: remotePubkey,
          relays: relays,
        );
        break;
      }
    }
    await _requests.closeSubscription(subscription.requestId);
    return result;
  }

  /// Connects to a bunker using a nostr connect URL (nostrconnect://)
  Future<BunkerConnection?> connectWithNostrConnect(NostrConnect nostrConnect) async {
    final relays = nostrConnect.relays;
    final secret = nostrConnect.secret;

    if (relays.isEmpty) {
      throw ArgumentError('At least one relay is required in bunker URL');
    }

    final keyPair = nostrConnect.keyPair;
    final localEventSigner = Bip340EventSigner(
      privateKey: keyPair.privateKey,
      publicKey: keyPair.publicKey,
    );

    final subscription = _requests.subscription(
      explicitRelays: relays,
      filters: [
        Filter(
          kinds: [BunkerRequest.kKind],
          pTags: [localEventSigner.publicKey],
          since: someTimeAgo(),
        ),
      ],
    );
    BunkerConnection? result;

    await for (final event in subscription.stream.timeout(
        Duration(seconds: 20))) {
      final decryptedContent = await localEventSigner.decryptNip44(
        ciphertext: event.content,
        senderPubKey: event.pubKey,
      );

      final response = jsonDecode(decryptedContent!);

      if (response["result"] == secret) {
        result = BunkerConnection(
          privateKey: localEventSigner.privateKey!,
          remotePubkey: event.pubKey,
          relays: relays,
        );
        break;
      }
    }
    await _requests.closeSubscription(subscription.requestId);
    return result;
  }

  int someTimeAgo({Duration duration = const Duration(minutes: 5)}) {
    return (DateTime
        .now()
        .millisecondsSinceEpoch ~/ 1000) - duration.inSeconds;
  }

  /// Creates a simple signer that delegates to this bunker instance
  Nip46EventSigner createSigner(BunkerConnection connection) {
    return Nip46EventSigner(
        connection: connection, requests: _requests, broadcast: _broadcast);
  }
}

