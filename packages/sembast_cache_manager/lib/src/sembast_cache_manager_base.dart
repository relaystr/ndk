import 'dart:async';
import 'package:ndk/domain_layer/entities/nip_05.dart';
import 'package:ndk/domain_layer/entities/user_relay_list.dart';
import 'package:ndk/ndk.dart';
import 'package:sembast/sembast.dart' as sembast;
import 'ndk_extensions.dart';

class SembastCacheManager extends CacheManager {
  final sembast.Database _database;
  
  late final sembast.StoreRef<String, Map<String, Object?>> _eventsStore;
  late final sembast.StoreRef<String, Map<String, Object?>> _metadataStore;
  late final sembast.StoreRef<String, Map<String, Object?>> _contactListStore;
  late final sembast.StoreRef<String, Map<String, Object?>> _relayListStore;
  late final sembast.StoreRef<String, Map<String, Object?>> _nip05Store;
  late final sembast.StoreRef<String, Map<String, Object?>> _relaySetStore;

  SembastCacheManager(this._database) {
    _eventsStore = sembast.stringMapStoreFactory.store('events');
    _metadataStore = sembast.stringMapStoreFactory.store('metadata');
    _contactListStore = sembast.stringMapStoreFactory.store('contact_lists');
    _relayListStore = sembast.stringMapStoreFactory.store('relay_lists');
    _nip05Store = sembast.stringMapStoreFactory.store('nip05');
    _relaySetStore = sembast.stringMapStoreFactory.store('relay_sets');
  }
  
  @override
  Future<void> close() async {
    await _database.close();
  }
  
  @override
  Future<ContactList?> loadContactList(String pubKey) async {
    final data = await _contactListStore.record(pubKey).get(_database);
    if (data == null) return null;
    return ContactListExtension.fromJsonStorage(data);
  }
  
  @override
  Future<Nip01Event?> loadEvent(String id) async {
    final data = await _eventsStore.record(id).get(_database);
    if (data == null) return null;
    return Nip01EventExtension.fromJsonStorage(data);
  }
  
  @override
  Future<List<Nip01Event>> loadEvents({List<String>? pubKeys, List<int>? kinds, String? pTag, int? since, int? until}) async {
    var finder = sembast.Finder();
    
    // Build filter conditions
    final filters = <sembast.Filter>[];
    
    if (pubKeys != null && pubKeys.isNotEmpty) {
      filters.add(sembast.Filter.inList('pubkey', pubKeys));
    }
    
    if (kinds != null && kinds.isNotEmpty) {
      filters.add(sembast.Filter.inList('kind', kinds));
    }
    
    if (since != null) {
      filters.add(sembast.Filter.greaterThanOrEquals('created_at', since));
    }
    
    if (until != null) {
      filters.add(sembast.Filter.lessThanOrEquals('created_at', until));
    }
    
    if (filters.isNotEmpty) {
      finder = sembast.Finder(filter: sembast.Filter.and(filters));
    }
    
    final records = await _eventsStore.find(_database, finder: finder);
    final events = records.map((record) => Nip01EventExtension.fromJsonStorage(record.value)).toList();
    
    // Filter by pTag if specified
    if (pTag != null) {
      return events.where((event) => event.pTags.contains(pTag)).toList();
    }
    
    return events;
  }
  
  @override
  Future<Metadata?> loadMetadata(String pubKey) async {
    final data = await _metadataStore.record(pubKey).get(_database);
    if (data == null) return null;
    return MetadataExtension.fromJsonStorage(data);
  }
  
  @override
  Future<List<Metadata?>> loadMetadatas(List<String> pubKeys) async {
    final metadatas = <Metadata?>[];
    for (final pubKey in pubKeys) {
      final metadata = await loadMetadata(pubKey);
      metadatas.add(metadata);
    }
    return metadatas;
  }
  
  @override
  Future<Nip05?> loadNip05(String pubKey) async {
    final data = await _nip05Store.record(pubKey).get(_database);
    if (data == null) return null;
    return Nip05Extension.fromJsonStorage(data);
  }
  
  @override
  Future<List<Nip05?>> loadNip05s(List<String> pubKeys) async {
    final nip05s = <Nip05?>[];
    for (final pubKey in pubKeys) {
      final nip05 = await loadNip05(pubKey);
      nip05s.add(nip05);
    }
    return nip05s;
  }
  
  @override
  Future<RelaySet?> loadRelaySet(String name, String pubKey) async {
    final key = '${pubKey}_$name';
    final data = await _relaySetStore.record(key).get(_database);
    if (data == null) return null;
    return RelaySetExtension.fromJsonStorage(data);
  }
  
  @override
  Future<UserRelayList?> loadUserRelayList(String pubKey) async {
    final data = await _relayListStore.record(pubKey).get(_database);
    if (data == null) return null;
    return UserRelayListExtension.fromJsonStorage(data);
  }
  
  @override
  Future<void> removeAllContactLists() async {
    await _contactListStore.delete(_database);
  }
  
  @override
  Future<void> removeAllEvents() async {
    await _eventsStore.delete(_database);
  }
  
  @override
  Future<void> removeAllEventsByPubKey(String pubKey) async {
    final finder = sembast.Finder(filter: sembast.Filter.equals('pubkey', pubKey));
    await _eventsStore.delete(_database, finder: finder);
  }
  
  @override
  Future<void> removeAllMetadatas() async {
    await _metadataStore.delete(_database);
  }
  
  @override
  Future<void> removeAllNip05s() async {
    await _nip05Store.delete(_database);
  }
  
  @override
  Future<void> removeAllRelaySets() async {
    await _relaySetStore.delete(_database);
  }
  
  @override
  Future<void> removeAllUserRelayLists() async {
    await _relayListStore.delete(_database);
  }
  
  @override
  Future<void> removeContactList(String pubKey) async {
    await _contactListStore.record(pubKey).delete(_database);
  }
  
  @override
  Future<void> removeEvent(String id) async {
    await _eventsStore.record(id).delete(_database);
  }
  
  @override
  Future<void> removeMetadata(String pubKey) async {
    await _metadataStore.record(pubKey).delete(_database);
  }
  
  @override
  Future<void> removeNip05(String pubKey) async {
    await _nip05Store.record(pubKey).delete(_database);
  }
  
  @override
  Future<void> removeRelaySet(String name, String pubKey) async {
    final key = '${pubKey}_$name';
    await _relaySetStore.record(key).delete(_database);
  }
  
  @override
  Future<void> removeUserRelayList(String pubKey) async {
    await _relayListStore.record(pubKey).delete(_database);
  }
  
  @override
  Future<void> saveContactList(ContactList contactList) async {
    await _contactListStore.record(contactList.pubKey).put(_database, contactList.toJsonForStorage());
  }
  
  @override
  Future<void> saveContactLists(List<ContactList> contactLists) async {
    await _database.transaction((txn) async {
      for (final contactList in contactLists) {
        await _contactListStore.record(contactList.pubKey).put(txn, contactList.toJsonForStorage());
      }
    });
  }
  
  @override
  Future<void> saveEvent(Nip01Event event) async {
    await _eventsStore.record(event.id).put(_database, event.toJsonForStorage());
  }
  
  @override
  Future<void> saveEvents(List<Nip01Event> events) async {
    await _database.transaction((txn) async {
      for (final event in events) {
        await _eventsStore.record(event.id).put(txn, event.toJsonForStorage());
      }
    });
  }
  
  @override
  Future<void> saveMetadata(Metadata metadata) async {
    await _metadataStore.record(metadata.pubKey).put(_database, metadata.toJsonForStorage());
  }
  
  @override
  Future<void> saveMetadatas(List<Metadata> metadatas) async {
    await _database.transaction((txn) async {
      for (final metadata in metadatas) {
        await _metadataStore.record(metadata.pubKey).put(txn, metadata.toJsonForStorage());
      }
    });
  }
  
  @override
  Future<void> saveNip05(Nip05 nip05) async {
    await _nip05Store.record(nip05.pubKey).put(_database, nip05.toJsonForStorage());
  }
  
  @override
  Future<void> saveNip05s(List<Nip05> nip05s) async {
    await _database.transaction((txn) async {
      for (final nip05 in nip05s) {
        await _nip05Store.record(nip05.pubKey).put(txn, nip05.toJsonForStorage());
      }
    });
  }
  
  @override
  Future<void> saveRelaySet(RelaySet relaySet) async {
    final key = '${relaySet.pubKey}_${relaySet.name}';
    await _relaySetStore.record(key).put(_database, relaySet.toJsonForStorage());
  }
  
  @override
  Future<void> saveUserRelayList(UserRelayList userRelayList) async {
    await _relayListStore.record(userRelayList.pubKey).put(_database, userRelayList.toJsonForStorage());
  }
  
  @override
  Future<void> saveUserRelayLists(List<UserRelayList> userRelayLists) async {
    await _database.transaction((txn) async {
      for (final userRelayList in userRelayLists) {
        await _relayListStore.record(userRelayList.pubKey).put(txn, userRelayList.toJsonForStorage());
      }
    });
  }
  
  @override
  Future<Iterable<Nip01Event>> searchEvents({List<String>? ids, List<String>? authors, List<int>? kinds, Map<String, List<String>>? tags, int? since, int? until, String? search, int limit = 100}) async {
    var finder = sembast.Finder(limit: limit);
    
    // Build filter conditions
    final filters = <sembast.Filter>[];
    
    // Filter by event IDs
    if (ids != null && ids.isNotEmpty) {
      filters.add(sembast.Filter.inList('id', ids));
    }
    
    // Filter by authors (pubkeys)
    if (authors != null && authors.isNotEmpty) {
      filters.add(sembast.Filter.inList('pubkey', authors));
    }
    
    // Filter by kinds
    if (kinds != null && kinds.isNotEmpty) {
      filters.add(sembast.Filter.inList('kind', kinds));
    }
    
    // Filter by time range
    if (since != null) {
      filters.add(sembast.Filter.greaterThanOrEquals('created_at', since));
    }
    
    if (until != null) {
      filters.add(sembast.Filter.lessThanOrEquals('created_at', until));
    }
    
    // Filter by content search
    if (search != null && search.isNotEmpty) {
      filters.add(sembast.Filter.matches('content', search));
    }
    
    // Apply filters
    if (filters.isNotEmpty) {
      finder = sembast.Finder(
        filter: sembast.Filter.and(filters),
        limit: limit,
        sortOrders: [sembast.SortOrder('created_at', false)], // Sort by newest first
      );
    } else {
      finder = sembast.Finder(
        limit: limit,
        sortOrders: [sembast.SortOrder('created_at', false)],
      );
    }
    
    final records = await _eventsStore.find(_database, finder: finder);
    final events = records.map((record) => Nip01EventExtension.fromJsonStorage(record.value)).toList();
    
    // Filter by tags if specified (done in memory since Sembast doesn't support complex tag filtering)
    if (tags != null && tags.isNotEmpty) {
      return events.where((event) {
        return tags.entries.every((tagEntry) {
          final tagName = tagEntry.key;
          final tagValues = tagEntry.value;
          final eventTags = event.getTags(tagName);
          return tagValues.any((value) => eventTags.contains(value.toLowerCase()));
        });
      });
    }
    
    return events;
  }
  
  @override
  Future<Iterable<Metadata>> searchMetadatas(String search, int limit) async {
    final finder = sembast.Finder(
      limit: limit,
      sortOrders: [sembast.SortOrder('updatedAt', false)], // Sort by most recently updated
    );
    
    final records = await _metadataStore.find(_database, finder: finder);
    final metadatas = records
        .map((record) => MetadataExtension.fromJsonStorage(record.value))
        .toList();
    
    // Filter by search term in memory (search in name, displayName, about, nip05)
    if (search.isNotEmpty) {
      final searchLower = search.toLowerCase();
      return metadatas.where((metadata) {
        return (metadata.name?.toLowerCase().contains(searchLower) ?? false) ||
               (metadata.displayName?.toLowerCase().contains(searchLower) ?? false) ||
               (metadata.about?.toLowerCase().contains(searchLower) ?? false) ||
               (metadata.nip05?.toLowerCase().contains(searchLower) ?? false);
      });
    }
    
    return metadatas;
  }
}
