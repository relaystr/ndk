import 'dart:async';
import 'dart:io';
import 'package:ndk/domain_layer/entities/nip_05.dart';
import 'package:ndk/domain_layer/entities/user_relay_list.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:sembast/sembast.dart' as sembast;
import 'package:sembast/sembast_io.dart';
import 'ndk_extensions.dart';
import 'package:path/path.dart' as p;

class SembastCacheManager extends CacheManager {
  static Future<SembastCacheManager> create({
    required String databasePath,
    String databaseName = "sembast_cache_manager",
  }) async {
    final dbFileName = "$databaseName.db";
    final dbPath = p.join(databasePath, dbFileName);

    await Directory(databasePath).create(recursive: true);

    final database = await databaseFactoryIo.openDatabase(dbPath);
    return SembastCacheManager(database);
  }

  final sembast.Database _database;

  late final sembast.StoreRef<String, Map<String, Object?>> _eventsStore;
  late final sembast.StoreRef<String, Map<String, Object?>> _metadataStore;
  late final sembast.StoreRef<String, Map<String, Object?>> _contactListStore;
  late final sembast.StoreRef<String, Map<String, Object?>> _relayListStore;
  late final sembast.StoreRef<String, Map<String, Object?>> _nip05Store;
  late final sembast.StoreRef<String, Map<String, Object?>> _relaySetStore;
  late final sembast.StoreRef<String, Map<String, Object?>>
      _filterFetchedRangeStore;

  late final sembast.StoreRef<String, Map<String, Object?>> _keysetStore;
  late final sembast.StoreRef<String, Map<String, Object?>> _proofStore;
  late final sembast.StoreRef<String, Map<String, Object?>> _transactionStore;
  late final sembast.StoreRef<String, Map<String, Object?>> _walletStore;
  late final sembast.StoreRef<String, Map<String, Object?>> _mintInfoStore;
  late final sembast.StoreRef<String, Map<String, Object?>> _secretCounterStore;

  SembastCacheManager(this._database) {
    _eventsStore = sembast.stringMapStoreFactory.store('events');
    _metadataStore = sembast.stringMapStoreFactory.store('metadata');
    _contactListStore = sembast.stringMapStoreFactory.store('contact_lists');
    _relayListStore = sembast.stringMapStoreFactory.store('relay_lists');
    _nip05Store = sembast.stringMapStoreFactory.store('nip05');
    _relaySetStore = sembast.stringMapStoreFactory.store('relay_sets');
    _keysetStore = sembast.stringMapStoreFactory.store('keysets');
    _proofStore = sembast.stringMapStoreFactory.store('proofs');
    _transactionStore = sembast.stringMapStoreFactory.store('transactions');
    _walletStore = sembast.stringMapStoreFactory.store('wallets');
    _mintInfoStore = sembast.stringMapStoreFactory.store('mint_infos');
    _secretCounterStore =
        sembast.stringMapStoreFactory.store('secret_counters');
    _filterFetchedRangeStore =
        sembast.stringMapStoreFactory.store('filter_fetched_ranges');
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
  Future<List<Nip01Event>> loadEvents({
    List<String>? ids,
    List<String>? pubKeys,
    List<int>? kinds,
    Map<String, List<String>>? tags,
    int? since,
    int? until,
    String? search,
    int? limit,
  }) async {
    // Build filter conditions
    final filters = <sembast.Filter>[];

    // Filter by event IDs
    if (ids != null && ids.isNotEmpty) {
      filters.add(sembast.Filter.inList('id', ids));
    }

    // Filter by authors (pubkeys)
    if (pubKeys != null && pubKeys.isNotEmpty) {
      filters.add(sembast.Filter.inList('pubkey', pubKeys));
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

    final finder = sembast.Finder(
      filter: filters.isNotEmpty ? sembast.Filter.and(filters) : null,
      limit: limit,
      sortOrders: [sembast.SortOrder('created_at', false)],
    );

    final records = await _eventsStore.find(_database, finder: finder);
    final events = records
        .map((record) => Nip01EventExtension.fromJsonStorage(record.value))
        .toList();

    // Filter by tags if specified (done in memory since Sembast doesn't support complex tag filtering)
    if (tags != null && tags.isNotEmpty) {
      return events.where((event) {
        return tags.entries.every((tagEntry) {
          var tagName = tagEntry.key;
          final tagValues = tagEntry.value;

          // Handle the special case where tag key starts with '#'
          if (tagName.startsWith('#') && tagName.length > 1) {
            tagName = tagName.substring(1);
          }

          final eventTags = event.getTags(tagName);

          if (tagValues.isEmpty &&
              event.tags.where((e) => e[0] == tagName).isNotEmpty) {
            return true;
          }

          return tagValues.any(
            (value) => eventTags.contains(value.toLowerCase()),
          );
        });
      }).toList();
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
    final snapshots = await _metadataStore.records(pubKeys).get(_database);
    return snapshots.map((data) {
      if (data == null) return null;
      return MetadataExtension.fromJsonStorage(data);
    }).toList();
  }

  @override
  Future<Nip05?> loadNip05({String? pubKey, String? identifier}) async {
    if (pubKey != null) {
      final data = await _nip05Store.record(pubKey).get(_database);
      if (data == null) return null;
      return Nip05Extension.fromJsonStorage(data);
    }
    if (identifier != null) {
      final finder = sembast.Finder(
        filter: sembast.Filter.equals('nip05', identifier),
      );
      final record = await _nip05Store.findFirst(_database, finder: finder);
      if (record == null) return null;
      return Nip05Extension.fromJsonStorage(record.value);
    }
    return null;
  }

  @override
  Future<List<Nip05?>> loadNip05s(List<String> pubKeys) async {
    final snapshots = await _nip05Store.records(pubKeys).get(_database);
    return snapshots.map((data) {
      if (data == null) return null;
      return Nip05Extension.fromJsonStorage(data);
    }).toList();
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
    final finder = sembast.Finder(
      filter: sembast.Filter.equals('pubkey', pubKey),
    );
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
  Future<void> removeEvents({
    List<String>? ids,
    List<String>? pubKeys,
    List<int>? kinds,
    Map<String, List<String>>? tags,
    int? since,
    int? until,
  }) async {
    // If all parameters are empty, return early (don't delete everything)
    if ((ids == null || ids.isEmpty) &&
        (pubKeys == null || pubKeys.isEmpty) &&
        (kinds == null || kinds.isEmpty) &&
        (tags == null || tags.isEmpty) &&
        since == null &&
        until == null) {
      return;
    }

    // Build filter conditions
    final filters = <sembast.Filter>[];

    if (ids != null && ids.isNotEmpty) {
      filters.add(sembast.Filter.inList('id', ids));
    }
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

    // If tags are specified, we need to load events first and filter in memory
    if (tags != null && tags.isNotEmpty) {
      final finder = sembast.Finder(
        filter: filters.isNotEmpty ? sembast.Filter.and(filters) : null,
      );
      final records = await _eventsStore.find(_database, finder: finder);
      final events = records
          .map((record) => Nip01EventExtension.fromJsonStorage(record.value))
          .toList();

      // Filter by tags in memory
      final matchingEvents = events.where((event) {
        return tags.entries.every((tagEntry) {
          var tagName = tagEntry.key;
          final tagValues = tagEntry.value;

          if (tagName.startsWith('#') && tagName.length > 1) {
            tagName = tagName.substring(1);
          }

          final eventTags = event.getTags(tagName);

          if (tagValues.isEmpty &&
              event.tags.where((e) => e[0] == tagName).isNotEmpty) {
            return true;
          }

          return tagValues.any(
            (value) => eventTags.contains(value.toLowerCase()),
          );
        });
      }).toList();

      // Delete matching events by ID
      await _eventsStore
          .records(matchingEvents.map((e) => e.id).toList())
          .delete(_database);
    } else {
      // No tags filter, delete directly with finder
      final finder = sembast.Finder(
        filter: filters.isNotEmpty ? sembast.Filter.and(filters) : null,
      );
      await _eventsStore.delete(_database, finder: finder);
    }
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
    await _contactListStore
        .record(contactList.pubKey)
        .put(_database, contactList.toJsonForStorage());
  }

  @override
  Future<void> saveContactLists(List<ContactList> contactLists) async {
    final keys = contactLists.map((c) => c.pubKey).toList();
    final values = contactLists.map((c) => c.toJsonForStorage()).toList();
    await _contactListStore.records(keys).put(_database, values);
  }

  @override
  Future<void> saveEvent(Nip01Event event) async {
    await _eventsStore
        .record(event.id)
        .put(_database, event.toJsonForStorage());
  }

  @override
  Future<void> saveEvents(List<Nip01Event> events) async {
    final keys = events.map((e) => e.id).toList();
    final values = events.map((e) => e.toJsonForStorage()).toList();
    await _eventsStore.records(keys).put(_database, values);
  }

  @override
  Future<void> saveMetadata(Metadata metadata) async {
    await _metadataStore
        .record(metadata.pubKey)
        .put(_database, metadata.toJsonForStorage());
  }

  @override
  Future<void> saveMetadatas(List<Metadata> metadatas) async {
    final keys = metadatas.map((m) => m.pubKey).toList();
    final values = metadatas.map((m) => m.toJsonForStorage()).toList();
    await _metadataStore.records(keys).put(_database, values);
  }

  @override
  Future<void> saveNip05(Nip05 nip05) async {
    await _nip05Store
        .record(nip05.pubKey)
        .put(_database, nip05.toJsonForStorage());
  }

  @override
  Future<void> saveNip05s(List<Nip05> nip05s) async {
    final keys = nip05s.map((n) => n.pubKey).toList();
    final values = nip05s.map((n) => n.toJsonForStorage()).toList();
    await _nip05Store.records(keys).put(_database, values);
  }

  @override
  Future<void> saveRelaySet(RelaySet relaySet) async {
    final key = '${relaySet.pubKey}_${relaySet.name}';
    await _relaySetStore
        .record(key)
        .put(_database, relaySet.toJsonForStorage());
  }

  @override
  Future<void> saveUserRelayList(UserRelayList userRelayList) async {
    await _relayListStore
        .record(userRelayList.pubKey)
        .put(_database, userRelayList.toJsonForStorage());
  }

  @override
  Future<void> saveUserRelayLists(List<UserRelayList> userRelayLists) async {
    final keys = userRelayLists.map((u) => u.pubKey).toList();
    final values = userRelayLists.map((u) => u.toJsonForStorage()).toList();
    await _relayListStore.records(keys).put(_database, values);
  }

  @override
  @Deprecated('Use loadEvents() instead')
  Future<Iterable<Nip01Event>> searchEvents({
    List<String>? ids,
    List<String>? authors,
    List<int>? kinds,
    Map<String, List<String>>? tags,
    int? since,
    int? until,
    String? search,
    int limit = 100,
  }) async {
    return loadEvents(
      ids: ids,
      pubKeys: authors,
      kinds: kinds,
      tags: tags,
      since: since,
      until: until,
      search: search,
      limit: limit,
    );
  }

  @override
  Future<Iterable<Metadata>> searchMetadatas(String search, int limit) async {
    sembast.Filter? filter;
    if (search.isNotEmpty) {
      final pattern = RegExp.escape(search);
      filter = sembast.Filter.or([
        sembast.Filter.matchesRegExp(
            'name', RegExp(pattern, caseSensitive: false)),
        sembast.Filter.matchesRegExp(
            'displayName', RegExp(pattern, caseSensitive: false)),
        sembast.Filter.matchesRegExp(
            'about', RegExp(pattern, caseSensitive: false)),
        sembast.Filter.matchesRegExp(
            'nip05', RegExp(pattern, caseSensitive: false)),
      ]);
    }

    final finder = sembast.Finder(
      filter: filter,
      limit: limit,
      sortOrders: [sembast.SortOrder('updatedAt', false)],
    );

    final records = await _metadataStore.find(_database, finder: finder);
    return records
        .map((record) => MetadataExtension.fromJsonStorage(record.value))
        .toList();
  }

  // =====================
  // Filter Fetched Ranges
  // =====================

  @override
  Future<void> saveFilterFetchedRangeRecord(
      FilterFetchedRangeRecord record) async {
    await _filterFetchedRangeStore
        .record(record.key)
        .put(_database, record.toJson());
  }

  @override
  Future<void> saveFilterFetchedRangeRecords(
      List<FilterFetchedRangeRecord> records) async {
    final keys = records.map((r) => r.key).toList();
    final values = records.map((r) => r.toJson()).toList();
    await _filterFetchedRangeStore.records(keys).put(_database, values);
  }

  @override
  Future<List<FilterFetchedRangeRecord>> loadFilterFetchedRangeRecords(
      String filterHash) async {
    final finder = sembast.Finder(
      filter: sembast.Filter.equals('filterHash', filterHash),
    );
    final records =
        await _filterFetchedRangeStore.find(_database, finder: finder);
    return records
        .map((r) => FilterFetchedRangeRecord.fromJson(r.value))
        .toList();
  }

  @override
  Future<List<FilterFetchedRangeRecord>> loadFilterFetchedRangeRecordsByRelay(
      String filterHash, String relayUrl) async {
    final finder = sembast.Finder(
      filter: sembast.Filter.and([
        sembast.Filter.equals('filterHash', filterHash),
        sembast.Filter.equals('relayUrl', relayUrl),
      ]),
    );
    final records =
        await _filterFetchedRangeStore.find(_database, finder: finder);
    return records
        .map((r) => FilterFetchedRangeRecord.fromJson(r.value))
        .toList();
  }

  @override
  Future<List<FilterFetchedRangeRecord>>
      loadFilterFetchedRangeRecordsByRelayUrl(String relayUrl) async {
    final finder = sembast.Finder(
      filter: sembast.Filter.equals('relayUrl', relayUrl),
    );
    final records =
        await _filterFetchedRangeStore.find(_database, finder: finder);
    return records
        .map((r) => FilterFetchedRangeRecord.fromJson(r.value))
        .toList();
  }

  @override
  Future<void> removeFilterFetchedRangeRecords(String filterHash) async {
    final finder = sembast.Finder(
      filter: sembast.Filter.equals('filterHash', filterHash),
    );
    await _filterFetchedRangeStore.delete(_database, finder: finder);
  }

  @override
  Future<void> removeFilterFetchedRangeRecordsByFilterAndRelay(
      String filterHash, String relayUrl) async {
    final finder = sembast.Finder(
      filter: sembast.Filter.and([
        sembast.Filter.equals('filterHash', filterHash),
        sembast.Filter.equals('relayUrl', relayUrl),
      ]),
    );
    await _filterFetchedRangeStore.delete(_database, finder: finder);
  }

  @override
  Future<void> removeFilterFetchedRangeRecordsByRelay(String relayUrl) async {
    final finder = sembast.Finder(
      filter: sembast.Filter.equals('relayUrl', relayUrl),
    );
    await _filterFetchedRangeStore.delete(_database, finder: finder);
  }

  @override
  Future<void> removeAllFilterFetchedRangeRecords() async {
    await _filterFetchedRangeStore.delete(_database);
  }

  // =====================
  // cashu / wallets
  // =====================

  @override
  Future<List<CahsuKeyset>> getKeysets({String? mintUrl}) async {
    if (mintUrl == null || mintUrl.isEmpty) {
      // Return all keysets if no mintUrl
      final records = await _keysetStore.find(_database);
      return records
          .map((record) => CahsuKeysetExtension.fromJsonStorage(record.value))
          .toList();
    }

    final finder = sembast.Finder(
      filter: sembast.Filter.equals('mintUrl', mintUrl),
    );

    final records = await _keysetStore.find(_database, finder: finder);
    return records
        .map((record) => CahsuKeysetExtension.fromJsonStorage(record.value))
        .toList();
  }

  @override
  Future<List<CashuProof>> getProofs({
    String? mintUrl,
    String? keysetId,
    CashuProofState state = CashuProofState.unspend,
  }) async {
    final filters = <sembast.Filter>[];

    // Filter by state
    filters.add(sembast.Filter.equals('state', state.toString()));

    // Filter by keysetId if provided
    if (keysetId != null && keysetId.isNotEmpty) {
      filters.add(sembast.Filter.equals('keysetId', keysetId));
    }

    // Filter by mintUrl if provided
    if (mintUrl != null && mintUrl.isNotEmpty) {
      // Get all keysets for the mintUrl
      final keysets = await getKeysets(mintUrl: mintUrl);
      if (keysets.isEmpty) {
        return [];
      }
      final keysetIds = keysets.map((k) => k.id).toList();
      filters.add(sembast.Filter.inList('keysetId', keysetIds));
    }

    final finder = sembast.Finder(
      filter: sembast.Filter.and(filters),
      sortOrders: [sembast.SortOrder('amount')],
    );

    final records = await _proofStore.find(_database, finder: finder);
    return records
        .map((record) => CashuProofExtension.fromJsonStorage(record.value))
        .toList();
  }

  @override
  Future<void> removeProofs({
    required List<CashuProof> proofs,
    required String mintUrl,
  }) async {
    final proofSecrets = proofs.map((p) => p.secret).toList();
    final finder = sembast.Finder(
      filter: sembast.Filter.inList('secret', proofSecrets),
    );

    await _proofStore.delete(_database, finder: finder);
  }

  @override
  Future<void> saveKeyset(CahsuKeyset keyset) async {
    await _keysetStore
        .record(keyset.id)
        .put(_database, keyset.toJsonForStorage());
  }

  @override
  Future<void> saveProofs({
    required List<CashuProof> proofs,
    required String mintUrl,
  }) async {
    await _database.transaction((txn) async {
      // Remove existing proofs by secret (upsert logic)
      final secretsToCheck = proofs.map((p) => p.secret).toList();
      final finder = sembast.Finder(
        filter: sembast.Filter.inList('secret', secretsToCheck),
      );
      await _proofStore.delete(txn, finder: finder);

      // Insert new proofs
      for (final proof in proofs) {
        await _proofStore
            .record(proof.secret)
            .put(txn, proof.toJsonForStorage());
      }
    });
  }

  @override
  Future<List<WalletTransaction>> getTransactions({
    int? limit,
    int? offset,
    String? walletId,
    String? unit,
    WalletType? walletType,
  }) async {
    final filters = <sembast.Filter>[];

    if (walletId != null && walletId.isNotEmpty) {
      filters.add(sembast.Filter.equals('walletId', walletId));
    }

    if (unit != null && unit.isNotEmpty) {
      filters.add(sembast.Filter.equals('unit', unit));
    }

    if (walletType != null) {
      filters.add(sembast.Filter.equals('walletType', walletType.toString()));
    }

    final finder = sembast.Finder(
      filter: filters.isNotEmpty ? sembast.Filter.and(filters) : null,
      sortOrders: [sembast.SortOrder('transactionDate', false)],
      limit: limit,
      offset: offset,
    );

    final records = await _transactionStore.find(_database, finder: finder);
    return records
        .map((record) =>
            WalletTransactionExtension.fromJsonStorage(record.value))
        .toList();
  }

  @override
  Future<void> saveTransactions({
    required List<WalletTransaction> transactions,
  }) async {
    await _database.transaction((txn) async {
      // Remove existing transactions by id (upsert logic)
      final idsToCheck = transactions.map((t) => t.id).toList();
      final finder = sembast.Finder(
        filter: sembast.Filter.inList('id', idsToCheck),
      );
      await _transactionStore.delete(txn, finder: finder);

      // Insert new transactions
      for (final transaction in transactions) {
        await _transactionStore
            .record(transaction.id)
            .put(txn, transaction.toJsonForStorage());
      }
    });
  }

  @override
  Future<List<Wallet>?> getWallets({List<String>? ids}) async {
    if (ids == null || ids.isEmpty) {
      // Return all wallets
      final records = await _walletStore.find(_database);
      return records
          .map((record) => WalletExtension.fromJsonStorage(record.value))
          .toList();
    }

    final finder = sembast.Finder(
      filter: sembast.Filter.inList('id', ids),
    );

    final records = await _walletStore.find(_database, finder: finder);
    return records
        .map((record) => WalletExtension.fromJsonStorage(record.value))
        .toList();
  }

  @override
  Future<void> removeWallet(String walletId) async {
    await _walletStore.record(walletId).delete(_database);
  }

  @override
  Future<void> saveWallet(Wallet wallet) async {
    await _walletStore
        .record(wallet.id)
        .put(_database, wallet.toJsonForStorage());
  }

  @override
  Future<List<CashuMintInfo>?> getMintInfos({List<String>? mintUrls}) async {
    if (mintUrls == null || mintUrls.isEmpty) {
      // Return all mint infos
      final records = await _mintInfoStore.find(_database);
      return records
          .map((record) => CashuMintInfoExtension.fromJsonStorage(record.value))
          .toList();
    }

    // For Sembast, we need to filter in memory since we can't do complex array operations
    final allRecords = await _mintInfoStore.find(_database);
    final allMintInfos = allRecords
        .map((record) => CashuMintInfoExtension.fromJsonStorage(record.value))
        .toList();

    // Filter by URLs
    return allMintInfos.where((mintInfo) {
      return mintUrls.any((url) => mintInfo.urls.contains(url));
    }).toList();
  }

  @override
  Future<void> saveMintInfo({required CashuMintInfo mintInfo}) async {
    // Use the first URL as the key for upsert logic
    final key = mintInfo.urls.first;

    // Remove existing mint info with the same URL
    final allRecords = await _mintInfoStore.find(_database);
    for (final record in allRecords) {
      final existingMintInfo =
          CashuMintInfoExtension.fromJsonStorage(record.value);
      if (existingMintInfo.urls.contains(mintInfo.urls.first)) {
        await _mintInfoStore.record(record.key).delete(_database);
      }
    }

    // Insert new mint info
    await _mintInfoStore
        .record(key)
        .put(_database, mintInfo.toJsonForStorage());
  }

  @override
  Future<int> getCashuSecretCounter({
    required String mintUrl,
    required String keysetId,
  }) async {
    final key = '${mintUrl}_$keysetId';
    final data = await _secretCounterStore.record(key).get(_database);
    if (data == null) return 0;
    return data['counter'] as int? ?? 0;
  }

  @override
  Future<void> setCashuSecretCounter({
    required String mintUrl,
    required String keysetId,
    required int counter,
  }) async {
    final key = '${mintUrl}_$keysetId';
    await _secretCounterStore.record(key).put(_database, {
      'mintUrl': mintUrl,
      'keysetId': keysetId,
      'counter': counter,
    });
  @override
  Future<void> clearAll() async {
    await Future.wait([
      _eventsStore.delete(_database),
      _metadataStore.delete(_database),
      _contactListStore.delete(_database),
      _relayListStore.delete(_database),
      _nip05Store.delete(_database),
      _relaySetStore.delete(_database),
      _filterFetchedRangeStore.delete(_database),
    ]);
  }
}
