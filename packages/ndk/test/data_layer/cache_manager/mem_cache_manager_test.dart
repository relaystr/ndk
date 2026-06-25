import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_cache_manager_test_suite/ndk_cache_manager_test_suite.dart';

// This will generate mock classes for our entities
@GenerateMocks(
    [UserRelayList, RelaySet, ContactList, Metadata, Nip01Event, Nip05])
import 'mem_cache_manager_test.mocks.dart';

void main() {
  late MemCacheManager cacheManager;

  setUp(() {
    cacheManager = MemCacheManager();
  });

  group('UserRelayList tests', () {
    test('saveUserRelayList and loadUserRelayList', () async {
      final mockUserRelayList = MockUserRelayList();
      when(mockUserRelayList.pubKey).thenReturn('testPubKey');

      await cacheManager.saveUserRelayList(mockUserRelayList);
      final result = await cacheManager.loadUserRelayList('testPubKey');

      expect(result, equals(mockUserRelayList));
    });

    test('removeUserRelayList', () async {
      final mockUserRelayList = MockUserRelayList();
      when(mockUserRelayList.pubKey).thenReturn('testPubKey');

      await cacheManager.saveUserRelayList(mockUserRelayList);
      await cacheManager.removeUserRelayList('testPubKey');
      final result = await cacheManager.loadUserRelayList('testPubKey');

      expect(result, isNull);
    });

    test('removeAllUserRelayLists', () async {
      final mockUserRelayList1 = MockUserRelayList();
      final mockUserRelayList2 = MockUserRelayList();
      when(mockUserRelayList1.pubKey).thenReturn('testPubKey1');
      when(mockUserRelayList2.pubKey).thenReturn('testPubKey2');

      await cacheManager
          .saveUserRelayLists([mockUserRelayList1, mockUserRelayList2]);
      await cacheManager.removeAllUserRelayLists();

      expect(await cacheManager.loadUserRelayList('testPubKey1'), isNull);
      expect(await cacheManager.loadUserRelayList('testPubKey2'), isNull);
    });
  });

  group('Nip05 tests', () {
    test('saveNip05 and loadNip05', () async {
      final mockNip05 = MockNip05();
      when(mockNip05.pubKey).thenReturn('testPubKey');
      when(mockNip05.nip05).thenReturn('test@example.com');

      await cacheManager.saveNip05(mockNip05);
      final result = await cacheManager.loadNip05(pubKey: 'testPubKey');

      expect(result, equals(mockNip05));
    });

    test('removeNip05', () async {
      final mockNip05 = MockNip05();
      when(mockNip05.pubKey).thenReturn('testPubKey');
      when(mockNip05.nip05).thenReturn('test@example.com');

      await cacheManager.saveNip05(mockNip05);
      await cacheManager.removeNip05('testPubKey');
      final result = await cacheManager.loadNip05(pubKey: 'testPubKey');

      expect(result, isNull);
    });

    test('removeAllNip05s', () async {
      final mockNip051 = MockNip05();
      final mockNip052 = MockNip05();
      when(mockNip051.pubKey).thenReturn('testPubKey1');
      when(mockNip051.nip05).thenReturn('test1@example.com');
      when(mockNip052.pubKey).thenReturn('testPubKey2');
      when(mockNip052.nip05).thenReturn('test2@example.com');

      await cacheManager.saveNip05s([mockNip051, mockNip052]);
      await cacheManager.removeAllNip05s();

      expect(await cacheManager.loadNip05(pubKey: 'testPubKey1'), isNull);
      expect(await cacheManager.loadNip05(pubKey: 'testPubKey2'), isNull);
    });
  });

  group('Event tests', () {
    test('saveEvent and loadEvent', () async {
      final event = Nip01Event(
        pubKey: 'testPubKey',
        kind: 1,
        tags: [],
        content: 'test event',
      );

      await cacheManager.saveEvent(event);
      final result = await cacheManager.loadEvent(event.id);

      expect(result, equals(event));
    });

    test('removeEvent', () async {
      final event = Nip01Event(
        pubKey: 'testPubKey',
        kind: 1,
        tags: [],
        content: 'test event',
      );

      await cacheManager.saveEvent(event);
      await cacheManager.removeEvent(event.id);
      final result = await cacheManager.loadEvent(event.id);

      expect(result, isNull);
    });

    test('removeAllEvents', () async {
      final event1 = Nip01Event(
        pubKey: 'testPubKey1',
        kind: 1,
        tags: [],
        content: 'test event 1',
      );
      final event2 = Nip01Event(
        pubKey: 'testPubKey2',
        kind: 1,
        tags: [],
        content: 'test event 2',
      );

      await cacheManager.saveEvents([event1, event2]);
      await cacheManager.removeAllEvents();

      expect(await cacheManager.loadEvent(event1.id), isNull);
      expect(await cacheManager.loadEvent(event2.id), isNull);
    });
  });

  group('DecryptedEventPayloadRecord tests', () {
    test('save and load decrypted payload record', () async {
      final record = DecryptedEventPayloadRecord(
        eventId: 'event-1',
        viewerPubKey: 'viewer-1',
        scheme: DecryptedPayloadScheme.nip44,
        status: DecryptedPayloadStatus.ready,
        plaintextContent: 'decrypted payload',
        createdAt: 100,
        updatedAt: 101,
        decryptedAt: 101,
        sourceEventPubKey: 'author-1',
        sourceEventKind: 4,
      );

      await cacheManager.saveDecryptedEventPayloadRecord(record);

      final loaded = await cacheManager.loadDecryptedEventPayloadRecord(
        eventId: 'event-1',
        viewerPubKey: 'viewer-1',
      );

      expect(loaded, isNotNull);
      expect(loaded!.plaintextContent, 'decrypted payload');
      expect(loaded.scheme, DecryptedPayloadScheme.nip44);
      expect(loaded.status, DecryptedPayloadStatus.ready);
    });

    test('removeEvent removes decrypted payload sidecar', () async {
      final event = Nip01Event(
        pubKey: 'author-1',
        kind: 4,
        tags: const [],
        content: 'ciphertext',
      );
      await cacheManager.saveEvent(event);
      await cacheManager.saveDecryptedEventPayloadRecord(
        DecryptedEventPayloadRecord(
          eventId: event.id,
          viewerPubKey: 'viewer-1',
          plaintextContent: 'plaintext',
          createdAt: 100,
          updatedAt: 100,
        ),
      );

      await cacheManager.removeEvent(event.id);

      final loaded = await cacheManager.loadDecryptedEventPayloadRecord(
        eventId: event.id,
        viewerPubKey: 'viewer-1',
      );
      expect(loaded, isNull);
    });
  });

  group('RelaySet tests', () {
    test('saveRelaySet and loadRelaySet', () async {
      final mockRelaySet = MockRelaySet();
      when(mockRelaySet.name).thenReturn('testName');
      when(mockRelaySet.pubKey).thenReturn('testPubKey');
      when(mockRelaySet.id)
          .thenReturn(RelaySet.buildId('testName', 'testPubKey'));

      await cacheManager.saveRelaySet(mockRelaySet);
      final result = await cacheManager.loadRelaySet('testName', 'testPubKey');

      expect(result, equals(mockRelaySet));
    });

    test('removeRelaySet', () async {
      final mockRelaySet = MockRelaySet();
      when(mockRelaySet.name).thenReturn('testName');
      when(mockRelaySet.pubKey).thenReturn('testPubKey');
      when(mockRelaySet.id)
          .thenReturn(RelaySet.buildId('testName', 'testPubKey'));

      await cacheManager.saveRelaySet(mockRelaySet);
      await cacheManager.removeRelaySet('testName', 'testPubKey');
      final result = await cacheManager.loadRelaySet('testName', 'testPubKey');

      expect(result, isNull);
    });

    test('removeAllRelaySets', () async {
      final mockRelaySet1 = MockRelaySet();
      final mockRelaySet2 = MockRelaySet();
      when(mockRelaySet1.name).thenReturn('testName1');
      when(mockRelaySet1.pubKey).thenReturn('testPubKey1');
      when(mockRelaySet1.id)
          .thenReturn(RelaySet.buildId('testName1', 'testPubKey1'));
      when(mockRelaySet2.name).thenReturn('testName2');
      when(mockRelaySet2.pubKey).thenReturn('testPubKey2');
      when(mockRelaySet2.id)
          .thenReturn(RelaySet.buildId('testName2', 'testPubKey2'));

      await cacheManager.saveRelaySet(mockRelaySet1);
      await cacheManager.saveRelaySet(mockRelaySet2);
      await cacheManager.removeAllRelaySets();

      expect(
          await cacheManager.loadRelaySet('testName1', 'testPubKey1'), isNull);
      expect(
          await cacheManager.loadRelaySet('testName2', 'testPubKey2'), isNull);
    });
  });

  group('ContactList tests', () {
    test('saveContactList and loadContactList', () async {
      final contactList = ContactList(
        pubKey: 'testPubKey',
        contacts: ['contact1'],
      );

      await cacheManager.saveContactList(contactList);
      final result = await cacheManager.loadContactList('testPubKey');

      expect(result, isNotNull);
      expect(result!.pubKey, equals(contactList.pubKey));
      expect(result.contacts, equals(contactList.contacts));
    });

    test('removeContactList', () async {
      final contactList = ContactList(
        pubKey: 'testPubKey',
        contacts: ['contact1'],
      );

      await cacheManager.saveContactList(contactList);
      await cacheManager.removeContactList('testPubKey');
      final result = await cacheManager.loadContactList('testPubKey');

      expect(result, isNull);
    });

    test('removeAllContactLists', () async {
      final contactList1 = ContactList(
        pubKey: 'testPubKey1',
        contacts: ['contact1'],
      );
      final contactList2 = ContactList(
        pubKey: 'testPubKey2',
        contacts: ['contact2'],
      );

      await cacheManager.saveContactLists([contactList1, contactList2]);
      await cacheManager.removeAllContactLists();

      expect(await cacheManager.loadContactList('testPubKey1'), isNull);
      expect(await cacheManager.loadContactList('testPubKey2'), isNull);
    });
  });

  group('Metadata tests', () {
    test('saveMetadata and loadMetadata', () async {
      final metadata = Metadata(
        pubKey: 'testPubKey',
        name: 'Test User',
        updatedAt: 1234,
      );

      await cacheManager.saveMetadata(metadata);
      final result = await cacheManager.loadMetadata('testPubKey');

      expect(result, isNotNull);
      expect(result!.pubKey, equals(metadata.pubKey));
      expect(result.name, equals(metadata.name));
    });

    test('removeMetadata', () async {
      final metadata = Metadata(
        pubKey: 'testPubKey',
        name: 'Test User',
        updatedAt: 1234,
      );

      await cacheManager.saveMetadata(metadata);
      await cacheManager.removeMetadata('testPubKey');
      final result = await cacheManager.loadMetadata('testPubKey');

      expect(result, isNull);
    });

    test('removeAllMetadatas', () async {
      final metadata1 = Metadata(
        pubKey: 'testPubKey1',
        name: 'User 1',
        updatedAt: 1000,
      );
      final metadata2 = Metadata(
        pubKey: 'testPubKey2',
        name: 'User 2',
        updatedAt: 2000,
      );

      await cacheManager.saveMetadatas([metadata1, metadata2]);
      await cacheManager.removeAllMetadatas();

      expect(await cacheManager.loadMetadata('testPubKey1'), isNull);
      expect(await cacheManager.loadMetadata('testPubKey2'), isNull);
    });

    test('loadMetadatas', () async {
      final metadata1 = Metadata(
        pubKey: 'testPubKey1',
        name: 'User 1',
        updatedAt: 1000,
      );
      final metadata2 = Metadata(
        pubKey: 'testPubKey2',
        name: 'User 2',
        updatedAt: 2000,
      );

      await cacheManager.saveMetadatas([metadata1, metadata2]);
      final results = await cacheManager
          .loadMetadatas(['testPubKey1', 'testPubKey2', 'nonExistentKey']);

      // Results should preserve position correspondence with input
      expect(results.length, equals(3));
      expect(results[0]?.pubKey, equals(metadata1.pubKey));
      expect(results[1]?.pubKey, equals(metadata2.pubKey));
      expect(results[2], isNull);
    });
  });

  // Run shared test suite for comprehensive coverage
  runCacheManagerTestSuite(
    name: 'MemCacheManager (Shared Suite)',
    createCacheManager: () async => MemCacheManager(),
    cleanUp: (cacheManager) async => await cacheManager.close(),
  );
}
