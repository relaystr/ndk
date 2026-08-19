import 'package:ndk/domain_layer/usecases/requests/verify_event_stream.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import '../mocks/mock_relay.dart';

/// counts how often each event id is handed to the verifier
class CountingEventVerifier implements EventVerifier {
  final Map<String, int> counts = {};

  int countFor(String id) => counts[id] ?? 0;

  void reset() => counts.clear();

  @override
  Future<bool> verify(Nip01Event event) async {
    counts.update(event.id, (count) => count + 1, ifAbsent: () => 1);
    return true;
  }
}

void main() async {
  late KeyPair key1;
  late Bip340EventSigner signer;
  late CountingEventVerifier verifier;
  late MockRelay relay1;
  late MockRelay relay2;
  late Ndk ndk;

  Future<Nip01Event> signedEvent(String content, int createdAt) => signer.sign(
    Nip01Event(
      kind: Nip01Event.kTextNodeKind,
      pubKey: key1.publicKey,
      content: content,
      tags: [],
      createdAt: createdAt,
    ),
  );

  setUp(() async {
    key1 = Bip340.generatePrivateKey();
    signer = Bip340EventSigner(
      privateKey: key1.privateKey,
      publicKey: key1.publicKey,
    );
    verifier = CountingEventVerifier();

    relay1 = MockRelay(name: "relay 1", explicitPort: 6090);
    relay2 = MockRelay(name: "relay 2", explicitPort: 6091);
    await relay1.startServer();
    await relay2.startServer();

    ndk = Ndk(
      NdkConfig(
        eventVerifier: verifier,
        cache: MemCacheManager(),
        bootstrapRelays: [relay1.url, relay2.url],
        logLevel: LogLevel.off,
      ),
    );
    ndk.accounts.loginExternalSigner(signer: signer);
  });

  tearDown(() async {
    await ndk.destroy();
    await relay1.stopServer();
    await relay2.stopServer();
  });

  group('re-verification of already verified events (issue #715)', () {
    test('does not re-verify an event delivered more than once', () async {
      final event = await signedEvent("duplicate", 1000);

      final results = await VerifyEventStream(
        unverifiedStreamInput: Stream.fromIterable([event, event, event]),
        eventVerifier: verifier,
      )().toList();

      expect(results.length, equals(3));
      expect(
        verifier.countFor(event.id),
        equals(1),
        reason: 'an event already verified should not be verified again',
      );
    });

    test('does not verify an event that already carries validSig true', () async {
      final event = (await signedEvent("cached", 1000)).copyWith(
        validSig: true,
      );

      await VerifyEventStream(
        unverifiedStreamInput: Stream.fromIterable([event]),
        eventVerifier: verifier,
      )().toList();

      expect(
        verifier.countFor(event.id),
        equals(0),
        reason: 'validSig true means the signature was already checked',
      );
    });

    test('verifies an event once when two relays deliver it', () async {
      final event = await signedEvent("shared", 1000);

      for (final url in [relay1.url, relay2.url]) {
        final response = ndk.broadcast.broadcast(
          nostrEvent: event,
          specificRelays: [url],
        );
        await response.broadcastDoneFuture;
      }

      await ndk.config.cache.clearAll();
      verifier.reset();

      final events = await ndk.requests
          .query(
            filter: Filter(
              kinds: [Nip01Event.kTextNodeKind],
              authors: [key1.publicKey],
            ),
            explicitRelays: [relay1.url, relay2.url],
          )
          .future;

      expect(events.length, equals(1));
      expect(
        verifier.countFor(event.id),
        equals(1),
        reason: 'the second copy should be deduplicated before verification',
      );
    });

    test('does not re-verify an event a previous request verified', () async {
      final event = await signedEvent("re-requested", 1000);
      final response = ndk.broadcast.broadcast(
        nostrEvent: event,
        specificRelays: [relay1.url],
      );
      await response.broadcastDoneFuture;

      await ndk.config.cache.clearAll();
      verifier.reset();

      final filter = Filter(
        kinds: [Nip01Event.kTextNodeKind],
        authors: [key1.publicKey],
      );

      await ndk.requests
          .query(
            filter: filter,
            explicitRelays: [relay1.url],
            cacheRead: false,
          )
          .future;
      await ndk.requests
          .query(
            filter: filter,
            explicitRelays: [relay1.url],
            cacheRead: false,
          )
          .future;

      expect(
        verifier.countFor(event.id),
        equals(1),
        reason: 'an event verified by a previous request stays verified',
      );
    });
  });
}
