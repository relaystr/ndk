import 'dart:convert';

import 'package:ndk/ndk.dart';
import 'package:nip01/nip01.dart';
import 'package:nip46_event_signer/src/models/connection_settings.dart';
import 'package:nip46_event_signer/src/utils.dart';

Future<ConnectionSettings> bunkerLogin({
  required Ndk ndk,
  required String bunkerUrl,
}) async {
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

  final oneHourAgo =
      (DateTime.now().millisecondsSinceEpoch ~/ 1000) -
      Duration(hours: 1).inSeconds;
  final subscription = ndk.requests.subscription(
    explicitRelays: relays,
    filters: [
      Filter(
        authors: [remotePubkey],
        kinds: [24133],
        pTags: [localEventSigner.publicKey],
        since: oneHourAgo,
      ),
    ],
  );

  ndk.broadcast.broadcast(nostrEvent: requestEvent, specificRelays: relays);

  await for (final event in subscription.stream) {
    final decryptedContent = await localEventSigner.decryptNip44(
      ciphertext: event.content,
      senderPubKey: remotePubkey,
    );

    final response = jsonDecode(decryptedContent!);

    if (response["id"] != request["id"]) continue;

    break;
  }

  ndk.requests.closeSubscription(subscription.requestId);

  return ConnectionSettings(
    privateKey: localEventSigner.privateKey!,
    remotePubkey: remotePubkey,
    relays: relays,
  );
}
