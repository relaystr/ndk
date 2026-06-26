import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import 'mock_event_verifier.dart';
import 'mock_relay.dart';

void main() {
  test('REQ with #r=a only returns events tagged r=a', () async {
    final keyPair = Bip340.generatePrivateKey();
    final matchingEvent = _signedNote(keyPair, [
      ['r', 'a'],
    ]);
    final nonMatchingEvent = _signedNote(keyPair, [
      ['r', 'b'],
    ]);

    final received = await _queryRelay(
      port: 4080,
      relayName: 'tag-filter-test-relay',
      events: [matchingEvent, nonMatchingEvent],
      filter: Filter(
        kinds: [Nip01Event.kTextNodeKind],
        tags: {
          '#r': ['a'],
        },
      ),
    );

    expect(
      received.map((event) => event.id),
      equals([matchingEvent.id]),
      reason: 'The relay must not return an event whose r tag is not "a".',
    );
  });

  test('REQ with #p still filters previously-supported pubkey tags', () async {
    final keyPair = Bip340.generatePrivateKey();
    final taggedPubkey = Bip340.generatePrivateKey().publicKey;
    final otherPubkey = Bip340.generatePrivateKey().publicKey;

    final matchingEvent = _signedNote(keyPair, [
      ['p', taggedPubkey],
    ]);
    final nonMatchingEvent = _signedNote(keyPair, [
      ['p', otherPubkey],
    ]);

    final received = await _queryRelay(
      port: 4081,
      relayName: 'p-tag-filter-test-relay',
      events: [matchingEvent, nonMatchingEvent],
      filter: Filter(
        kinds: [Nip01Event.kTextNodeKind],
        pTags: [taggedPubkey],
      ),
    );

    expect(
      received.map((event) => event.id),
      equals([matchingEvent.id]),
      reason: 'The #p tag must keep filtering through the generic tag path.',
    );
  });

  test('REQ with #e still filters previously-supported event tags', () async {
    final keyPair = Bip340.generatePrivateKey();
    final taggedEventId = 'a' * 64;
    final otherEventId = 'b' * 64;

    final matchingEvent = _signedNote(keyPair, [
      ['e', taggedEventId],
    ]);
    final nonMatchingEvent = _signedNote(keyPair, [
      ['e', otherEventId],
    ]);

    final received = await _queryRelay(
      port: 4082,
      relayName: 'e-tag-filter-test-relay',
      events: [matchingEvent, nonMatchingEvent],
      filter: Filter(
        kinds: [Nip01Event.kTextNodeKind],
        eTags: [taggedEventId],
      ),
    );

    expect(
      received.map((event) => event.id),
      equals([matchingEvent.id]),
      reason: 'The #e tag must keep filtering through the generic tag path.',
    );
  });

  test('REQ with multiple tags requires all of them to match (AND)', () async {
    final keyPair = Bip340.generatePrivateKey();
    final taggedPubkey = Bip340.generatePrivateKey().publicKey;

    final bothEvent = _signedNote(keyPair, [
      ['r', 'a'],
      ['p', taggedPubkey],
    ]);
    final onlyREvent = _signedNote(keyPair, [
      ['r', 'a'],
    ]);
    final onlyPEvent = _signedNote(keyPair, [
      ['p', taggedPubkey],
    ]);

    final received = await _queryRelay(
      port: 4083,
      relayName: 'multi-tag-filter-test-relay',
      events: [bothEvent, onlyREvent, onlyPEvent],
      filter: Filter(
        kinds: [Nip01Event.kTextNodeKind],
        tags: {
          '#r': ['a'],
          '#p': [taggedPubkey],
        },
      ),
    );

    expect(
      received.map((event) => event.id),
      equals([bothEvent.id]),
      reason: 'An event must match every requested tag, not just one of them.',
    );
  });

  test('REQ safely skips malformed single-element tags', () async {
    final keyPair = Bip340.generatePrivateKey();
    final malformedEvent = _signedNote(keyPair, [
      ['r'],
    ]);
    final validEvent = _signedNote(keyPair, [
      ['r', 'a'],
    ]);

    final received = await _queryRelay(
      port: 4084,
      relayName: 'malformed-tag-filter-test-relay',
      events: [malformedEvent, validEvent],
      filter: Filter(
        kinds: [Nip01Event.kTextNodeKind],
        tags: {
          '#r': ['a'],
        },
      ),
    );

    expect(
      received.map((event) => event.id),
      equals([validEvent.id]),
      reason: 'A value-less tag like ["r"] must be skipped without crashing.',
    );
  });
}

Nip01Event _signedNote(KeyPair keyPair, List<List<String>> tags) {
  return Nip01Utils.signWithPrivateKey(
    event: Nip01Event(
      pubKey: keyPair.publicKey,
      kind: Nip01Event.kTextNodeKind,
      tags: tags,
      content: 'test event',
    ),
    privateKey: keyPair.privateKey!,
  );
}

/// Broadcasts [events] to a fresh [MockRelay] and returns the events a reader
/// receives back for [filter].
Future<List<Nip01Event>> _queryRelay({
  required int port,
  required String relayName,
  required List<Nip01Event> events,
  required Filter filter,
}) async {
  final relay = MockRelay(name: relayName, explicitPort: port);
  await relay.startServer();
  addTearDown(relay.stopServer);

  final writer = Ndk(
    NdkConfig(
      cache: MemCacheManager(),
      eventVerifier: MockEventVerifier(),
      bootstrapRelays: [relay.url],
    ),
  );
  addTearDown(writer.destroy);

  for (final event in events) {
    await writer.broadcast.broadcast(
      nostrEvent: event,
      specificRelays: [relay.url],
    ).broadcastDoneFuture;
  }

  final reader = Ndk(
    NdkConfig(
      cache: MemCacheManager(),
      eventVerifier: MockEventVerifier(),
      bootstrapRelays: [relay.url],
    ),
  );
  addTearDown(reader.destroy);

  return reader.requests.query(filter: filter).future;
}
