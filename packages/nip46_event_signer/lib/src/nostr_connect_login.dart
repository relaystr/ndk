import 'dart:async';
import 'dart:convert';

import 'package:ndk/ndk.dart';
import 'package:nip01/nip01.dart';
import 'package:nip46_event_signer/src/models/connection_settings.dart';
import 'package:nip46_event_signer/src/utils.dart';

class NostrConnectLogin {
  Ndk ndk;

  List<String> relays;
  List<String>? perms;
  String? name;
  String? url;
  String? image;

  final keyPair = KeyPair.generate();
  final secret = generateRandomString();

  final _connectionController =
      StreamController<ConnectionSettings>.broadcast();
  Stream<ConnectionSettings> get connectionStream =>
      _connectionController.stream;

  late NdkResponse subscription;

  Bip340EventSigner get localEventSigner => Bip340EventSigner(
    privateKey: keyPair.privateKey,
    publicKey: keyPair.publicKey,
  );

  String get nostrConnectURL {
    final pubkey = localEventSigner.publicKey;

    final params = <String>[];

    for (final relay in relays) {
      params.add('relay=${Uri.encodeComponent(relay)}');
    }

    params.add('secret=$secret');

    if (perms != null && perms!.isNotEmpty) {
      params.add('perms=${perms!.join(',')}');
    }

    if (name != null) {
      params.add('name=${Uri.encodeComponent(name!)}');
    }

    if (url != null) {
      params.add('url=${Uri.encodeComponent(url!)}');
    }

    if (image != null) {
      params.add('image=${Uri.encodeComponent(image!)}');
    }

    return 'nostrconnect://$pubkey?${params.join('&')}';
  }

  NostrConnectLogin({
    required this.ndk,
    required this.relays,
    this.perms,
    this.name,
    this.url,
    this.image,
  }) {
    if (relays.isEmpty) {
      throw ArgumentError("At least one relay is required");
    }

    final oneHourAgo =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000) -
        Duration(hours: 1).inSeconds;
    subscription = ndk.requests.subscription(
      explicitRelays: relays,
      filters: [
        Filter(
          kinds: [24133],
          pTags: [localEventSigner.publicKey],
          since: oneHourAgo,
        ),
      ],
    );

    listenConnection();
  }

  Future<void> listenConnection() async {
    await for (final event in subscription.stream) {
      final decryptedContent = await localEventSigner.decryptNip44(
        ciphertext: event.content,
        senderPubKey: event.pubKey,
      );

      final response = jsonDecode(decryptedContent!);

      if (response["method"] != "connect") continue;

      _connectionController.add(
        ConnectionSettings(
          privateKey: localEventSigner.privateKey!,
          remotePubkey: event.pubKey,
          relays: relays,
        ),
      );

      break;
    }

    ndk.requests.closeSubscription(subscription.requestId);
  }

  void dispose() {
    _connectionController.close();
  }
}
