import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import '../mocks/mock_relay.dart';

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

      final event = Nip01EventService.createEventCalculateId(
        pubKey: keyPair.publicKey,
        kind: 1,
        tags: [],
        content: "Test",
      );
      final signedEvent = Nip01EventService.signWithPrivateKey(
        event: event,
        privateKey: keyPair.privateKey!,
      );

      final broadcast = ndk.broadcast.broadcast(
        nostrEvent: signedEvent,
        specificRelays: [relay.url],
      );
      final broadcastResponses = await broadcast.broadcastDoneFuture;
      expect(broadcastResponses.first.broadcastSuccessful, isTrue);

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

      ndk.destroy();
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

      ndk.destroy();
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

      ndk.destroy();
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

      ndk.destroy();
    });

    test('Broadcast without trailling /', () async {
      final ndk = Ndk.emptyBootstrapRelaysConfig();

      final keyPair = Bip340.generatePrivateKey();
      ndk.accounts.loginPrivateKey(
        pubkey: keyPair.publicKey,
        privkey: keyPair.privateKey!,
      );

      final event = Nip01EventService.createEventCalculateId(
        pubKey: keyPair.publicKey,
        kind: 1,
        tags: [],
        content: "Test",
      );
      final signedEvent = Nip01EventService.signWithPrivateKey(
        event: event,
        privateKey: keyPair.privateKey!,
      );

      final broadcast = ndk.broadcast.broadcast(
        nostrEvent: signedEvent,
        specificRelays: [relay.url],
      );
      final broadcastResponses = await broadcast.broadcastDoneFuture;
      expect(broadcastResponses.first.broadcastSuccessful, isTrue);

      ndk.destroy();
    });

    test('Broadcast with trailling /', () async {
      final ndk = Ndk.emptyBootstrapRelaysConfig();

      final keyPair = Bip340.generatePrivateKey();
      ndk.accounts.loginPrivateKey(
        pubkey: keyPair.publicKey,
        privkey: keyPair.privateKey!,
      );

      final event = Nip01EventService.createEventCalculateId(
        pubKey: keyPair.publicKey,
        kind: 1,
        tags: [],
        content: "Test",
      );
      final signedEvent = Nip01EventService.signWithPrivateKey(
        event: event,
        privateKey: keyPair.privateKey!,
      );

      final broadcast = ndk.broadcast.broadcast(
        nostrEvent: signedEvent,
        specificRelays: ["${relay.url}/"],
      );
      final broadcastResponses = await broadcast.broadcastDoneFuture;
      expect(broadcastResponses.first.broadcastSuccessful, isTrue);

      ndk.destroy();
    });

    test('Query without trailling / and JIT', () async {
      final ndk = Ndk(NdkConfig(
        eventVerifier: Bip340EventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.JIT,
      ));

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

      ndk.destroy();
    });

    test('Query with trailling / and JIT', () async {
      final ndk = Ndk(NdkConfig(
        eventVerifier: Bip340EventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.JIT,
      ));

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

      ndk.destroy();
    });

    test('Subscription without trailling / and JIT', () async {
      final ndk = Ndk(NdkConfig(
        eventVerifier: Bip340EventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.JIT,
      ));

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

      ndk.destroy();
    });

    test('Subscription with trailling / and JIT', () async {
      final ndk = Ndk(NdkConfig(
        eventVerifier: Bip340EventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.JIT,
      ));

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

      ndk.destroy();
    });

    test('Broadcast without trailling / and JIT', () async {
      final ndk = Ndk(NdkConfig(
        eventVerifier: Bip340EventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.JIT,
      ));

      final keyPair = Bip340.generatePrivateKey();
      ndk.accounts.loginPrivateKey(
        pubkey: keyPair.publicKey,
        privkey: keyPair.privateKey!,
      );

      final event = Nip01EventService.createEventCalculateId(
        pubKey: keyPair.publicKey,
        kind: 1,
        tags: [],
        content: "Test",
      );
      final signedEvent = Nip01EventService.signWithPrivateKey(
        event: event,
        privateKey: keyPair.privateKey!,
      );

      final broadcast = ndk.broadcast.broadcast(
        nostrEvent: signedEvent,
        specificRelays: [relay.url],
      );
      final broadcastResponses = await broadcast.broadcastDoneFuture;
      expect(broadcastResponses.first.broadcastSuccessful, isTrue);

      ndk.destroy();
    });

    test('Broadcast with trailling / and JIT', () async {
      final ndk = Ndk(NdkConfig(
        eventVerifier: Bip340EventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.JIT,
      ));

      final keyPair = Bip340.generatePrivateKey();
      ndk.accounts.loginPrivateKey(
        pubkey: keyPair.publicKey,
        privkey: keyPair.privateKey!,
      );

      final event = Nip01EventService.createEventCalculateId(
        pubKey: keyPair.publicKey,
        kind: 1,
        tags: [],
        content: "Test",
      );

      final signedEvent = Nip01EventService.signWithPrivateKey(
        event: event,
        privateKey: keyPair.privateKey!,
      );

      final broadcast = ndk.broadcast.broadcast(
        nostrEvent: signedEvent,
        specificRelays: ["${relay.url}/"],
      );
      final broadcastResponses = await broadcast.broadcastDoneFuture;
      expect(broadcastResponses.first.broadcastSuccessful, isTrue);

      ndk.destroy();
    });
  });
}
