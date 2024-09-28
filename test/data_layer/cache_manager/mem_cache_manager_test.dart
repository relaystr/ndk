import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip05/nip05.dart';

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
      final result = cacheManager.loadUserRelayList('testPubKey');

      expect(result, equals(mockUserRelayList));
    });

    test('removeUserRelayList', () async {
      final mockUserRelayList = MockUserRelayList();
      when(mockUserRelayList.pubKey).thenReturn('testPubKey');

      await cacheManager.saveUserRelayList(mockUserRelayList);
      await cacheManager.removeUserRelayList('testPubKey');
      final result = cacheManager.loadUserRelayList('testPubKey');

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

      expect(cacheManager.loadUserRelayList('testPubKey1'), isNull);
      expect(cacheManager.loadUserRelayList('testPubKey2'), isNull);
    });
  });

  group('Nip05 tests', () {
    test('saveNip05 and loadNip05', () async {
      final mockNip05 = MockNip05();
      when(mockNip05.pubKey).thenReturn('testPubKey');

      await cacheManager.saveNip05(mockNip05);
      final result = cacheManager.loadNip05('testPubKey');

      expect(result, equals(mockNip05));
    });

    test('removeNip05', () async {
      final mockNip05 = MockNip05();
      when(mockNip05.pubKey).thenReturn('testPubKey');

      await cacheManager.saveNip05(mockNip05);
      await cacheManager.removeNip05('testPubKey');
      final result = cacheManager.loadNip05('testPubKey');

      expect(result, isNull);
    });

    test('removeAllNip05s', () async {
      final mockNip051 = MockNip05();
      final mockNip052 = MockNip05();
      when(mockNip051.pubKey).thenReturn('testPubKey1');
      when(mockNip052.pubKey).thenReturn('testPubKey2');

      await cacheManager.saveNip05s([mockNip051, mockNip052]);
      await cacheManager.removeAllNip05s();

      expect(cacheManager.loadNip05('testPubKey1'), isNull);
      expect(cacheManager.loadNip05('testPubKey2'), isNull);
    });
  });

  group('Event tests', () {
    test('saveEvent and loadEvent', () async {
      final mockEvent = MockNip01Event();
      when(mockEvent.id).thenReturn('testId');

      await cacheManager.saveEvent(mockEvent);
      final result = cacheManager.loadEvent('testId');

      expect(result, equals(mockEvent));
    });

    test('removeEvent', () async {
      final mockEvent = MockNip01Event();
      when(mockEvent.id).thenReturn('testId');

      await cacheManager.saveEvent(mockEvent);
      await cacheManager.removeEvent('testId');
      final result = cacheManager.loadEvent('testId');

      expect(result, isNull);
    });

    test('removeAllEvents', () async {
      final mockEvent1 = MockNip01Event();
      final mockEvent2 = MockNip01Event();
      when(mockEvent1.id).thenReturn('testId1');
      when(mockEvent2.id).thenReturn('testId2');

      await cacheManager.saveEvents([mockEvent1, mockEvent2]);
      await cacheManager.removeAllEvents();

      expect(cacheManager.loadEvent('testId1'), isNull);
      expect(cacheManager.loadEvent('testId2'), isNull);
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
      final result = cacheManager.loadRelaySet('testName', 'testPubKey');

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
      final result = cacheManager.loadRelaySet('testName', 'testPubKey');

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

      expect(cacheManager.loadRelaySet('testName1', 'testPubKey1'), isNull);
      expect(cacheManager.loadRelaySet('testName2', 'testPubKey2'), isNull);
    });
  });

  group('ContactList tests', () {
    test('saveContactList and loadContactList', () async {
      final mockContactList = MockContactList();
      when(mockContactList.pubKey).thenReturn('testPubKey');

      await cacheManager.saveContactList(mockContactList);
      final result = cacheManager.loadContactList('testPubKey');

      expect(result, equals(mockContactList));
    });

    test('removeContactList', () async {
      final mockContactList = MockContactList();
      when(mockContactList.pubKey).thenReturn('testPubKey');

      await cacheManager.saveContactList(mockContactList);
      await cacheManager.removeContactList('testPubKey');
      final result = cacheManager.loadContactList('testPubKey');

      expect(result, isNull);
    });

    test('removeAllContactLists', () async {
      final mockContactList1 = MockContactList();
      final mockContactList2 = MockContactList();
      when(mockContactList1.pubKey).thenReturn('testPubKey1');
      when(mockContactList2.pubKey).thenReturn('testPubKey2');

      await cacheManager.saveContactLists([mockContactList1, mockContactList2]);
      await cacheManager.removeAllContactLists();

      expect(cacheManager.loadContactList('testPubKey1'), isNull);
      expect(cacheManager.loadContactList('testPubKey2'), isNull);
    });
  });

  group('Metadata tests', () {
    test('saveMetadata and loadMetadata', () async {
      final mockMetadata = MockMetadata();
      when(mockMetadata.pubKey).thenReturn('testPubKey');

      await cacheManager.saveMetadata(mockMetadata);
      final result = cacheManager.loadMetadata('testPubKey');

      expect(result, equals(mockMetadata));
    });

    test('removeMetadata', () async {
      final mockMetadata = MockMetadata();
      when(mockMetadata.pubKey).thenReturn('testPubKey');

      await cacheManager.saveMetadata(mockMetadata);
      await cacheManager.removeMetadata('testPubKey');
      final result = cacheManager.loadMetadata('testPubKey');

      expect(result, isNull);
    });

    test('removeAllMetadatas', () async {
      final mockMetadata1 = MockMetadata();
      final mockMetadata2 = MockMetadata();
      when(mockMetadata1.pubKey).thenReturn('testPubKey1');
      when(mockMetadata2.pubKey).thenReturn('testPubKey2');

      await cacheManager.saveMetadatas([mockMetadata1, mockMetadata2]);
      await cacheManager.removeAllMetadatas();

      expect(cacheManager.loadMetadata('testPubKey1'), isNull);
      expect(cacheManager.loadMetadata('testPubKey2'), isNull);
    });

    test('loadMetadatas', () async {
      final mockMetadata1 = MockMetadata();
      final mockMetadata2 = MockMetadata();
      when(mockMetadata1.pubKey).thenReturn('testPubKey1');
      when(mockMetadata2.pubKey).thenReturn('testPubKey2');

      await cacheManager.saveMetadatas([mockMetadata1, mockMetadata2]);
      final results = cacheManager
          .loadMetadatas(['testPubKey1', 'testPubKey2', 'nonExistentKey']);

      expect(results.length, equals(2));
      expect(results[0], equals(mockMetadata1));
      expect(results[1], equals(mockMetadata2));
    });
  });
}
