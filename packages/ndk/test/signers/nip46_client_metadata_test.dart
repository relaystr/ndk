import 'dart:convert';

import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

import '../mocks/mock_relay.dart';

void main() {
  group('bunker connect', () {
    late MockRelay relay;
    late Ndk ndk;

    String bunkerUrl() => 'bunker://${MockRelay.remoteSignerPublicKey}'
        '?relay=${relay.url}&secret=s3cret';

    setUp(() async {
      relay = MockRelay(name: 'nip46-client-metadata-relay');
      await relay.startServer();

      ndk = Ndk(
        NdkConfig(
          cache: MemCacheManager(),
          eventVerifier: Bip340EventVerifier(),
          bootstrapRelays: [relay.url],
        ),
      );
      await ndk.relays.seedRelaysConnected;
    });

    tearDown(() async {
      await ndk.destroy();
      await relay.stopServer();
    });

    test('sends perms and metadata', () async {
      await ndk.bunkers.connectWithBunkerUrl(
        bunkerUrl(),
        clientMetadata: const Nip46ClientMetadata(
          name: 'My app',
          url: 'https://myapp.example',
          perms: ['nip44_encrypt', 'sign_event:4'],
        ),
      );

      final params = relay.lastConnectParams!;
      expect(params, hasLength(4));
      expect(
        params.sublist(0, 3),
        equals([
          MockRelay.remoteSignerPublicKey,
          's3cret',
          'nip44_encrypt,sign_event:4',
        ]),
      );
      expect(
        jsonDecode(params[3]),
        equals({'name': 'My app', 'url': 'https://myapp.example'}),
      );
    });

    test('sends empty perms before metadata alone', () async {
      await ndk.bunkers.connectWithBunkerUrl(
        bunkerUrl(),
        clientMetadata: const Nip46ClientMetadata(name: 'My app'),
      );

      final params = relay.lastConnectParams!;
      expect(params[2], isEmpty);
      expect(jsonDecode(params[3]), equals({'name': 'My app'}));
    });

    test('without metadata sends pubkey and secret', () async {
      await ndk.bunkers.connectWithBunkerUrl(bunkerUrl());

      expect(
        relay.lastConnectParams,
        equals([MockRelay.remoteSignerPublicKey, 's3cret']),
      );
    });
  });

  test('nostrconnect URL carries perms and metadata', () {
    final nostrConnect = NostrConnect(
      relays: ['wss://relay.example.com'],
      clientMetadata: const Nip46ClientMetadata(
        name: 'My app',
        url: 'https://myapp.example',
        image: 'https://myapp.example/icon.png',
        perms: ['nip44_encrypt', 'sign_event:4'],
      ),
    );

    final query = Uri.parse(nostrConnect.nostrConnectURL).queryParameters;
    expect(query['perms'], equals('nip44_encrypt,sign_event:4'));
    expect(query['name'], equals('My app'));
    expect(query['url'], equals('https://myapp.example'));
    expect(query['image'], equals('https://myapp.example/icon.png'));
  });
}
