part of 'cache_manager_test_suite.dart';

void _runEvictionTests(CacheManager Function() getCacheManager) {
  test('evict removes expired events without delivery state', () async {
    final cacheManager = getCacheManager();
    final expiredEvent = Nip01Event(
      pubKey: 'evict_expired_pubkey',
      kind: 1,
      tags: [
        ['expiration', '1'],
      ],
      content: 'expired',
      createdAt: 10,
    );

    await cacheManager.saveEvent(expiredEvent);
    final result = await cacheManager.evict(const EvictionPolicy.safeSweep());

    expect(result.removedEvents, equals(1));
    expect(result.removedExpired, equals(1));
    expect(await cacheManager.loadEvent(expiredEvent.id), isNull);
  });

  test('evict keeps events with delivery state even if expired', () async {
    final cacheManager = getCacheManager();
    final expiredEvent = Nip01Event(
      pubKey: 'evict_locked_pubkey',
      kind: 1,
      tags: [
        ['expiration', '1'],
      ],
      content: 'expired but queued',
      createdAt: 11,
    );

    await cacheManager.saveEvent(expiredEvent);
    await cacheManager.saveEventDeliveryRecord(
      EventDeliveryRecord(
        eventId: expiredEvent.id,
        createdAt: 11,
        updatedAt: 11,
      ),
    );

    final result = await cacheManager.evict(const EvictionPolicy.safeSweep());

    expect(result.removedEvents, equals(0));
    expect(result.keptDueToDeliveryState, equals(1));
    expect(await cacheManager.loadEvent(expiredEvent.id), isNotNull);
  });

  test('evict removes superseded replaceable events but keeps latest',
      () async {
    final cacheManager = getCacheManager();
    final older = Nip01Event(
      pubKey: 'evict_replaceable_pubkey',
      kind: Metadata.kKind,
      tags: [],
      content: '{"name":"old"}',
      createdAt: 100,
    );
    final newer = Nip01Event(
      pubKey: 'evict_replaceable_pubkey',
      kind: Metadata.kKind,
      tags: [],
      content: '{"name":"new"}',
      createdAt: 200,
    );

    await cacheManager.saveEvents([older, newer]);
    final result = await cacheManager.evict(const EvictionPolicy.safeSweep());

    expect(result.removedSuperseded, equals(1));
    expect(await cacheManager.loadEvent(older.id), isNull);
    expect(await cacheManager.loadEvent(newer.id), isNotNull);
    expect(
        (await cacheManager.loadEvents(
          pubKeys: ['evict_replaceable_pubkey'],
          kinds: [Metadata.kKind],
        ))
            .single
            .content,
        contains('new'));
  });

  test('evict removes author-deleted events and their sidecars', () async {
    final cacheManager = getCacheManager();
    final target = Nip01Event(
      pubKey: 'evict_deleted_pubkey',
      kind: 1,
      tags: [],
      content: 'deleted later',
      createdAt: 300,
    );
    final deletion = Nip01Event(
      pubKey: 'evict_deleted_pubkey',
      kind: 5,
      tags: [
        ['e', target.id],
      ],
      content: 'delete',
      createdAt: 301,
    );

    await cacheManager.saveEvent(target);
    await cacheManager.addEventSource(
      eventId: target.id,
      relayUrl: 'wss://relay.example.com',
    );
    await cacheManager.saveDecryptedEventPayloadRecord(
      DecryptedEventPayloadRecord(
        eventId: target.id,
        viewerPubKey: 'viewer',
        plaintextContent: 'secret',
        createdAt: 1,
        updatedAt: 1,
      ),
    );
    await cacheManager.saveEvent(deletion);

    final result = await cacheManager.evict(const EvictionPolicy.safeSweep());

    expect(result.removedDeleted, equals(1));
    expect(await cacheManager.loadEvent(target.id), isNull);
    expect(await cacheManager.loadEventSources(target.id), isEmpty);
    expect(
      await cacheManager.loadDecryptedEventPayloadRecord(
        eventId: target.id,
        viewerPubKey: 'viewer',
      ),
      isNull,
    );
    expect(await cacheManager.loadEvent(deletion.id), isNotNull);
  });

  test('evict applies per-kind caps to visible regular events', () async {
    final cacheManager = getCacheManager();
    final older = Nip01Event(
      pubKey: 'cap_pubkey_1',
      kind: 1,
      tags: const [],
      content: 'older',
      createdAt: 100,
    );
    final middle = Nip01Event(
      pubKey: 'cap_pubkey_2',
      kind: 1,
      tags: const [],
      content: 'middle',
      createdAt: 200,
    );
    final newer = Nip01Event(
      pubKey: 'cap_pubkey_3',
      kind: 1,
      tags: const [],
      content: 'newer',
      createdAt: 300,
    );

    await cacheManager.saveEvents([older, middle, newer]);
    final result = await cacheManager.evict(
      const EvictionPolicy(kindCaps: {1: 2}, protectedKinds: {}),
    );

    expect(result.removedByKindCap, equals(1));
    expect(await cacheManager.loadEvent(older.id), isNull);
    expect(await cacheManager.loadEvent(middle.id), isNotNull);
    expect(await cacheManager.loadEvent(newer.id), isNotNull);
  });

  test('evict keeps protected pubkeys even when a kind cap would remove them',
      () async {
    final cacheManager = getCacheManager();
    final protected = Nip01Event(
      pubKey: 'protected_author',
      kind: 1,
      tags: const [],
      content: 'protected',
      createdAt: 100,
    );
    final unprotected = Nip01Event(
      pubKey: 'unprotected_author',
      kind: 1,
      tags: const [],
      content: 'unprotected',
      createdAt: 200,
    );

    await cacheManager.saveEvents([protected, unprotected]);
    final result = await cacheManager.evict(
      const EvictionPolicy(
        kindCaps: {1: 0},
        protectedKinds: {},
        protectedPubKeys: {'protected_author'},
      ),
    );

    expect(result.keptProtected, equals(1));
    expect(result.removedByKindCap, equals(1));
    expect(await cacheManager.loadEvent(protected.id), isNotNull);
    expect(await cacheManager.loadEvent(unprotected.id), isNull);
  });

  test('evict keeps default protected kinds even when capped to zero',
      () async {
    final cacheManager = getCacheManager();
    final metadata = Nip01Event(
      pubKey: 'protected_kind_author',
      kind: Metadata.kKind,
      tags: const [],
      content: '{"name":"still here"}',
      createdAt: 100,
    );

    await cacheManager.saveEvent(metadata);
    final result = await cacheManager.evict(
      const EvictionPolicy(kindCaps: {Metadata.kKind: 0}),
    );

    expect(result.keptProtected, equals(1));
    expect(result.removedEvents, equals(0));
    expect(await cacheManager.loadEvent(metadata.id), isNotNull);
  });
}
