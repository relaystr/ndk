import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_cache_manager_test_suite/ndk_cache_manager_test_suite.dart';
import 'package:ndk_sqlite3/ndk_sqlite3.dart';
import 'package:ndk_sqlite3/src/sql.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

SqliteCacheManager _inMemory() => SqliteCacheManager(sqlite3.openInMemory());

void _holdWriteLock((String, SendPort) args) {
  final (path, locked) = args;
  final db = sqlite3.open(path);
  db.execute('BEGIN IMMEDIATE');
  locked.send(null);
  sleep(const Duration(milliseconds: 300));
  db.execute('COMMIT');
  db.close();
}

void main() {
  runCacheManagerTestSuite(
    name: 'SqliteCacheManager',
    createCacheManager: () async => _inMemory(),
    cleanUp: (cacheManager) => cacheManager.close(),
  );

  test('persists across reopening the database file', () async {
    final directory = await Directory.systemTemp.createTemp('ndk_sqlite3');
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}/cache.db';
    final event = Nip01Event(
      pubKey: 'reopen_author',
      kind: 1,
      tags: [
        ['t', 'nostr'],
      ],
      content: 'kept',
      createdAt: 1000,
    );

    final first = SqliteCacheManager.open(path);
    await first.saveEvent(event);
    first.setDefaultWalletForSending('wallet-1');
    await first.close();

    final second = SqliteCacheManager.open(path);
    final loaded = await second.loadEvents(
      tags: {
        't': ['nostr'],
      },
    );
    expect(loaded.single.id, event.id);
    expect(second.getDefaultWalletIdForSending(), 'wallet-1');
    await second.close();
  });

  test('waits for a write lock held by another connection', () async {
    final directory = await Directory.systemTemp.createTemp('ndk_sqlite3');
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}/cache.db';
    final cacheManager = SqliteCacheManager.open(path);
    addTearDown(cacheManager.close);

    final locked = ReceivePort();
    await Isolate.spawn(_holdWriteLock, (path, locked.sendPort));
    await locked.first;

    final event = Nip01Event(
      pubKey: 'busy_author',
      kind: 1,
      tags: [],
      content: 'waited',
      createdAt: 1000,
    );
    await cacheManager.saveEvent(event);
    expect((await cacheManager.loadEvent(event.id))?.content, 'waited');
  });

  test('a tag filter drives the query over a single kind', () async {
    final db = sqlite3.openInMemory();
    final cacheManager = SqliteCacheManager(db);
    addTearDown(cacheManager.close);

    final where = eventFilter(
      kinds: [7],
      tags: {
        '#e': ['note'],
      },
    );
    final plan = db.select(
      'EXPLAIN QUERY PLAN SELECT e.id FROM events e WHERE $where '
      'ORDER BY e.created_at DESC, e.id LIMIT 50',
      where.args,
    );
    expect(
      plan.map((row) => row['detail'] as String),
      everyElement(isNot(contains('events_kind_created_at'))),
    );
  });

  test('persists and restores a BOLT12 wallet', () async {
    final cacheManager = _inMemory();
    const offer =
        'lno1pqqq5xj5wajkcan9gdshx6pq23jhxarfdenjqstyv3ex2umnzcss80xkrjkyrjk43u5dgu8f6a450fg2cnjtg7lhg76c3gtk5gdhshns';
    final wallet = Bolt12Wallet(
      id: 'bolt12-test',
      name: 'BOLT12 test wallet',
      supportedUnits: const {'sat'},
      offer: offer,
      source: 'alice@example.com',
      bip353Address: 'alice@example.com',
      description: 'Test offer',
      issuer: 'Test issuer',
      currency: 'USD',
      expiresAt: 2000000000,
      quantityMax: 10,
      hasBlindedPaths: true,
      metadata: const {'cardColor': 123},
    );

    await cacheManager.storeWallet(wallet);
    final restored = await cacheManager.getWallet(wallet.id) as Bolt12Wallet;

    expect(restored.offer, offer);
    expect(restored.bip353Address, wallet.bip353Address);
    expect(restored.expiresAt, wallet.expiresAt);
    expect(restored.hasBlindedPaths, isTrue);
    expect(restored.metadata['cardColor'], 123);

    await cacheManager.close();
  });

  test('persists full event delivery record state', () async {
    final cacheManager = _inMemory();
    const original = EventDeliveryRecord(
      eventId: 'event-1',
      status: EventDeliveryStatus.needsAction,
      signingState: EventSigningState.transientFailure,
      createdAt: 1700000000,
      updatedAt: 1700000100,
      serializedEventJson: '{"id":"event-1"}',
      signedAt: 1700000050,
      completedAt: 1700000200,
      requiresInteractiveSigning: true,
      signAttemptCount: 3,
      lastSignAttemptAt: 1700000090,
      nextSignRetryAt: 1700000400,
      lastSignError: 'timed out waiting for signer',
    );

    await cacheManager.saveEventDeliveryRecord(original);
    final restored = await cacheManager.loadEventDeliveryRecord(
      original.eventId,
    );

    expect(restored?.toJson(), original.toJson());
    await cacheManager.close();
  });

  test('a deletion by coordinate keeps later versions visible', () async {
    final cacheManager = _inMemory();
    Nip01Event article(int createdAt) => Nip01Event(
      pubKey: 'coordinate_author',
      kind: 30023,
      tags: [
        ['d', 'Article'],
      ],
      content: 'at $createdAt',
      createdAt: createdAt,
    );
    final deletion = Nip01Event(
      pubKey: 'coordinate_author',
      kind: 5,
      tags: [
        ['a', '30023:coordinate_author:Article'],
      ],
      content: '',
      createdAt: 200,
    );
    await cacheManager.saveEvents([article(100), article(200), article(300)]);
    await cacheManager.saveEvent(deletion);

    final visible = await cacheManager.loadEvents(kinds: [30023]);
    final result = await cacheManager.evict(const EvictionPolicy.safeSweep());

    expect(visible.map((e) => e.content), ['at 300']);
    expect(result.removedDeleted, 2);
    expect(await cacheManager.loadEvent(article(300).id), isNotNull);
    await cacheManager.close();
  });

  group('matches MemCacheManager', () {
    for (var seed = 0; seed < 20; seed++) {
      test('on random dataset $seed', () async {
        final dataset = _Dataset(Random(seed));

        Future<(MemCacheManager, SqliteCacheManager)> filled() async {
          final expected = MemCacheManager();
          final actual = _inMemory();
          for (final cacheManager in [expected, actual]) {
            await cacheManager.saveEvents(dataset.events);
            await cacheManager.saveEventDeliveryRecords(dataset.deliveries);
            await cacheManager.saveRelayDeliveryTargets(dataset.targets);
          }
          return (expected, actual);
        }

        final (expected, actual) = await filled();
        for (final query in dataset.queries) {
          expect(
            _ids(await query(actual)),
            _ids(await query(expected)),
            reason: 'seed $seed',
          );
        }
        for (final query in dataset.hiddenQueries) {
          expect(
            _hidden(await query(actual)),
            _hidden(await query(expected)),
            reason: 'seed $seed',
          );
        }
        await actual.close();

        for (final policy in _policies) {
          final (expected, actual) = await filled();
          final expectedResult = await expected.evict(policy);
          final actualResult = await actual.evict(policy);
          expect(
            _evictionCounts(actualResult),
            _evictionCounts(expectedResult),
            reason: 'seed $seed',
          );
          for (final event in dataset.events) {
            expect(
              await actual.loadEvent(event.id) != null,
              await expected.loadEvent(event.id) != null,
              reason: 'seed $seed, event ${event.content}',
            );
          }
          await actual.close();
        }
      });
    }
  });
}

const _policies = [
  EvictionPolicy.safeSweep(),
  EvictionPolicy(
    kindCaps: {1: 5, 0: 1, 30023: 2},
    protectedKinds: {},
    protectedPubKeys: {'author-c'},
  ),
  EvictionPolicy(
    sweepExpired: false,
    sweepDeleted: false,
    kindCaps: {1: 3, 20001: 0},
    protectedKinds: {},
  ),
  EvictionPolicy(
    sweepSuperseded: false,
    sweepDeliveredEphemeral: false,
    sweepTerminalFailedDeliveries: true,
    kindCaps: {30023: 1},
    protectedKinds: {},
    protectedCoordinates: {'30023:author-a:x'},
  ),
];

typedef _Query = Future<List<Nip01Event>> Function(CacheManager cacheManager);
typedef _HiddenQuery =
    Future<List<HiddenEvent>> Function(CacheManager cacheManager);

class _Dataset {
  static const _authors = ['author-a', 'author-b', 'author-c'];

  final events = <Nip01Event>[];
  final deliveries = <EventDeliveryRecord>[];
  final targets = <RelayDeliveryTarget>[];
  late final List<_Query> queries;
  late final List<_HiddenQuery> hiddenQueries;

  _Dataset(Random random) {
    // distinct timestamps: ties are covered by the shared suite
    final timestamps = List.generate(200, (i) => 1000 + i * 10)
      ..shuffle(random);
    var next = 0;
    String author() => _authors[random.nextInt(_authors.length)];

    for (var i = 0; i < 120; i++) {
      final kind = const [
        1,
        1,
        0,
        3,
        30023,
        30023,
        10002,
        20001,
      ][random.nextInt(8)];
      events.add(
        Nip01Event(
          pubKey: author(),
          kind: kind,
          tags: [
            if (kind == 30023)
              [
                'd',
                const ['x', 'y', 'Z'][random.nextInt(3)],
              ],
            if (random.nextInt(6) == 0)
              ['expiration', random.nextBool() ? '1' : '4000000000'],
            if (random.nextInt(3) == 0) ['p', author()],
          ],
          content: 'event $i',
          createdAt: timestamps[next++],
        ),
      );
    }
    for (var i = 0; i < 25; i++) {
      final target = events[random.nextInt(events.length)];
      final byCoordinate =
          random.nextBool() &&
          EventCacheStateRecord.conflictKeyFor(target) != null;
      events.add(
        Nip01Event(
          pubKey: random.nextInt(4) == 0 ? author() : target.pubKey,
          kind: 5,
          tags: [
            byCoordinate
                ? [
                    'a',
                    '${target.kind}:${target.pubKey}:${target.getDtag() ?? ''}',
                  ]
                : ['e', target.id],
          ],
          content: 'deletion $i',
          createdAt: timestamps[next++],
        ),
      );
    }
    final ephemeral = [
      for (final event in events)
        if (event.kind == 20001) event,
    ];
    for (var i = 0; i < 15; i++) {
      final event = ephemeral.isNotEmpty && random.nextBool()
          ? ephemeral[random.nextInt(ephemeral.length)]
          : events[random.nextInt(events.length)];
      deliveries.add(
        EventDeliveryRecord(
          eventId: event.id,
          status: const [
            EventDeliveryStatus.delivered,
            EventDeliveryStatus.delivered,
            EventDeliveryStatus.inProgress,
            EventDeliveryStatus.failed,
          ][random.nextInt(4)],
          createdAt: 1000,
          updatedAt: 1000,
          completedAt: 1000,
        ),
      );
      targets.add(
        RelayDeliveryTarget(
          eventId: event.id,
          relayUrl: 'wss://relay.example',
          reason: RelayDeliveryReason.authorWrite,
          state: random.nextBool()
              ? RelayDeliveryState.acked
              : RelayDeliveryState.pending,
        ),
      );
    }
    events.shuffle(random);

    final someIds = [for (final event in events.take(30)) event.id];
    queries = [
      (cm) => cm.loadEvents(),
      (cm) => cm.loadEvents(ids: someIds),
      (cm) => cm.loadEvents(kinds: [30023], limit: 3),
      (cm) => cm.loadEvents(pubKeys: ['author-a'], kinds: [0, 3]),
      (cm) => cm.loadEvents(
        tags: {
          'd': ['x', 'Z'],
        },
      ),
      (cm) => cm.loadEvents(tags: {'#p': []}),
      (cm) => cm.loadEvents(search: 'EVENT 1', since: 1500, until: 2500),
    ];
    hiddenQueries = [
      (cm) => cm.loadHiddenEvents(),
      (cm) => cm.loadHiddenEvents(reasons: {HiddenEventReason.superseded}),
      (cm) =>
          cm.loadHiddenEvents(coordinates: ['30023:author-a:x', '0:author-b']),
      (cm) => cm.loadHiddenEvents(kinds: [1], limit: 4),
    ];
  }
}

List<String> _ids(List<Nip01Event> events) => [for (final e in events) e.id];

List<String> _hidden(List<HiddenEvent> hidden) => [
  for (final h in hidden)
    '${h.event.id} ${h.reasons.map((r) => r.name).toList()..sort()} '
        '${h.state.isCurrent} ${h.state.coordinateKey}',
];

List<int> _evictionCounts(EvictionResult result) => [
  result.removedEvents,
  result.removedExpired,
  result.removedDeleted,
  result.removedSuperseded,
  result.removedDeliveredEphemeral,
  result.removedByKindCap,
  result.keptDueToDeliveryState,
  result.keptProtected,
  result.removedCompletedDeliveries,
  result.removedTerminalFailedDeliveries,
];
