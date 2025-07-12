import 'dart:io';
import 'package:ndk/domain_layer/entities/nip_05.dart';
import 'package:ndk/domain_layer/entities/pubkey_mapping.dart';
import 'package:ndk/domain_layer/entities/read_write_marker.dart';
import 'package:ndk/domain_layer/entities/user_relay_list.dart';
import 'package:ndk/ndk.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:test/test.dart';
import 'package:sembast_cache_manager/sembast_cache_manager.dart';

void main() {
  group('SembastCacheManager Tests', () {
    late Database database;
    late SembastCacheManager cacheManager;
    late Directory tempDir;

    setUp(() async {
      // Create temporary directory for test database
      tempDir = await Directory.systemTemp.createTemp('sembast_cache_test_');
      final dbPath = '${tempDir.path}/test_cache.db';
      
      // Open database
      database = await databaseFactoryIo.openDatabase(dbPath);
      cacheManager = SembastCacheManager(database);
    });

    tearDown(() async {
      // Clean up
      await cacheManager.close();
      await tempDir.delete(recursive: true);
    });

    group('Event Operations', () {
      test('saveEvent and loadEvent', () async {
        final event = Nip01Event(
          pubKey: 'test_pubkey',
          kind: 1,
          tags: [['p', 'another_pubkey'], ['t', 'test']],
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
        final events = [
          Nip01Event(
            pubKey: 'pubkey1',
            kind: 1,
            tags: [],
            content: 'Event 1',
            createdAt: 1234567890,
          ),
          Nip01Event(
            pubKey: 'pubkey2',
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

      test('loadEvents with filters', () async {
        final events = [
          Nip01Event(
            pubKey: 'pubkey1',
            kind: 1,
            tags: [['p', 'target_pubkey']],
            content: 'Event 1',
            createdAt: 1234567890,
          ),
          Nip01Event(
            pubKey: 'pubkey2',
            kind: 2,
            tags: [],
            content: 'Event 2',
            createdAt: 1234567895,
          ),
          Nip01Event(
            pubKey: 'pubkey1',
            kind: 1,
            tags: [],
            content: 'Event 3',
            createdAt: 1234567900,
          ),
        ];

        await cacheManager.saveEvents(events);

        // Test pubKeys filter
        final eventsByPubkey = await cacheManager.loadEvents(pubKeys: ['pubkey1']);
        expect(eventsByPubkey.length, equals(2));
        expect(eventsByPubkey.every((e) => e.pubKey == 'pubkey1'), isTrue);

        // Test kinds filter
        final eventsByKind = await cacheManager.loadEvents(kinds: [1]);
        expect(eventsByKind.length, equals(2));
        expect(eventsByKind.every((e) => e.kind == 1), isTrue);

        // Test time range filters
        final eventsAfter = await cacheManager.loadEvents(since: 1234567895);
        expect(eventsAfter.length, equals(2));

        final eventsBefore = await cacheManager.loadEvents(until: 1234567895);
        expect(eventsBefore.length, equals(2));

        // Test pTag filter
        final eventsByPTag = await cacheManager.loadEvents(pTag: 'target_pubkey');
        expect(eventsByPTag.length, equals(1));
        expect(eventsByPTag.first.pTags.contains('target_pubkey'), isTrue);
      });

      test('searchEvents with complex filters', () async {
        final events = [
          Nip01Event(
            pubKey: 'author1',
            kind: 1,
            tags: [['t', 'bitcoin'], ['p', 'user1']],
            content: 'Bitcoin is great!',
            createdAt: 1234567890,
          ),
          Nip01Event(
            pubKey: 'author2',
            kind: 2,
            tags: [['t', 'nostr']],
            content: 'Nostr protocol discussion',
            createdAt: 1234567895,
          ),
          Nip01Event(
            pubKey: 'author1',
            kind: 1,
            tags: [['t', 'lightning']],
            content: 'Lightning network update',
            createdAt: 1234567900,
          ),
        ];

        await cacheManager.saveEvents(events);

        // Test author filter
        final eventsByAuthor = await cacheManager.searchEvents(authors: ['author1']);
        expect(eventsByAuthor.length, equals(2));

        // Test kind filter
        final eventsByKind = await cacheManager.searchEvents(kinds: [1]);
        expect(eventsByKind.length, equals(2));

        // Test content search
        final eventsByContent = await cacheManager.searchEvents(search: 'Bitcoin');
        expect(eventsByContent.length, equals(1));

        // Test tag filter
        final eventsByTag = await cacheManager.searchEvents(tags: {'t': ['bitcoin']});
        expect(eventsByTag.length, equals(1));

        // Test time range
        final eventsInRange = await cacheManager.searchEvents(since: 1234567895, until: 1234567900);
        expect(eventsInRange.length, equals(2));

        // Test limit
        final limitedEvents = await cacheManager.searchEvents(limit: 1);
        expect(limitedEvents.length, equals(1));
      });

      test('removeEvent and removeAllEvents', () async {
        final event = Nip01Event(
          pubKey: 'test_pubkey',
          kind: 1,
          tags: [],
          content: 'Test event',
        );

        await cacheManager.saveEvent(event);
        expect(await cacheManager.loadEvent(event.id), isNotNull);

        await cacheManager.removeEvent(event.id);
        expect(await cacheManager.loadEvent(event.id), isNull);

        // Test removeAllEvents
        final events = List.generate(3, (i) => Nip01Event(
          pubKey: 'pubkey$i',
          kind: 1,
          tags: [],
          content: 'Event $i',
        ));

        await cacheManager.saveEvents(events);
        await cacheManager.removeAllEvents();

        for (final event in events) {
          expect(await cacheManager.loadEvent(event.id), isNull);
        }
      });

      test('removeAllEventsByPubKey', () async {
        final events = [
          Nip01Event(pubKey: 'pubkey1', kind: 1, tags: [], content: 'Event 1'),
          Nip01Event(pubKey: 'pubkey1', kind: 1, tags: [], content: 'Event 2'),
          Nip01Event(pubKey: 'pubkey2', kind: 1, tags: [], content: 'Event 3'),
        ];

        await cacheManager.saveEvents(events);
        await cacheManager.removeAllEventsByPubKey('pubkey1');

        expect(await cacheManager.loadEvent(events[0].id), isNull);
        expect(await cacheManager.loadEvent(events[1].id), isNull);
        expect(await cacheManager.loadEvent(events[2].id), isNotNull);
      });
    });

    group('Metadata Operations', () {
      test('saveMetadata and loadMetadata', () async {
        final metadata = Metadata(
          pubKey: 'test_pubkey',
          name: 'Test User',
          displayName: 'Test Display Name',
          about: 'Test about text',
          picture: 'https://example.com/pic.jpg',
          nip05: 'test@example.com',
        );

        await cacheManager.saveMetadata(metadata);
        final loaded = await cacheManager.loadMetadata('test_pubkey');

        expect(loaded, isNotNull);
        expect(loaded!.pubKey, equals(metadata.pubKey));
        expect(loaded.name, equals(metadata.name));
        expect(loaded.displayName, equals(metadata.displayName));
        expect(loaded.about, equals(metadata.about));
        expect(loaded.nip05, equals(metadata.nip05));
      });

      test('loadMetadatas batch operation', () async {
        final metadatas = [
          Metadata(pubKey: 'pubkey1', name: 'User 1'),
          Metadata(pubKey: 'pubkey2', name: 'User 2'),
        ];

        await cacheManager.saveMetadatas(metadatas);
        final loaded = await cacheManager.loadMetadatas(['pubkey1', 'pubkey2', 'nonexistent']);

        expect(loaded.length, equals(3));
        expect(loaded[0]?.name, equals('User 1'));
        expect(loaded[1]?.name, equals('User 2'));
        expect(loaded[2], isNull);
      });

      test('searchMetadatas', () async {
        final metadatas = [
          Metadata(pubKey: 'pubkey1', name: 'Alice', displayName: 'Alice Smith', about: 'Bitcoin enthusiast'),
          Metadata(pubKey: 'pubkey2', name: 'Bob', displayName: 'Bob Jones', about: 'Nostr developer'),
          Metadata(pubKey: 'pubkey3', name: 'Carol', nip05: 'carol@bitcoin.org'),
        ];

        await cacheManager.saveMetadatas(metadatas);

        // Search by name
        final aliceResults = await cacheManager.searchMetadatas('Alice', 10);
        expect(aliceResults.length, equals(1));
        expect(aliceResults.first.name, equals('Alice'));

        // Search by about
        final bitcoinResults = await cacheManager.searchMetadatas('bitcoin', 10);
        expect(bitcoinResults.length, equals(2)); // Alice (about) and Carol (nip05)

        // Search by nip05
        final nip05Results = await cacheManager.searchMetadatas('carol@bitcoin.org', 10);
        expect(nip05Results.length, equals(1));
        expect(nip05Results.first.name, equals('Carol'));

        // Test limit
        final limitedResults = await cacheManager.searchMetadatas('', 1);
        expect(limitedResults.length, equals(1));
      });
    });

    group('ContactList Operations', () {
      test('saveContactList and loadContactList', () async {
        final contactList = ContactList(
          pubKey: 'test_pubkey',
          contacts: ['contact1', 'contact2'],
        );
        contactList.createdAt = 1234567890;
        contactList.petnames = ['Alice', 'Bob'];

        await cacheManager.saveContactList(contactList);
        final loaded = await cacheManager.loadContactList('test_pubkey');

        expect(loaded, isNotNull);
        expect(loaded!.pubKey, equals(contactList.pubKey));
        expect(loaded.contacts, equals(contactList.contacts));
        expect(loaded.createdAt, equals(contactList.createdAt));
        expect(loaded.petnames, equals(contactList.petnames));
      });

      test('saveContactLists batch operation', () async {
        final contactLists = [
          ContactList(pubKey: 'pubkey1', contacts: ['contact1']),
          ContactList(pubKey: 'pubkey2', contacts: ['contact2']),
        ];

        await cacheManager.saveContactLists(contactLists);

        for (final contactList in contactLists) {
          final loaded = await cacheManager.loadContactList(contactList.pubKey);
          expect(loaded, isNotNull);
          expect(loaded!.contacts, equals(contactList.contacts));
        }
      });
    });

    group('NIP-05 Operations', () {
      test('saveNip05 and loadNip05', () async {
        final nip05 = Nip05(
          pubKey: 'test_pubkey',
          nip05: 'test@example.com',
          valid: true,
          relays: ['wss://relay1.com', 'wss://relay2.com'],
        );

        await cacheManager.saveNip05(nip05);
        final loaded = await cacheManager.loadNip05('test_pubkey');

        expect(loaded, isNotNull);
        expect(loaded!.pubKey, equals(nip05.pubKey));
        expect(loaded.nip05, equals(nip05.nip05));
        expect(loaded.valid, equals(nip05.valid));
        expect(loaded.relays, equals(nip05.relays));
      });

      test('loadNip05s batch operation', () async {
        final nip05s = [
          Nip05(pubKey: 'pubkey1', nip05: 'user1@example.com', valid: true),
          Nip05(pubKey: 'pubkey2', nip05: 'user2@example.com', valid: false),
        ];

        await cacheManager.saveNip05s(nip05s);
        final loaded = await cacheManager.loadNip05s(['pubkey1', 'pubkey2', 'nonexistent']);

        expect(loaded.length, equals(3));
        expect(loaded[0]?.nip05, equals('user1@example.com'));
        expect(loaded[1]?.nip05, equals('user2@example.com'));
        expect(loaded[2], isNull);
      });
    });

    group('UserRelayList Operations', () {
      test('saveUserRelayList and loadUserRelayList', () async {
        final userRelayList = UserRelayList(
          pubKey: 'test_pubkey',
          createdAt: 1234567890,
          refreshedTimestamp: 1234567895,
          relays: {
            'wss://relay1.com': ReadWriteMarker.from(read: true, write: true),
            'wss://relay2.com': ReadWriteMarker.from(read: true, write: false),
          },
        );

        await cacheManager.saveUserRelayList(userRelayList);
        final loaded = await cacheManager.loadUserRelayList('test_pubkey');

        expect(loaded, isNotNull);
        expect(loaded!.pubKey, equals(userRelayList.pubKey));
        expect(loaded.createdAt, equals(userRelayList.createdAt));
        expect(loaded.relays.length, equals(2));
        expect(loaded.relays['wss://relay1.com']?.isRead, isTrue);
        expect(loaded.relays['wss://relay1.com']?.isWrite, isTrue);
        expect(loaded.relays['wss://relay2.com']?.isWrite, isFalse);
      });

      test('saveUserRelayLists batch operation', () async {
        final userRelayLists = [
          UserRelayList(
            pubKey: 'pubkey1',
            createdAt: 1234567890,
            refreshedTimestamp: 1234567890,
            relays: {'wss://relay1.com': ReadWriteMarker.from(read: true, write: true)},
          ),
          UserRelayList(
            pubKey: 'pubkey2',
            createdAt: 1234567891,
            refreshedTimestamp: 1234567891,
            relays: {'wss://relay2.com': ReadWriteMarker.from(read: true, write: false)},
          ),
        ];

        await cacheManager.saveUserRelayLists(userRelayLists);

        for (final userRelayList in userRelayLists) {
          final loaded = await cacheManager.loadUserRelayList(userRelayList.pubKey);
          expect(loaded, isNotNull);
          expect(loaded!.relays.length, equals(1));
        }
      });
    });

    group('RelaySet Operations', () {
      test('saveRelaySet and loadRelaySet', () async {
        final relaySet = RelaySet(
          name: 'test_set',
          pubKey: 'test_pubkey',
          relayMinCountPerPubkey: 2,
          direction: RelayDirection.outbox,
          relaysMap: {
            'wss://relay1.com': [
              PubkeyMapping(
                pubKey: 'user1',
                rwMarker: ReadWriteMarker.from(read: true, write: true),
              ),
            ],
          },
          notCoveredPubkeys: [],
          fallbackToBootstrapRelays: true,
        );

        await cacheManager.saveRelaySet(relaySet);
        final loaded = await cacheManager.loadRelaySet('test_set', 'test_pubkey');

        expect(loaded, isNotNull);
        expect(loaded!.name, equals(relaySet.name));
        expect(loaded.pubKey, equals(relaySet.pubKey));
        expect(loaded.direction, equals(relaySet.direction));
        expect(loaded.relaysMap.length, equals(1));
        expect(loaded.relaysMap['wss://relay1.com']?.first.pubKey, equals('user1'));
      });
    });

    group('Cleanup Operations', () {
      test('remove operations work correctly', () async {
        // Setup test data
        final event = Nip01Event(pubKey: 'test_pubkey', kind: 1, tags: [], content: 'Test');
        final metadata = Metadata(pubKey: 'test_pubkey', name: 'Test User');
        final contactList = ContactList(pubKey: 'test_pubkey', contacts: ['contact1']);
        final nip05 = Nip05(pubKey: 'test_pubkey', nip05: 'test@example.com', valid: true);
        final userRelayList = UserRelayList(
          pubKey: 'test_pubkey',
          createdAt: 1234567890,
          refreshedTimestamp: 1234567890,
          relays: {},
        );
        final relaySet = RelaySet(
          name: 'test_set',
          pubKey: 'test_pubkey',
          relayMinCountPerPubkey: 1,
          direction: RelayDirection.inbox,
          relaysMap: {},
          notCoveredPubkeys: [],
        );

        // Save all data
        await cacheManager.saveEvent(event);
        await cacheManager.saveMetadata(metadata);
        await cacheManager.saveContactList(contactList);
        await cacheManager.saveNip05(nip05);
        await cacheManager.saveUserRelayList(userRelayList);
        await cacheManager.saveRelaySet(relaySet);

        // Test individual removals
        await cacheManager.removeMetadata('test_pubkey');
        expect(await cacheManager.loadMetadata('test_pubkey'), isNull);

        await cacheManager.removeContactList('test_pubkey');
        expect(await cacheManager.loadContactList('test_pubkey'), isNull);

        await cacheManager.removeNip05('test_pubkey');
        expect(await cacheManager.loadNip05('test_pubkey'), isNull);

        await cacheManager.removeUserRelayList('test_pubkey');
        expect(await cacheManager.loadUserRelayList('test_pubkey'), isNull);

        await cacheManager.removeRelaySet('test_set', 'test_pubkey');
        expect(await cacheManager.loadRelaySet('test_set', 'test_pubkey'), isNull);

        // Test bulk removals
        await cacheManager.saveMetadata(metadata);
        await cacheManager.removeAllMetadatas();
        expect(await cacheManager.loadMetadata('test_pubkey'), isNull);

        await cacheManager.saveContactList(contactList);
        await cacheManager.removeAllContactLists();
        expect(await cacheManager.loadContactList('test_pubkey'), isNull);

        await cacheManager.saveNip05(nip05);
        await cacheManager.removeAllNip05s();
        expect(await cacheManager.loadNip05('test_pubkey'), isNull);

        await cacheManager.saveUserRelayList(userRelayList);
        await cacheManager.removeAllUserRelayLists();
        expect(await cacheManager.loadUserRelayList('test_pubkey'), isNull);

        await cacheManager.saveRelaySet(relaySet);
        await cacheManager.removeAllRelaySets();
        expect(await cacheManager.loadRelaySet('test_set', 'test_pubkey'), isNull);
      });
    });

    group('Database Operations', () {
      test('close database', () async {
        expect(() async => await cacheManager.close(), returnsNormally);
      });
    });
  });
}