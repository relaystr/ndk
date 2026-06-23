part of 'cache_manager_test_suite.dart';

void _runEventTests(CacheManager Function() getCacheManager,
    LocalEventSignerFactory eventSignerFactory) {
  test('saveEvent and loadEvent', () async {
    final cacheManager = getCacheManager();
    final event = Nip01Event(
      pubKey: 'test_pubkey_event_1',
      kind: 1,
      tags: [
        ['p', 'another_pubkey'],
        ['t', 'test'],
      ],
      content: 'Test event content',
      createdAt: 1234567890,
    );

    await cacheManager.saveEvent(event);
    final loadedEvent = await cacheManager.loadEvent(event.id);

    expect(loadedEvent, isNotNull);
    expect(loadedEvent!.id, equals(event.id));
    expect(loadedEvent.pubKey, equals(event.pubKey));
    expect(loadedEvent.kind, equals(event.kind));
    expect(loadedEvent.content, equals(event.content));
    expect(loadedEvent.createdAt, equals(event.createdAt));
  });

  test('saveEvents batch operation', () async {
    final cacheManager = getCacheManager();
    final events = [
      Nip01Event(
        pubKey: 'pubkey_batch_1',
        kind: 1,
        tags: [],
        content: 'Event 1',
        createdAt: 1234567890,
      ),
      Nip01Event(
        pubKey: 'pubkey_batch_2',
        kind: 1,
        tags: [],
        content: 'Event 2',
        createdAt: 1234567891,
      ),
    ];

    await cacheManager.saveEvents(events);

    for (final event in events) {
      final loaded = await cacheManager.loadEvent(event.id);
      expect(loaded, isNotNull);
      expect(loaded!.content, equals(event.content));
    }
  });

  test('loadEvents with pubKeys filter', () async {
    final cacheManager = getCacheManager();
    await cacheManager.removeAllEvents();

    final events = [
      Nip01Event(
        pubKey: 'pubkey_filter_1',
        kind: 1,
        tags: [],
        content: 'Event 1',
        createdAt: 1234567890,
      ),
      Nip01Event(
        pubKey: 'pubkey_filter_2',
        kind: 1,
        tags: [],
        content: 'Event 2',
        createdAt: 1234567891,
      ),
      Nip01Event(
        pubKey: 'pubkey_filter_1',
        kind: 2,
        tags: [],
        content: 'Event 3',
        createdAt: 1234567892,
      ),
    ];

    await cacheManager.saveEvents(events);

    final loadedEvents = await cacheManager.loadEvents(
      pubKeys: ['pubkey_filter_1'],
    );

    expect(loadedEvents.length, equals(2));
    expect(loadedEvents.every((e) => e.pubKey == 'pubkey_filter_1'), isTrue);
  });

  test('loadEvents with kinds filter', () async {
    final cacheManager = getCacheManager();
    await cacheManager.removeAllEvents();

    final events = [
      Nip01Event(
        pubKey: 'pubkey_kind_1',
        kind: 1,
        tags: [],
        content: 'Event 1',
        createdAt: 1234567890,
      ),
      Nip01Event(
        pubKey: 'pubkey_kind_2',
        kind: 2,
        tags: [],
        content: 'Event 2',
        createdAt: 1234567891,
      ),
      Nip01Event(
        pubKey: 'pubkey_kind_3',
        kind: 1,
        tags: [],
        content: 'Event 3',
        createdAt: 1234567892,
      ),
    ];

    await cacheManager.saveEvents(events);

    final loadedEvents = await cacheManager.loadEvents(kinds: [1]);

    expect(loadedEvents.length, equals(2));
    expect(loadedEvents.every((e) => e.kind == 1), isTrue);
  });

  test('loadEvents with tags filter', () async {
    final cacheManager = getCacheManager();
    await cacheManager.removeAllEvents();

    final events = [
      Nip01Event(
        pubKey: 'pubkey_ptag_1',
        kind: 1,
        tags: [
          ['p', 'target_pubkey_ptag'],
        ],
        content: 'Event 1',
        createdAt: 1234567890,
      ),
      Nip01Event(
        pubKey: 'pubkey_ptag_2',
        kind: 1,
        tags: [
          ['p', 'other_pubkey'],
        ],
        content: 'Event 2',
        createdAt: 1234567891,
      ),
    ];

    await cacheManager.saveEvents(events);

    final loadedEvents = await cacheManager.loadEvents(
      tags: {
        'p': ['target_pubkey_ptag']
      },
    );

    expect(loadedEvents.length, equals(1));
    expect(loadedEvents.first.pTags.contains('target_pubkey_ptag'), isTrue);
  });

  test('loadEvents with time range filters', () async {
    final cacheManager = getCacheManager();
    await cacheManager.removeAllEvents();

    final events = [
      Nip01Event(
        pubKey: 'pubkey_time_1',
        kind: 1,
        tags: [],
        content: 'Event 1',
        createdAt: 1000,
      ),
      Nip01Event(
        pubKey: 'pubkey_time_2',
        kind: 1,
        tags: [],
        content: 'Event 2',
        createdAt: 2000,
      ),
      Nip01Event(
        pubKey: 'pubkey_time_3',
        kind: 1,
        tags: [],
        content: 'Event 3',
        createdAt: 3000,
      ),
    ];

    await cacheManager.saveEvents(events);

    final eventsSince = await cacheManager.loadEvents(since: 2000);
    expect(eventsSince.length, equals(2));

    final eventsUntil = await cacheManager.loadEvents(until: 2000);
    expect(eventsUntil.length, equals(2));

    final eventsRange = await cacheManager.loadEvents(since: 1500, until: 2500);
    expect(eventsRange.length, equals(1));
    expect(eventsRange.first.createdAt, equals(2000));
  });

  test('loadEvents with combined filters', () async {
    final cacheManager = getCacheManager();
    await cacheManager.removeAllEvents();

    final events = [
      Nip01Event(
        pubKey: 'pubkey_combined_1',
        kind: 1,
        tags: [],
        content: 'Event 1',
        createdAt: 1234567890,
      ),
      Nip01Event(
        pubKey: 'pubkey_combined_1',
        kind: 2,
        tags: [],
        content: 'Event 2',
        createdAt: 1234567891,
      ),
      Nip01Event(
        pubKey: 'pubkey_combined_2',
        kind: 1,
        tags: [],
        content: 'Event 3',
        createdAt: 1234567892,
      ),
    ];

    await cacheManager.saveEvents(events);

    final loadedEvents = await cacheManager.loadEvents(
      pubKeys: ['pubkey_combined_1'],
      kinds: [1],
    );

    expect(loadedEvents.length, equals(1));
    expect(loadedEvents.first.pubKey, equals('pubkey_combined_1'));
    expect(loadedEvents.first.kind, equals(1));
  });

  test('removeEvent', () async {
    final cacheManager = getCacheManager();
    final event = Nip01Event(
      pubKey: 'pubkey_remove',
      kind: 1,
      tags: [],
      content: 'Test event to remove',
      createdAt: 1234567890,
    );

    await cacheManager.saveEvent(event);
    expect(await cacheManager.loadEvent(event.id), isNotNull);

    await cacheManager.removeEvent(event.id);
    expect(await cacheManager.loadEvent(event.id), isNull);
  });

  test('removeEvents by ids', () async {
    final cacheManager = getCacheManager();
    final key1 = Bip340.generatePrivateKey();
    final key2 = Bip340.generatePrivateKey();
    final key3 = Bip340.generatePrivateKey();
    final signer1 = eventSignerFactory.create(
        privateKey: key1.privateKey, publicKey: key1.publicKey);
    final signer2 = eventSignerFactory.create(
        privateKey: key2.privateKey, publicKey: key2.publicKey);
    final signer3 = eventSignerFactory.create(
        privateKey: key3.privateKey, publicKey: key3.publicKey);

    final event1 = await signer1.sign(Nip01Event(
        pubKey: key1.publicKey, kind: 1, tags: [], content: 'Event 1'));
    final event2 = await signer2.sign(Nip01Event(
        pubKey: key2.publicKey, kind: 1, tags: [], content: 'Event 2'));
    final event3 = await signer3.sign(Nip01Event(
        pubKey: key3.publicKey, kind: 1, tags: [], content: 'Event 3'));

    await cacheManager.saveEvents([event1, event2, event3]);
    expect(await cacheManager.loadEvent(event1.id), isNotNull);
    expect(await cacheManager.loadEvent(event2.id), isNotNull);
    expect(await cacheManager.loadEvent(event3.id), isNotNull);

    await cacheManager.removeEvents(ids: [event1.id, event2.id]);

    expect(await cacheManager.loadEvent(event1.id), isNull);
    expect(await cacheManager.loadEvent(event2.id), isNull);
    expect(await cacheManager.loadEvent(event3.id), isNotNull);
  });

  test('removeEvents with pubKeys and kinds', () async {
    final cacheManager = getCacheManager();
    await cacheManager.removeAllEvents();

    final events = [
      Nip01Event(
        pubKey: 'author_filter_1',
        kind: 1,
        tags: [],
        content: 'Event 1 kind 1',
        createdAt: 1000,
      ),
      Nip01Event(
        pubKey: 'author_filter_1',
        kind: 2,
        tags: [],
        content: 'Event 2 kind 2',
        createdAt: 2000,
      ),
      Nip01Event(
        pubKey: 'author_filter_2',
        kind: 1,
        tags: [],
        content: 'Event 3 kind 1',
        createdAt: 3000,
      ),
      Nip01Event(
        pubKey: 'author_filter_1',
        kind: 1,
        tags: [],
        content: 'Event 4 kind 1',
        createdAt: 4000,
      ),
    ];

    await cacheManager.saveEvents(events);

    await cacheManager.removeEvents(
      pubKeys: ['author_filter_1'],
      kinds: [1],
    );

    expect(await cacheManager.loadEvent(events[0].id), isNull);
    expect(await cacheManager.loadEvent(events[3].id), isNull);
    expect(await cacheManager.loadEvent(events[1].id), isNotNull);
    expect(await cacheManager.loadEvent(events[2].id), isNotNull);
  });

  test('removeEvents with time range', () async {
    final cacheManager = getCacheManager();
    await cacheManager.removeAllEvents();

    final events = [
      Nip01Event(
        pubKey: 'time_filter_author',
        kind: 1,
        tags: [],
        content: 'Event 1',
        createdAt: 1000,
      ),
      Nip01Event(
        pubKey: 'time_filter_author',
        kind: 1,
        tags: [],
        content: 'Event 2',
        createdAt: 2000,
      ),
      Nip01Event(
        pubKey: 'time_filter_author',
        kind: 1,
        tags: [],
        content: 'Event 3',
        createdAt: 3000,
      ),
      Nip01Event(
        pubKey: 'time_filter_author',
        kind: 1,
        tags: [],
        content: 'Event 4',
        createdAt: 4000,
      ),
    ];

    await cacheManager.saveEvents(events);

    await cacheManager.removeEvents(
      pubKeys: ['time_filter_author'],
      until: 2500,
    );

    expect(await cacheManager.loadEvent(events[0].id), isNull);
    expect(await cacheManager.loadEvent(events[1].id), isNull);
    expect(await cacheManager.loadEvent(events[2].id), isNotNull);
    expect(await cacheManager.loadEvent(events[3].id), isNotNull);
  });

  test('removeEvents with empty parameters does nothing', () async {
    final cacheManager = getCacheManager();
    await cacheManager.removeAllEvents();

    final event = Nip01Event(
      pubKey: 'empty_filter_author',
      kind: 1,
      tags: [],
      content: 'Event 1',
      createdAt: 1000,
    );

    await cacheManager.saveEvent(event);
    await cacheManager.removeEvents();

    expect(await cacheManager.loadEvent(event.id), isNotNull);
  });

  test('removeEvents with tags filter', () async {
    final cacheManager = getCacheManager();
    await cacheManager.removeAllEvents();

    final events = [
      Nip01Event(
        pubKey: 'tag_filter_author',
        kind: 1,
        tags: [
          ['p', 'target_pubkey_1']
        ],
        content: 'Event 1 with p tag',
        createdAt: 1000,
      ),
      Nip01Event(
        pubKey: 'tag_filter_author',
        kind: 1,
        tags: [
          ['p', 'target_pubkey_2']
        ],
        content: 'Event 2 with different p tag',
        createdAt: 2000,
      ),
      Nip01Event(
        pubKey: 'tag_filter_author',
        kind: 1,
        tags: [
          ['e', 'some_event_id']
        ],
        content: 'Event 3 with e tag',
        createdAt: 3000,
      ),
      Nip01Event(
        pubKey: 'tag_filter_author',
        kind: 1,
        tags: [],
        content: 'Event 4 without tags',
        createdAt: 4000,
      ),
    ];

    await cacheManager.saveEvents(events);

    await cacheManager.removeEvents(
      tags: {
        'p': ['target_pubkey_1']
      },
    );

    expect(await cacheManager.loadEvent(events[0].id), isNull);
    expect(await cacheManager.loadEvent(events[1].id), isNotNull);
    expect(await cacheManager.loadEvent(events[2].id), isNotNull);
    expect(await cacheManager.loadEvent(events[3].id), isNotNull);
  });

  test('removeAllEventsByPubKey', () async {
    final cacheManager = getCacheManager();
    await cacheManager.removeAllEvents();

    final events = [
      Nip01Event(
          pubKey: 'pubkey_remove_all_1',
          kind: 1,
          tags: [],
          content: 'Event 1',
          createdAt: 1234567890),
      Nip01Event(
          pubKey: 'pubkey_remove_all_1',
          kind: 2,
          tags: [],
          content: 'Event 2',
          createdAt: 1234567891),
      Nip01Event(
          pubKey: 'pubkey_remove_all_2',
          kind: 1,
          tags: [],
          content: 'Event 3',
          createdAt: 1234567892),
    ];

    await cacheManager.saveEvents(events);
    await cacheManager.removeAllEventsByPubKey('pubkey_remove_all_1');

    expect(await cacheManager.loadEvent(events[0].id), isNull);
    expect(await cacheManager.loadEvent(events[1].id), isNull);
    expect(await cacheManager.loadEvent(events[2].id), isNotNull);
  });

  test('removeAllEvents', () async {
    final cacheManager = getCacheManager();
    final events = [
      Nip01Event(
          pubKey: 'pubkey_clear_1',
          kind: 1,
          tags: [],
          content: 'Event 1',
          createdAt: 1234567890),
      Nip01Event(
          pubKey: 'pubkey_clear_2',
          kind: 1,
          tags: [],
          content: 'Event 2',
          createdAt: 1234567891),
    ];

    await cacheManager.saveEvents(events);
    await cacheManager.removeAllEvents();

    for (final event in events) {
      expect(await cacheManager.loadEvent(event.id), isNull);
    }
  });

  test('event with tags preserved correctly', () async {
    final cacheManager = getCacheManager();
    final event = Nip01Event(
      pubKey: 'pubkey_tags',
      kind: 1,
      tags: [
        ['p', 'pubkey1', 'wss://relay.com', 'alias'],
        ['e', 'event_id_ref'],
        ['t', 'nostr'],
        ['custom', 'value1', 'value2'],
      ],
      content: 'Event with tags',
      createdAt: 1234567890,
    );

    await cacheManager.saveEvent(event);
    final loaded = await cacheManager.loadEvent(event.id);

    expect(loaded, isNotNull);
    expect(loaded!.tags.length, equals(event.tags.length));
    expect(loaded.tags, equals(event.tags));
    expect(loaded.pTags, contains('pubkey1'));
    expect(loaded.tTags, contains('nostr'));
  });

  test('replaceable events keep only the current winner in query results',
      () async {
    final cacheManager = getCacheManager();
    await cacheManager.removeAllEvents();

    const kind = 30023;
    const pubKey = 'replaceable_author';
    const dTag = 'article-1';

    final version1 = Nip01Event(
      id: 'bbbb',
      pubKey: pubKey,
      kind: kind,
      tags: const [
        ['d', dTag]
      ],
      content: 'version 1',
      createdAt: 1000,
    );

    final version2 = Nip01Event(
      id: 'cccc',
      pubKey: pubKey,
      kind: kind,
      tags: const [
        ['d', dTag]
      ],
      content: 'version 2',
      createdAt: 2000,
    );

    final version3 = Nip01Event(
      id: 'aaaa',
      pubKey: pubKey,
      kind: kind,
      tags: const [
        ['d', dTag]
      ],
      content: 'version 3',
      createdAt: 2000,
    );

    await cacheManager.saveEvents([version1, version2, version3]);

    final loadedEvents = await cacheManager.loadEvents(
      pubKeys: const [pubKey],
      kinds: const [kind],
      tags: const {
        'd': [dTag]
      },
    );

    expect(loadedEvents.length, equals(1));
    expect(loadedEvents.first.id, equals('aaaa'));
    expect(loadedEvents.first.content, equals('version 3'));
  });

  test('non-replaceable events do not compete with each other', () async {
    final cacheManager = getCacheManager();
    await cacheManager.removeAllEvents();

    const pubKey = 'normal_author';

    final event1 = Nip01Event(
      id: 'normal-1',
      pubKey: pubKey,
      kind: 1,
      tags: const [],
      content: 'note 1',
      createdAt: 1000,
    );

    final event2 = Nip01Event(
      id: 'normal-2',
      pubKey: pubKey,
      kind: 1,
      tags: const [],
      content: 'note 2',
      createdAt: 2000,
    );

    await cacheManager.saveEvents([event1, event2]);

    final loadedEvents = await cacheManager.loadEvents(
      pubKeys: const [pubKey],
      kinds: const [1],
    );

    expect(loadedEvents.length, equals(2));
    expect(loadedEvents.map((e) => e.id).toSet(), {'normal-1', 'normal-2'});
  });

  test('incoming deletion suppresses matching target event on reads', () async {
    final cacheManager = getCacheManager();
    await cacheManager.removeAllEvents();

    final target = Nip01Event(
      id: 'target-event',
      pubKey: 'author-a',
      kind: 1,
      tags: const [],
      content: 'target',
      createdAt: 1000,
    );

    final deletion = Nip01Event(
      id: 'deletion-event',
      pubKey: 'author-a',
      kind: 5,
      tags: const [
        ['e', 'target-event']
      ],
      content: 'delete target-event',
      createdAt: 2000,
    );

    await cacheManager.saveEvents([target, deletion]);

    final loadedEvents = await cacheManager.loadEvents(ids: ['target-event']);

    expect(loadedEvents, isEmpty);
    expect(await cacheManager.loadEvent('deletion-event'), isNotNull);
  });

  test('out-of-order deletion prevents target resurrection', () async {
    final cacheManager = getCacheManager();
    await cacheManager.removeAllEvents();

    final deletion = Nip01Event(
      id: 'deletion-first',
      pubKey: 'author-a',
      kind: 5,
      tags: const [
        ['e', 'target-late']
      ],
      content: 'delete target-late',
      createdAt: 2000,
    );

    final target = Nip01Event(
      id: 'target-late',
      pubKey: 'author-a',
      kind: 1,
      tags: const [],
      content: 'late target',
      createdAt: 1000,
    );

    await cacheManager.saveEvent(deletion);
    await cacheManager.saveEvent(target);

    final loadedEvents = await cacheManager.loadEvents(ids: ['target-late']);

    expect(loadedEvents, isEmpty);
  });

  test('deletions do not apply across authors', () async {
    final cacheManager = getCacheManager();
    await cacheManager.removeAllEvents();

    final target = Nip01Event(
      id: 'shared-id',
      pubKey: 'author-b',
      kind: 1,
      tags: const [],
      content: 'should survive',
      createdAt: 1000,
    );

    final deletion = Nip01Event(
      id: 'cross-author-deletion',
      pubKey: 'author-a',
      kind: 5,
      tags: const [
        ['e', 'shared-id']
      ],
      content: 'attempted delete',
      createdAt: 2000,
    );

    await cacheManager.saveEvents([target, deletion]);

    final loadedEvents = await cacheManager.loadEvents(ids: ['shared-id']);

    expect(loadedEvents.length, equals(1));
    expect(loadedEvents.first.pubKey, equals('author-b'));
  });

  test(
      'expired events are filtered from normal reads but remain loadable by id',
      () async {
    final cacheManager = getCacheManager();
    await cacheManager.removeAllEvents();

    final expiredEvent = Nip01Event(
      id: 'expired-event',
      pubKey: 'expired-author',
      kind: 1,
      tags: const [
        ['expiration', '1']
      ],
      content: 'expired',
      createdAt: 1000,
    );

    await cacheManager.saveEvent(expiredEvent);

    final queryResults = await cacheManager.loadEvents(ids: ['expired-event']);
    final directLookup = await cacheManager.loadEvent('expired-event');

    expect(queryResults, isEmpty);
    expect(directLookup, isNotNull);
  });

  test('adding the same event source provenance from multiple relays merges',
      () async {
    final cacheManager = getCacheManager();

    await cacheManager.addEventSource(
      eventId: 'relay-merge-event',
      relayUrl: 'wss://relay-one.example',
    );
    await cacheManager.addEventSource(
      eventId: 'relay-merge-event',
      relayUrl: 'wss://relay-two.example',
    );

    final sources = await cacheManager.loadEventSources('relay-merge-event');

    expect(
      sources.toSet(),
      {
        'wss://relay-one.example',
        'wss://relay-two.example',
      },
    );
  });

  test('addEventSource and loadEventSources dedupe and preserve all sources',
      () async {
    final cacheManager = getCacheManager();

    await cacheManager.addEventSource(
      eventId: 'source-event',
      relayUrl: 'wss://relay-b.example',
    );
    await cacheManager.addEventSource(
      eventId: 'source-event',
      relayUrl: 'wss://relay-a.example',
    );
    await cacheManager.addEventSource(
      eventId: 'source-event',
      relayUrl: 'wss://relay-b.example',
    );

    final sources = await cacheManager.loadEventSources('source-event');

    expect(sources, ['wss://relay-a.example', 'wss://relay-b.example']);
  });

  test('removeEventSources clears provenance for an event', () async {
    final cacheManager = getCacheManager();

    await cacheManager.addEventSources(
      eventId: 'source-event-remove',
      relayUrls: const ['wss://relay-a.example', 'wss://relay-b.example'],
    );

    expect(
      await cacheManager.loadEventSources('source-event-remove'),
      isNotEmpty,
    );

    await cacheManager.removeEventSources('source-event-remove');

    expect(await cacheManager.loadEventSources('source-event-remove'), isEmpty);
  });

  test('saveEventDeliveryRecord and loadEventDeliveryRecord roundtrip',
      () async {
    final cacheManager = getCacheManager();

    const record = EventDeliveryRecord(
      eventId: 'delivery-event-1',
      status: EventDeliveryStatus.partiallyDelivered,
      createdAt: 1000,
      updatedAt: 2000,
    );

    await cacheManager.saveEventDeliveryRecord(record);
    final loaded = await cacheManager.loadEventDeliveryRecord(record.eventId);

    expect(loaded, isNotNull);
    expect(loaded!.toJson(), equals(record.toJson()));
  });

  test('loadEventDeliveryRecords filters by status', () async {
    final cacheManager = getCacheManager();
    await cacheManager.removeAllEventDeliveryRecords();

    const deliveredRecord = EventDeliveryRecord(
      eventId: 'delivery-complete',
      status: EventDeliveryStatus.delivered,
      createdAt: 1000,
      updatedAt: 1000,
      completedAt: 1001,
    );

    const pendingRecord = EventDeliveryRecord(
      eventId: 'delivery-pending',
      status: EventDeliveryStatus.inProgress,
      createdAt: 2000,
      updatedAt: 2001,
    );

    await cacheManager.saveEventDeliveryRecords([
      deliveredRecord,
      pendingRecord,
    ]);

    final inProgress = await cacheManager.loadEventDeliveryRecords(
      status: EventDeliveryStatus.inProgress,
    );

    expect(inProgress.map((record) => record.eventId), ['delivery-pending']);
  });

  test('removeEventDeliveryRecord and removeAllEventDeliveryRecords work',
      () async {
    final cacheManager = getCacheManager();
    await cacheManager.removeAllEventDeliveryRecords();

    const recordA = EventDeliveryRecord(
      eventId: 'delivery-remove-a',
      createdAt: 1000,
      updatedAt: 1000,
    );
    const recordB = EventDeliveryRecord(
      eventId: 'delivery-remove-b',
      createdAt: 1001,
      updatedAt: 1001,
    );

    await cacheManager.saveEventDeliveryRecords([recordA, recordB]);
    await cacheManager.removeEventDeliveryRecord(recordA.eventId);

    expect(await cacheManager.loadEventDeliveryRecord(recordA.eventId), isNull);
    expect(
      await cacheManager.loadEventDeliveryRecord(recordB.eventId),
      isNotNull,
    );

    await cacheManager.removeAllEventDeliveryRecords();

    expect(await cacheManager.loadEventDeliveryRecords(), isEmpty);
  });

  test('relay delivery targets roundtrip and query independently', () async {
    final cacheManager = getCacheManager();
    await cacheManager.removeAllRelayDeliveryTargets();

    const targetA = RelayDeliveryTargetRecord(
      eventId: 'delivery-target-event',
      target: RelayDeliveryTarget(
        relayUrl: 'wss://relay-a.example',
        reason: RelayDeliveryReason.authorWrite,
        state: RelayDeliveryState.acked,
        attemptCount: 1,
        lastOkMessage: 'ok',
      ),
    );

    const targetB = RelayDeliveryTargetRecord(
      eventId: 'delivery-target-event',
      target: RelayDeliveryTarget(
        relayUrl: 'wss://relay-b.example',
        reason: RelayDeliveryReason.replyAuthorRead,
        state: RelayDeliveryState.transientFailure,
        attemptCount: 2,
        nextRetryAt: 3000,
        lastError: 'timeout',
      ),
    );

    await cacheManager.saveRelayDeliveryTargets([targetA, targetB]);

    final loadedA = await cacheManager.loadRelayDeliveryTarget(
      eventId: targetA.eventId,
      relayUrl: targetA.relayUrl,
    );
    final loadedForEvent = await cacheManager.loadRelayDeliveryTargets(
      eventId: 'delivery-target-event',
    );
    final nonAcked = await cacheManager.loadRelayDeliveryTargets(
      excludeAcked: true,
    );

    expect(loadedA?.toJson(), targetA.toJson());
    expect(loadedForEvent.map((record) => record.relayUrl).toSet(), {
      'wss://relay-a.example',
      'wss://relay-b.example',
    });
    expect(
        nonAcked.map((record) => record.relayUrl), ['wss://relay-b.example']);
  });

  test('independent relay target updates for same event do not overwrite',
      () async {
    final cacheManager = getCacheManager();
    await cacheManager.removeAllRelayDeliveryTargets();

    await cacheManager.saveRelayDeliveryTarget(const RelayDeliveryTargetRecord(
      eventId: 'race-safe-event',
      target: RelayDeliveryTarget(
        relayUrl: 'wss://relay-a.example',
        reason: RelayDeliveryReason.authorWrite,
        state: RelayDeliveryState.acked,
      ),
    ));
    await cacheManager.saveRelayDeliveryTarget(const RelayDeliveryTargetRecord(
      eventId: 'race-safe-event',
      target: RelayDeliveryTarget(
        relayUrl: 'wss://relay-b.example',
        reason: RelayDeliveryReason.explicit,
        state: RelayDeliveryState.transientFailure,
        attemptCount: 1,
      ),
    ));

    final loaded = await cacheManager.loadRelayDeliveryTargets(
      eventId: 'race-safe-event',
    );

    expect(loaded.length, 2);
    expect(loaded.map((record) => record.relayUrl).toSet(), {
      'wss://relay-a.example',
      'wss://relay-b.example',
    });
  });

  test('removeRelayDeliveryTarget and removeRelayDeliveryTargets work',
      () async {
    final cacheManager = getCacheManager();
    await cacheManager.removeAllRelayDeliveryTargets();

    await cacheManager.saveRelayDeliveryTargets(const [
      RelayDeliveryTargetRecord(
        eventId: 'target-remove-event',
        target: RelayDeliveryTarget(
          relayUrl: 'wss://relay-a.example',
          reason: RelayDeliveryReason.authorWrite,
        ),
      ),
      RelayDeliveryTargetRecord(
        eventId: 'target-remove-event',
        target: RelayDeliveryTarget(
          relayUrl: 'wss://relay-b.example',
          reason: RelayDeliveryReason.explicit,
        ),
      ),
      RelayDeliveryTargetRecord(
        eventId: 'other-target-remove-event',
        target: RelayDeliveryTarget(
          relayUrl: 'wss://relay-c.example',
          reason: RelayDeliveryReason.hint,
        ),
      ),
    ]);

    await cacheManager.removeRelayDeliveryTarget(
      eventId: 'target-remove-event',
      relayUrl: 'wss://relay-a.example',
    );

    expect(
      await cacheManager.loadRelayDeliveryTarget(
        eventId: 'target-remove-event',
        relayUrl: 'wss://relay-a.example',
      ),
      isNull,
    );

    await cacheManager.removeRelayDeliveryTargets('target-remove-event');

    expect(
      await cacheManager.loadRelayDeliveryTargets(
        eventId: 'target-remove-event',
      ),
      isEmpty,
    );
    expect(
      await cacheManager.loadRelayDeliveryTargets(
        eventId: 'other-target-remove-event',
      ),
      isNotEmpty,
    );
  });

  test('removing an event also removes its provenance and delivery state',
      () async {
    final cacheManager = getCacheManager();

    final event = Nip01Event(
      id: 'event-with-associated-state',
      pubKey: 'author-associated',
      kind: 1,
      tags: const [],
      content: 'hello',
      createdAt: 1000,
    );

    await cacheManager.saveEvent(event);
    await cacheManager.addEventSources(
      eventId: event.id,
      relayUrls: const ['wss://relay-a.example', 'wss://relay-b.example'],
    );
    await cacheManager.saveEventDeliveryRecord(const EventDeliveryRecord(
      eventId: 'event-with-associated-state',
      createdAt: 1000,
      updatedAt: 1001,
    ));
    await cacheManager.saveRelayDeliveryTarget(const RelayDeliveryTargetRecord(
      eventId: 'event-with-associated-state',
      target: RelayDeliveryTarget(
        relayUrl: 'wss://relay-a.example',
        reason: RelayDeliveryReason.authorWrite,
      ),
    ));

    await cacheManager.removeEvent(event.id);

    expect(await cacheManager.loadEvent(event.id), isNull);
    expect(await cacheManager.loadEventSources(event.id), isEmpty);
    expect(await cacheManager.loadEventDeliveryRecord(event.id), isNull);
    expect(await cacheManager.loadRelayDeliveryTargets(eventId: event.id),
        isEmpty);
  });
}
