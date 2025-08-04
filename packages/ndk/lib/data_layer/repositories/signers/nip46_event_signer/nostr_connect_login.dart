import 'dart:async';
import 'dart:convert';

import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import 'models/bunker_event.dart';
import 'models/connection_settings.dart';
import 'utils.dart';

class NostrConnectLogin {
  final _streamController = StreamController<BunkerEvent>.broadcast();
  Stream<BunkerEvent> get stream => _streamController.stream;

  Ndk? ndk;
  NdkResponse? subscription;

  List<String> relays;
  List<String>? perms;
  String? appName;
  String? appUrl;
  String? appImageUrl;

  final keyPair = Bip340.generatePrivateKey();
  final secret = Helpers.getSecureRandomString(16);

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

    if (appName != null) {
      params.add('name=${Uri.encodeComponent(appName!)}');
    }

    if (appUrl != null) {
      params.add('url=${Uri.encodeComponent(appUrl!)}');
    }

    if (appImageUrl != null) {
      params.add('image=${Uri.encodeComponent(appImageUrl!)}');
    }

    return 'nostrconnect://$pubkey?${params.join('&')}';
  }

  NostrConnectLogin({
    required this.relays,
    this.perms,
    this.appName,
    this.appUrl,
    this.appImageUrl,
  }) {
    if (relays.isEmpty) {
      throw ArgumentError("At least one relay is required");
    }

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
          kinds: [24133],
          pTags: [localEventSigner.publicKey],
          since: someTimeAgo(),
        ),
      ],
    );

    listenConnection();
  }

  Future<void> listenConnection() async {
    await for (final event in subscription!.stream) {
      final decryptedContent = await localEventSigner.decryptNip44(
        ciphertext: event.content,
        senderPubKey: event.pubKey,
      );

      final response = jsonDecode(decryptedContent!);

      if (response["result"] == "auth_url") {
        _streamController.add(AuthRequired(response["error"]));
        continue;
      }

      if (response["result"] == secret) {
        _streamController.add(
          Connected(
            ConnectionSettings(
              privateKey: localEventSigner.privateKey!,
              remotePubkey: event.pubKey,
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
