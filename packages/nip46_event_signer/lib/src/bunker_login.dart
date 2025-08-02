import 'dart:async';
import 'dart:convert';

import 'package:ndk/ndk.dart';
import 'package:nip01/nip01.dart';
import 'package:nip46_event_signer/src/models/bunker_event.dart';
import 'package:nip46_event_signer/src/models/connection_settings.dart';
import 'package:nip46_event_signer/src/utils.dart';

class BunkerLogin {
  final _streamController = StreamController<BunkerEvent>.broadcast();
  Stream<BunkerEvent> get stream => _streamController.stream;

  Ndk? ndk;
  NdkResponse? subscription;

  BunkerLogin({required String bunkerUrl}) {
    _connect(bunkerUrl: bunkerUrl);
  }

  _connect({required String bunkerUrl}) async {
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

    final keyPair = KeyPair.generate();
    final localEventSigner = Bip340EventSigner(
      privateKey: keyPair.privateKey,
      publicKey: keyPair.publicKey,
    );

    final request = {
      "id": generateRandomString(),
      "method": "connect",
      "params": [remotePubkey, secret],
    };

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

    ndk = Ndk(
      NdkConfig(
        eventVerifier: Bip340EventVerifier(),
        cache: MemCacheManager(),
        bootstrapRelays: relays,
      ),
    );

    subscription = ndk!.requests.subscription(
      explicitRelays: relays,
      filters: [
        Filter(
          authors: [remotePubkey],
          kinds: [24133],
          pTags: [localEventSigner.publicKey],
          since: someTimeAgo(),
        ),
      ],
    );

    await localEventSigner.sign(requestEvent);
    ndk!.broadcast.broadcast(nostrEvent: requestEvent, specificRelays: relays);

    await for (final event in subscription!.stream) {
      final decryptedContent = await localEventSigner.decryptNip44(
        ciphertext: event.content,
        senderPubKey: remotePubkey,
      );

      final response = jsonDecode(decryptedContent!);

      if (response["id"] != request["id"]) continue;

      if (response["result"] == "auth_url") {
        _streamController.add(AuthRequired(response["error"]));
        continue;
      }

      if (response["result"] == "ack") {
        _streamController.add(
          Connected(
            ConnectionSettings(
              privateKey: localEventSigner.privateKey!,
              remotePubkey: remotePubkey,
              relays: relays,
            ),
          ),
        );
        break;
      }
    }

    dispose();
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
