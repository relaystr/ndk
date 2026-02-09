/// Shared test suite for CacheManager implementations.
///
/// This library provides a reusable test suite that can be run against any
/// [CacheManager] implementation to verify it correctly implements the
/// interface contract.
///
/// ## Usage
///
/// In your test file, import this library and call [runCacheManagerTestSuite]:
///
/// ```dart
/// import 'package:ndk/shared/test_utils/cache_manager_test_suite.dart';
/// import 'package:test/test.dart';
///
/// void main() {
///   runCacheManagerTestSuite(
///     name: 'MyCacheManager',
///     createCacheManager: () async => MyCacheManager(),
///     tearDown: (cacheManager) async => await cacheManager.close(),
///   );
/// }
/// ```
library;

import 'package:test/test.dart';

import 'package:ndk/domain_layer/entities/contact_list.dart';
import 'package:ndk/domain_layer/entities/metadata.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/domain_layer/entities/nip_05.dart';
import 'package:ndk/domain_layer/entities/pubkey_mapping.dart';
import 'package:ndk/domain_layer/entities/read_write.dart';
import 'package:ndk/domain_layer/entities/read_write_marker.dart';
import 'package:ndk/domain_layer/entities/relay_set.dart';
import 'package:ndk/domain_layer/entities/user_relay_list.dart';
import 'package:ndk/domain_layer/repositories/cache_manager.dart';

/// A factory function that creates a new [CacheManager] instance for testing.
typedef CacheManagerFactory = Future<CacheManager> Function();

/// A teardown function that cleans up after tests.
typedef CacheManagerTearDown = Future<void> Function(CacheManager cacheManager);

/// Runs the complete test suite for a [CacheManager] implementation.
///
/// Parameters:
/// - [name]: A descriptive name for the cache manager being tested.
/// - [createCacheManager]: A factory function that creates a fresh instance
///   of the cache manager for each test group.
/// - [cleanUp]: An optional cleanup function called after each test group.
///   This should close/dispose the cache manager.
///
/// Example:
/// ```dart
/// runCacheManagerTestSuite(
///   name: 'IsarCacheManager',
///   createCacheManager: () async {
///     final cacheManager = IsarCacheManager();
///     await cacheManager.init();
///     return cacheManager;
///   },
///   cleanUp: (cm) async => await cm.close(),
/// );
/// ```
void runCacheManagerTestSuite({
  required String name,
  required CacheManagerFactory createCacheManager,
  CacheManagerTearDown? cleanUp,
}) {
  group('$name CacheManager Test Suite', () {
    late CacheManager cacheManager;

    setUp(() async {
      cacheManager = await createCacheManager();
    });

    tearDown(() async {
      if (cleanUp != null) {
        await cleanUp(cacheManager);
      }
    });

    group('Event Operations', () {
      _runEventTests(() => cacheManager);
    });

    group('Metadata Operations', () {
      _runMetadataTests(() => cacheManager);
    });

    group('ContactList Operations', () {
      _runContactListTests(() => cacheManager);
    });

    group('Nip05 Operations', () {
      _runNip05Tests(() => cacheManager);
    });

    group('UserRelayList Operations', () {
      _runUserRelayListTests(() => cacheManager);
    });

    group('RelaySet Operations', () {
      _runRelaySetTests(() => cacheManager);
    });

    group('Search Operations', () {
      _runSearchTests(() => cacheManager);
    });

    group('ClearAll Operations', () {
      _runClearAllTests(() => cacheManager);
    });
  });
}

// ============================================================================
// Event Tests
// ============================================================================

void _runEventTests(CacheManager Function() getCacheManager) {
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

    // Test since filter
    final eventsSince = await cacheManager.loadEvents(since: 2000);
    expect(eventsSince.length, equals(2));

    // Test until filter
    final eventsUntil = await cacheManager.loadEvents(until: 2000);
    expect(eventsUntil.length, equals(2));

    // Test both filters
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
}

// ============================================================================
// Metadata Tests
// ============================================================================

void _runMetadataTests(CacheManager Function() getCacheManager) {
  test('saveMetadata and loadMetadata', () async {
    final cacheManager = getCacheManager();
    final metadata = Metadata(
      pubKey: 'metadata_pubkey_1',
      name: 'Test User',
      displayName: 'Test Display Name',
      about: 'Test about text',
      picture: 'https://example.com/pic.jpg',
      banner: 'https://example.com/banner.jpg',
      website: 'https://example.com',
      nip05: 'test@example.com',
      lud16: 'test@walletofsatoshi.com',
      lud06: 'lnurl1234',
      updatedAt: 1234567890,
    );

    await cacheManager.saveMetadata(metadata);
    final loaded = await cacheManager.loadMetadata('metadata_pubkey_1');

    expect(loaded, isNotNull);
    expect(loaded!.pubKey, equals(metadata.pubKey));
    expect(loaded.name, equals(metadata.name));
    expect(loaded.displayName, equals(metadata.displayName));
    expect(loaded.about, equals(metadata.about));
    expect(loaded.picture, equals(metadata.picture));
    expect(loaded.banner, equals(metadata.banner));
    expect(loaded.website, equals(metadata.website));
    expect(loaded.nip05, equals(metadata.nip05));
    expect(loaded.lud16, equals(metadata.lud16));
    expect(loaded.lud06, equals(metadata.lud06));
  });

  test('saveMetadatas batch operation', () async {
    final cacheManager = getCacheManager();
    final metadatas = [
      Metadata(pubKey: 'metadata_batch_1', name: 'User 1'),
      Metadata(pubKey: 'metadata_batch_2', name: 'User 2'),
    ];

    await cacheManager.saveMetadatas(metadatas);

    for (final metadata in metadatas) {
      final loaded = await cacheManager.loadMetadata(metadata.pubKey);
      expect(loaded, isNotNull);
      expect(loaded!.name, equals(metadata.name));
    }
  });

  test('loadMetadatas batch operation', () async {
    final cacheManager = getCacheManager();
    final metadatas = [
      Metadata(pubKey: 'metadata_load_batch_1', name: 'User 1'),
      Metadata(pubKey: 'metadata_load_batch_2', name: 'User 2'),
    ];

    await cacheManager.saveMetadatas(metadatas);
    final loaded = await cacheManager.loadMetadatas([
      'metadata_load_batch_1',
      'metadata_load_batch_2',
      'nonexistent_pubkey',
    ]);

    expect(loaded.length, equals(3));
    expect(loaded[0]?.name, equals('User 1'));
    expect(loaded[1]?.name, equals('User 2'));
    expect(loaded[2], isNull);
  });

  test('removeMetadata', () async {
    final cacheManager = getCacheManager();
    final metadata = Metadata(pubKey: 'metadata_remove', name: 'Test User');

    await cacheManager.saveMetadata(metadata);
    expect(await cacheManager.loadMetadata('metadata_remove'), isNotNull);

    await cacheManager.removeMetadata('metadata_remove');
    expect(await cacheManager.loadMetadata('metadata_remove'), isNull);
  });

  test('removeAllMetadatas', () async {
    final cacheManager = getCacheManager();
    final metadatas = [
      Metadata(pubKey: 'metadata_clear_1', name: 'User 1'),
      Metadata(pubKey: 'metadata_clear_2', name: 'User 2'),
    ];

    await cacheManager.saveMetadatas(metadatas);
    await cacheManager.removeAllMetadatas();

    for (final metadata in metadatas) {
      expect(await cacheManager.loadMetadata(metadata.pubKey), isNull);
    }
  });

  test('metadata update overwrites existing', () async {
    final cacheManager = getCacheManager();
    final metadata1 = Metadata(
      pubKey: 'metadata_update',
      name: 'Original Name',
      updatedAt: 1000,
    );

    await cacheManager.saveMetadata(metadata1);

    final metadata2 = Metadata(
      pubKey: 'metadata_update',
      name: 'Updated Name',
      updatedAt: 2000,
    );

    await cacheManager.saveMetadata(metadata2);

    final loaded = await cacheManager.loadMetadata('metadata_update');
    expect(loaded, isNotNull);
    expect(loaded!.name, equals('Updated Name'));
  });
}

// ============================================================================
// ContactList Tests
// ============================================================================

void _runContactListTests(CacheManager Function() getCacheManager) {
  test('saveContactList and loadContactList', () async {
    final cacheManager = getCacheManager();
    final contactList = ContactList(
      pubKey: 'contact_list_pubkey_1',
      contacts: ['contact1', 'contact2', 'contact3'],
    );
    contactList.createdAt = 1234567890;
    contactList.petnames = ['Alice', 'Bob', 'Carol'];
    contactList.followedTags = ['nostr', 'bitcoin'];

    await cacheManager.saveContactList(contactList);
    final loaded = await cacheManager.loadContactList('contact_list_pubkey_1');

    expect(loaded, isNotNull);
    expect(loaded!.pubKey, equals(contactList.pubKey));
    expect(loaded.contacts, equals(contactList.contacts));
    expect(loaded.createdAt, equals(contactList.createdAt));
    expect(loaded.petnames, equals(contactList.petnames));
    expect(loaded.followedTags, equals(contactList.followedTags));
  });

  test('saveContactLists batch operation', () async {
    final cacheManager = getCacheManager();
    final contactLists = [
      ContactList(pubKey: 'contact_batch_1', contacts: ['c1']),
      ContactList(pubKey: 'contact_batch_2', contacts: ['c2']),
    ];

    await cacheManager.saveContactLists(contactLists);

    for (final contactList in contactLists) {
      final loaded = await cacheManager.loadContactList(contactList.pubKey);
      expect(loaded, isNotNull);
      expect(loaded!.contacts, equals(contactList.contacts));
    }
  });

  test('removeContactList', () async {
    final cacheManager = getCacheManager();
    final contactList = ContactList(
      pubKey: 'contact_remove',
      contacts: ['contact1'],
    );

    await cacheManager.saveContactList(contactList);
    expect(await cacheManager.loadContactList('contact_remove'), isNotNull);

    await cacheManager.removeContactList('contact_remove');
    expect(await cacheManager.loadContactList('contact_remove'), isNull);
  });

  test('removeAllContactLists', () async {
    final cacheManager = getCacheManager();
    final contactLists = [
      ContactList(pubKey: 'contact_clear_1', contacts: ['c1']),
      ContactList(pubKey: 'contact_clear_2', contacts: ['c2']),
    ];

    await cacheManager.saveContactLists(contactLists);
    await cacheManager.removeAllContactLists();

    for (final contactList in contactLists) {
      expect(await cacheManager.loadContactList(contactList.pubKey), isNull);
    }
  });
}

// ============================================================================
// Nip05 Tests
// ============================================================================

void _runNip05Tests(CacheManager Function() getCacheManager) {
  test('saveNip05 and loadNip05', () async {
    final cacheManager = getCacheManager();
    final nip05 = Nip05(
      pubKey: 'nip05_pubkey_1',
      nip05: 'test@example.com',
      valid: true,
      networkFetchTime: 1234567890,
      relays: ['wss://relay1.com', 'wss://relay2.com'],
    );

    await cacheManager.saveNip05(nip05);
    final loaded = await cacheManager.loadNip05(pubKey: 'nip05_pubkey_1');

    expect(loaded, isNotNull);
    expect(loaded!.pubKey, equals(nip05.pubKey));
    expect(loaded.nip05, equals(nip05.nip05));
    expect(loaded.valid, equals(nip05.valid));
    expect(loaded.networkFetchTime, equals(nip05.networkFetchTime));
    expect(loaded.relays, equals(nip05.relays));
  });

  test('loadNip05 by identifier', () async {
    final cacheManager = getCacheManager();
    final nip05 = Nip05(
      pubKey: 'nip05_id_pubkey',
      nip05: 'testuser@example.com',
      valid: true,
      networkFetchTime: 1234567890,
      relays: ['wss://relay1.com'],
    );

    await cacheManager.saveNip05(nip05);
    final loaded =
        await cacheManager.loadNip05(identifier: 'testuser@example.com');

    expect(loaded, isNotNull);
    expect(loaded!.pubKey, equals(nip05.pubKey));
    expect(loaded.nip05, equals(nip05.nip05));
    expect(loaded.valid, equals(nip05.valid));
  });

  test('saveNip05s batch operation', () async {
    final cacheManager = getCacheManager();
    final nip05s = [
      Nip05(pubKey: 'nip05_batch_1', nip05: 'user1@example.com', valid: true),
      Nip05(pubKey: 'nip05_batch_2', nip05: 'user2@example.com', valid: false),
    ];

    await cacheManager.saveNip05s(nip05s);

    for (final nip05 in nip05s) {
      final loaded = await cacheManager.loadNip05(pubKey: nip05.pubKey);
      expect(loaded, isNotNull);
      expect(loaded!.nip05, equals(nip05.nip05));
      expect(loaded.valid, equals(nip05.valid));
    }
  });

  test('loadNip05s batch operation', () async {
    final cacheManager = getCacheManager();
    final nip05s = [
      Nip05(pubKey: 'nip05_load_1', nip05: 'user1@example.com', valid: true),
      Nip05(pubKey: 'nip05_load_2', nip05: 'user2@example.com', valid: false),
    ];

    await cacheManager.saveNip05s(nip05s);
    final loaded = await cacheManager.loadNip05s([
      'nip05_load_1',
      'nip05_load_2',
      'nonexistent',
    ]);

    expect(loaded.length, equals(3));
    expect(loaded[0]?.nip05, equals('user1@example.com'));
    expect(loaded[1]?.nip05, equals('user2@example.com'));
    expect(loaded[2], isNull);
  });

  test('removeNip05', () async {
    final cacheManager = getCacheManager();
    final nip05 = Nip05(
      pubKey: 'nip05_remove',
      nip05: 'test@example.com',
      valid: true,
    );

    await cacheManager.saveNip05(nip05);
    expect(await cacheManager.loadNip05(pubKey: 'nip05_remove'), isNotNull);

    await cacheManager.removeNip05('nip05_remove');
    expect(await cacheManager.loadNip05(pubKey: 'nip05_remove'), isNull);
  });

  test('removeAllNip05s', () async {
    final cacheManager = getCacheManager();
    final nip05s = [
      Nip05(pubKey: 'nip05_clear_1', nip05: 'u1@ex.com', valid: true),
      Nip05(pubKey: 'nip05_clear_2', nip05: 'u2@ex.com', valid: false),
    ];

    await cacheManager.saveNip05s(nip05s);
    await cacheManager.removeAllNip05s();

    for (final nip05 in nip05s) {
      expect(await cacheManager.loadNip05(pubKey: nip05.pubKey), isNull);
    }
  });
}

// ============================================================================
// UserRelayList Tests
// ============================================================================

void _runUserRelayListTests(CacheManager Function() getCacheManager) {
  test('saveUserRelayList and loadUserRelayList', () async {
    final cacheManager = getCacheManager();
    final userRelayList = UserRelayList(
      pubKey: 'relay_list_pubkey_1',
      createdAt: 1234567890,
      refreshedTimestamp: 1234567895,
      relays: {
        'wss://relay1.com': ReadWriteMarker.readWrite,
        'wss://relay2.com': ReadWriteMarker.readOnly,
        'wss://relay3.com': ReadWriteMarker.writeOnly,
      },
    );

    await cacheManager.saveUserRelayList(userRelayList);
    final loaded = await cacheManager.loadUserRelayList('relay_list_pubkey_1');

    expect(loaded, isNotNull);
    expect(loaded!.pubKey, equals(userRelayList.pubKey));
    expect(loaded.createdAt, equals(userRelayList.createdAt));
    expect(loaded.relays.length, equals(3));
    expect(
        loaded.relays['wss://relay1.com'], equals(ReadWriteMarker.readWrite));
    expect(loaded.relays['wss://relay2.com'], equals(ReadWriteMarker.readOnly));
    expect(
        loaded.relays['wss://relay3.com'], equals(ReadWriteMarker.writeOnly));
  });

  test('saveUserRelayLists batch operation', () async {
    final cacheManager = getCacheManager();
    final userRelayLists = [
      UserRelayList(
        pubKey: 'relay_batch_1',
        createdAt: 1234567890,
        refreshedTimestamp: 1234567890,
        relays: {'wss://relay1.com': ReadWriteMarker.readWrite},
      ),
      UserRelayList(
        pubKey: 'relay_batch_2',
        createdAt: 1234567891,
        refreshedTimestamp: 1234567891,
        relays: {'wss://relay2.com': ReadWriteMarker.readOnly},
      ),
    ];

    await cacheManager.saveUserRelayLists(userRelayLists);

    for (final userRelayList in userRelayLists) {
      final loaded = await cacheManager.loadUserRelayList(userRelayList.pubKey);
      expect(loaded, isNotNull);
      expect(loaded!.relays.length, equals(1));
    }
  });

  test('removeUserRelayList', () async {
    final cacheManager = getCacheManager();
    final userRelayList = UserRelayList(
      pubKey: 'relay_remove',
      createdAt: 1234567890,
      refreshedTimestamp: 1234567890,
      relays: {'wss://relay.com': ReadWriteMarker.readWrite},
    );

    await cacheManager.saveUserRelayList(userRelayList);
    expect(await cacheManager.loadUserRelayList('relay_remove'), isNotNull);

    await cacheManager.removeUserRelayList('relay_remove');
    expect(await cacheManager.loadUserRelayList('relay_remove'), isNull);
  });

  test('removeAllUserRelayLists', () async {
    final cacheManager = getCacheManager();
    final userRelayLists = [
      UserRelayList(
        pubKey: 'relay_clear_1',
        createdAt: 1234567890,
        refreshedTimestamp: 1234567890,
        relays: {},
      ),
      UserRelayList(
        pubKey: 'relay_clear_2',
        createdAt: 1234567891,
        refreshedTimestamp: 1234567891,
        relays: {},
      ),
    ];

    await cacheManager.saveUserRelayLists(userRelayLists);
    await cacheManager.removeAllUserRelayLists();

    for (final userRelayList in userRelayLists) {
      expect(
          await cacheManager.loadUserRelayList(userRelayList.pubKey), isNull);
    }
  });
}

// ============================================================================
// RelaySet Tests
// ============================================================================

void _runRelaySetTests(CacheManager Function() getCacheManager) {
  test('saveRelaySet and loadRelaySet', () async {
    final cacheManager = getCacheManager();
    final relaySet = RelaySet(
      name: 'test_set',
      pubKey: 'relay_set_pubkey_1',
      relayMinCountPerPubkey: 2,
      direction: RelayDirection.outbox,
      relaysMap: {
        'wss://relay1.com': [
          PubkeyMapping(pubKey: 'user1', rwMarker: ReadWriteMarker.readWrite),
          PubkeyMapping(pubKey: 'user2', rwMarker: ReadWriteMarker.readOnly),
        ],
        'wss://relay2.com': [
          PubkeyMapping(pubKey: 'user3', rwMarker: ReadWriteMarker.writeOnly),
        ],
      },
      notCoveredPubkeys: [],
      fallbackToBootstrapRelays: true,
    );

    await cacheManager.saveRelaySet(relaySet);
    final loaded =
        await cacheManager.loadRelaySet('test_set', 'relay_set_pubkey_1');

    expect(loaded, isNotNull);
    expect(loaded!.name, equals(relaySet.name));
    expect(loaded.pubKey, equals(relaySet.pubKey));
    expect(loaded.relayMinCountPerPubkey, equals(2));
    expect(loaded.direction, equals(RelayDirection.outbox));
    expect(loaded.relaysMap.length, equals(2));
    expect(loaded.relaysMap['wss://relay1.com']?.length, equals(2));
  });

  test('removeRelaySet', () async {
    final cacheManager = getCacheManager();
    final relaySet = RelaySet(
      name: 'set_to_remove',
      pubKey: 'relay_set_remove',
      relayMinCountPerPubkey: 1,
      direction: RelayDirection.inbox,
      relaysMap: {},
      notCoveredPubkeys: [],
    );

    await cacheManager.saveRelaySet(relaySet);
    expect(
      await cacheManager.loadRelaySet('set_to_remove', 'relay_set_remove'),
      isNotNull,
    );

    await cacheManager.removeRelaySet('set_to_remove', 'relay_set_remove');
    expect(
      await cacheManager.loadRelaySet('set_to_remove', 'relay_set_remove'),
      isNull,
    );
  });

  test('removeAllRelaySets', () async {
    final cacheManager = getCacheManager();
    final relaySets = [
      RelaySet(
        name: 'set_clear_1',
        pubKey: 'relay_set_clear_1',
        relayMinCountPerPubkey: 1,
        direction: RelayDirection.inbox,
        relaysMap: {},
        notCoveredPubkeys: [],
      ),
      RelaySet(
        name: 'set_clear_2',
        pubKey: 'relay_set_clear_2',
        relayMinCountPerPubkey: 1,
        direction: RelayDirection.outbox,
        relaysMap: {},
        notCoveredPubkeys: [],
      ),
    ];

    for (final relaySet in relaySets) {
      await cacheManager.saveRelaySet(relaySet);
    }
    await cacheManager.removeAllRelaySets();

    for (final relaySet in relaySets) {
      expect(
        await cacheManager.loadRelaySet(relaySet.name, relaySet.pubKey),
        isNull,
      );
    }
  });
}

// ============================================================================
// Search Tests
// ============================================================================

void _runSearchTests(CacheManager Function() getCacheManager) {
  test('searchMetadatas by name', () async {
    final cacheManager = getCacheManager();
    await cacheManager.removeAllMetadatas();

    final metadatas = [
      Metadata(
          pubKey: 'search_meta_1', name: 'Alice Smith', displayName: 'Alice'),
      Metadata(
          pubKey: 'search_meta_2', name: 'Bob Jones', displayName: 'Bobby'),
      Metadata(
          pubKey: 'search_meta_3',
          name: 'Alice Wonder',
          nip05: 'alice@example.com'),
    ];

    await cacheManager.saveMetadatas(metadatas);

    final aliceResults = await cacheManager.searchMetadatas('Alice', 10);
    expect(aliceResults.length, greaterThanOrEqualTo(2));
    expect(
        aliceResults.every((m) =>
            m.name?.toLowerCase().contains('alice') == true ||
            m.displayName?.toLowerCase().contains('alice') == true ||
            m.nip05?.toLowerCase().contains('alice') == true),
        isTrue);
  });

  test('searchMetadatas with limit', () async {
    final cacheManager = getCacheManager();
    await cacheManager.removeAllMetadatas();

    final metadatas = List.generate(
      5,
      (i) => Metadata(pubKey: 'search_limit_$i', name: 'User $i'),
    );

    await cacheManager.saveMetadatas(metadatas);

    final results = await cacheManager.searchMetadatas('User', 2);
    expect(results.length, lessThanOrEqualTo(2));
  });
}

// ============================================================================
// ClearAll Tests
// ============================================================================

void _runClearAllTests(CacheManager Function() getCacheManager) {
  test('clearAll removes all cached data', () async {
    final cacheManager = getCacheManager();

    // Save data to all cache types
    final event = Nip01Event(
      pubKey: 'clearall_event_pubkey',
      kind: 1,
      tags: [],
      content: 'Test event',
      createdAt: 1234567890,
    );
    await cacheManager.saveEvent(event);

    final metadata = Metadata(pubKey: 'clearall_metadata_pubkey', name: 'Test');
    await cacheManager.saveMetadata(metadata);

    final contactList = ContactList(
      pubKey: 'clearall_contact_pubkey',
      contacts: ['contact1'],
    );
    await cacheManager.saveContactList(contactList);

    final nip05 = Nip05(
      pubKey: 'clearall_nip05_pubkey',
      nip05: 'test@example.com',
      valid: true,
    );
    await cacheManager.saveNip05(nip05);

    final userRelayList = UserRelayList(
      pubKey: 'clearall_relay_pubkey',
      createdAt: 1234567890,
      refreshedTimestamp: 1234567890,
      relays: {'wss://relay.com': ReadWriteMarker.readWrite},
    );
    await cacheManager.saveUserRelayList(userRelayList);

    final relaySet = RelaySet(
      name: 'clearall_set',
      pubKey: 'clearall_relayset_pubkey',
      relayMinCountPerPubkey: 1,
      direction: RelayDirection.inbox,
      relaysMap: {},
      notCoveredPubkeys: [],
    );
    await cacheManager.saveRelaySet(relaySet);

    // Verify data exists
    expect(await cacheManager.loadEvent(event.id), isNotNull);
    expect(
        await cacheManager.loadMetadata('clearall_metadata_pubkey'), isNotNull);
    expect(await cacheManager.loadContactList('clearall_contact_pubkey'),
        isNotNull);
    expect(await cacheManager.loadNip05(pubKey: 'clearall_nip05_pubkey'),
        isNotNull);
    expect(await cacheManager.loadUserRelayList('clearall_relay_pubkey'),
        isNotNull);
    expect(
        await cacheManager.loadRelaySet(
            'clearall_set', 'clearall_relayset_pubkey'),
        isNotNull);

    // Clear all
    await cacheManager.clearAll();

    // Verify all data is removed
    expect(await cacheManager.loadEvent(event.id), isNull);
    expect(await cacheManager.loadMetadata('clearall_metadata_pubkey'), isNull);
    expect(
        await cacheManager.loadContactList('clearall_contact_pubkey'), isNull);
    expect(
        await cacheManager.loadNip05(pubKey: 'clearall_nip05_pubkey'), isNull);
    expect(
        await cacheManager.loadUserRelayList('clearall_relay_pubkey'), isNull);
    expect(
        await cacheManager.loadRelaySet(
            'clearall_set', 'clearall_relayset_pubkey'),
        isNull);
  });
}
