import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import 'mocks/mock_relay.dart';

void main() {
  group('Trailing slash', () {
    late MockRelay relay;

    setUp(() async {
      relay = MockRelay(name: 'test');
      await relay.startServer();

      final ndk = Ndk.emptyBootstrapRelaysConfig();

      final keyPair = Bip340.generatePrivateKey();
      ndk.accounts.loginPrivateKey(
        pubkey: keyPair.publicKey,
        privkey: keyPair.privateKey!,
      );

      final event = Nip01Event(
        pubKey: keyPair.publicKey,
        kind: 1,
        tags: [],
        content: "Test",
      );

      final broadcast = ndk.broadcast.broadcast(
        nostrEvent: event,
        specificRelays: [relay.url],
      );
      await broadcast.broadcastDoneFuture;

      ndk.destroy();
    });

    tearDown(() async {
      await relay.stopServer();
    });

    test('Query without trailling /', () async {
      final ndk = Ndk.emptyBootstrapRelaysConfig();

      final query = ndk.requests.query(
        filters: [
          Filter(kinds: [1], limit: 1),
        ],
        explicitRelays: [relay.url],
      );

      await for (var event in query.stream) {
        expect(event.content, equals("Test"));
        break;
      }
    });

    test('Query with trailling /', () async {
      final ndk = Ndk.emptyBootstrapRelaysConfig();

      final query = ndk.requests.query(
        filters: [
          Filter(kinds: [1], limit: 1),
        ],
        explicitRelays: ["${relay.url}/"],
      );

      await for (var event in query.stream) {
        expect(event.content, equals("Test"));
        break;
      }
    });

    test('Subscription without trailling /', () async {
      final ndk = Ndk.emptyBootstrapRelaysConfig();

      final query = ndk.requests.subscription(
        filters: [
          Filter(kinds: [1], limit: 1),
        ],
        explicitRelays: [relay.url],
      );

      await for (var event in query.stream) {
        expect(event.content, equals("Test"));
        break;
      }
    });

    test('Subscription with trailling /', () async {
      final ndk = Ndk.emptyBootstrapRelaysConfig();

      final query = ndk.requests.subscription(
        filters: [
          Filter(kinds: [1], limit: 1),
        ],
        explicitRelays: ["${relay.url}/"],
      );

      await for (var event in query.stream) {
        expect(event.content, equals("Test"));
        break;
      }
    });
  });
}
