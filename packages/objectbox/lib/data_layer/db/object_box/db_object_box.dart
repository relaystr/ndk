import 'dart:async';

import 'package:ndk/domain_layer/entities/wallet/wallet_transaction.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';

import 'package:ndk_objectbox/data_layer/db/object_box/schema/db_nip_05.dart';

import '../../../objectbox.g.dart';
import 'db_init_object_box.dart';
import 'schema/db_cashu_keyset.dart';
import 'schema/db_cashu_proof.dart';
import 'schema/db_contact_list.dart';
import 'schema/db_metadata.dart';
import 'schema/db_nip_01_event.dart';
import 'schema/db_user_relay_list.dart';
import 'schema/db_wallet.dart';

class DbObjectBox implements CacheManager {
  final Completer _initCompleter = Completer();
  Future get dbRdy => _initCompleter.future;
  late ObjectBoxInit _objectBox;

  /// crates objectbox db instace
  /// [attach] to attach to already open instance (e.g. for isolates)
  DbObjectBox({bool attach = false}) {
    _init(attach);
  }

  Future _init(bool attach) async {
    final objectbox;
    if (attach) {
      objectbox = await ObjectBoxInit.attach();
    } else {
      objectbox = await ObjectBoxInit.create();
    }

    _objectBox = objectbox;
    _initCompleter.complete();
  }

  close() async {
    _objectBox.store.close();
  }

  @override
  Future<ContactList?> loadContactList(String pubKey) async {
    await dbRdy;
    final contactListBox = _objectBox.store.box<DbContactList>();
    final existingContact = contactListBox
        .query(DbContactList_.pubKey.equals(pubKey))
        .order(DbContactList_.createdAt, flags: Order.descending)
        .build()
        .findFirst();
    if (existingContact == null) {
      return null;
    }
    return existingContact.toNdk();
  }

  @override
  Future<Nip01Event?> loadEvent(String id) async {
    await dbRdy;
    final eventBox = _objectBox.store.box<DbNip01Event>();
    final existingEvent =
        eventBox.query(DbNip01Event_.nostrId.equals(id)).build().findFirst();
    if (existingEvent == null) {
      return null;
    }
    return existingEvent.toNdk();
  }

  @override
  Future<List<Nip01Event>> loadEvents({
    List<String>? pubKeys,
    List<int>? kinds,
    String? pTag,
    int? since,
    int? until,
  }) async {
    await dbRdy;
    final eventBox = _objectBox.store.box<DbNip01Event>();
    var query;

    if (pubKeys != null && pubKeys.isNotEmpty) {
      query = kinds != null && kinds.isNotEmpty
          ? eventBox.query(DbNip01Event_.pubKey
              .oneOf(pubKeys)
              .and(DbNip01Event_.kind.oneOf(kinds)))
          : eventBox.query(DbNip01Event_.pubKey.oneOf(pubKeys));
    } else if (kinds != null && kinds.isNotEmpty) {
      query = eventBox.query(DbNip01Event_.kind.oneOf(kinds));
    } else {
      throw Exception("cannot query without either kinds or pubKeys");
    }
    query = query.order(DbNip01Event_.createdAt, flags: Order.descending);

    List<DbNip01Event> foundDb = query.build().find();

    final foundValid = foundDb.where((event) {
      if (pTag != null && !event.pTags.contains(pTag)) {
        return false;
      }

      if (since != null && event.createdAt < since) {
        return false;
      }

      if (until != null && event.createdAt > until) {
        return false;
      }

      return true;
    }).toList();

    return foundValid.map((dbEvent) => dbEvent.toNdk()).toList();
  }

  @override
  Future<Metadata?> loadMetadata(String pubKey) async {
    await dbRdy;
    final metadataBox = _objectBox.store.box<DbMetadata>();
    final existingMetadata = metadataBox
        .query(DbMetadata_.pubKey.equals(pubKey))
        .order(DbMetadata_.updatedAt, flags: Order.descending)
        .build()
        .findFirst();
    if (existingMetadata == null) {
      return null;
    }
    return existingMetadata.toNdk();
  }

  @override
  Future<List<Metadata?>> loadMetadatas(List<String> pubKeys) async {
    await dbRdy;
    final metadataBox = _objectBox.store.box<DbMetadata>();
    final existingMetadatas = metadataBox
        .query(DbMetadata_.pubKey.oneOf(pubKeys))
        .order(DbMetadata_.updatedAt, flags: Order.descending)
        .build()
        .find();
    return existingMetadatas.map((dbMetadata) => dbMetadata.toNdk()).toList();
  }

  @override
  Future<void> removeAllContactLists() async {
    await dbRdy;
    final contactListBox = _objectBox.store.box<DbContactList>();
    contactListBox.removeAll();
  }

  @override
  Future<void> removeAllEvents() async {
    await dbRdy;
    final eventBox = _objectBox.store.box<DbNip01Event>();
    eventBox.removeAll();
  }

  @override
  Future<void> removeAllEventsByPubKey(String pubKey) async {
    await dbRdy;
    final eventBox = _objectBox.store.box<DbNip01Event>();
    final events =
        eventBox.query(DbNip01Event_.pubKey.equals(pubKey)).build().find();
    eventBox.removeMany(events.map((e) => e.dbId).toList());
  }

  @override
  Future<void> removeAllMetadatas() async {
    await dbRdy;
    final metadataBox = _objectBox.store.box<DbMetadata>();
    metadataBox.removeAll();
  }

  @override
  Future<void> saveContactList(ContactList contactList) async {
    await dbRdy;
    final contactListBox = _objectBox.store.box<DbContactList>();
    final existingContact = contactListBox
        .query(DbContactList_.pubKey.equals(contactList.pubKey))
        .order(DbContactList_.createdAt, flags: Order.descending)
        .build()
        .findFirst();
    if (existingContact != null) {
      contactListBox.remove(existingContact.dbId);
    }
    contactListBox.put(DbContactList.fromNdk(contactList));
  }

  @override
  Future<void> saveContactLists(List<ContactList> contactLists) async {
    await dbRdy;
    final contactListBox = _objectBox.store.box<DbContactList>();
    contactListBox
        .putMany(contactLists.map((cl) => DbContactList.fromNdk(cl)).toList());
  }

  @override
  Future<void> saveEvent(Nip01Event event) async {
    await dbRdy;
    final eventBox = _objectBox.store.box<DbNip01Event>();
    final existingEvent = eventBox
        .query(DbNip01Event_.nostrId.equals(event.id))
        .build()
        .findFirst();
    if (existingEvent != null) {
      eventBox.remove(existingEvent.dbId);
    }
    eventBox.put(DbNip01Event.fromNdk(event));
  }

  @override
  Future<void> saveEvents(List<Nip01Event> events) async {
    await dbRdy;
    final eventBox = _objectBox.store.box<DbNip01Event>();
    eventBox.putMany(events.map((e) => DbNip01Event.fromNdk(e)).toList());
  }

  @override
  Future<void> saveMetadata(Metadata metadata) async {
    await dbRdy;
    final metadataBox = _objectBox.store.box<DbMetadata>();
    final existingMetadatas = metadataBox
        .query(DbMetadata_.pubKey.equals(metadata.pubKey))
        .order(DbMetadata_.updatedAt, flags: Order.descending)
        .build()
        .find();
    if (existingMetadatas.length > 1) {
      metadataBox.removeMany(existingMetadatas.map((e) => e.dbId).toList());
    }
    if (existingMetadatas.isNotEmpty &&
        metadata.updatedAt! < existingMetadatas[0].updatedAt!) {
      return;
    }
    metadataBox.put(DbMetadata.fromNdk(metadata));
  }

  @override
  Future<void> saveMetadatas(List<Metadata> metadatas) async {
    await dbRdy;
    for (final metadata in metadatas) {
      await saveMetadata(metadata);
    }
  }

  @override
  Future<Nip05?> loadNip05(String pubKey) async {
    await dbRdy;
    final box = _objectBox.store.box<DbNip05>();
    final existing = box
        .query(DbNip05_.pubKey.equals(pubKey))
        .order(DbNip05_.networkFetchTime, flags: Order.descending)
        .build()
        .findFirst();
    if (existing == null) {
      return null;
    }
    return existing.toNdk();
  }

  @override
  Future<List<Nip05?>> loadNip05s(List<String> pubKeys) async {
    await dbRdy;
    final box = _objectBox.store.box<DbNip05>();
    final existing = box
        .query(DbNip05_.pubKey.oneOf(pubKeys))
        .order(DbNip05_.networkFetchTime, flags: Order.descending)
        .build()
        .find();
    return existing.map((dbMetadata) => dbMetadata.toNdk()).toList();
  }

  @override
  Future<RelaySet?> loadRelaySet(String name, String pubKey) async {
    return null;
  }

  @override
  Future<UserRelayList?> loadUserRelayList(String pubKey) async {
    await dbRdy;
    final userRelayListBox = _objectBox.store.box<DbUserRelayList>();
    final existingUserRelayList = userRelayListBox
        .query(DbUserRelayList_.pubKey.equals(pubKey))
        .order(DbUserRelayList_.createdAt, flags: Order.descending)
        .build()
        .findFirst();
    if (existingUserRelayList == null) {
      return null;
    }
    return existingUserRelayList.toNdk();
  }

  @override
  Future<void> removeAllNip05s() async {
    await dbRdy;
    final box = _objectBox.store.box<DbNip05>();
    box.removeAll();
  }

  @override
  Future<void> removeAllRelaySets() async {
    throw UnimplementedError(
        'removeAllRelaySets is not implemented in DbObjectBox');
  }

  @override
  Future<void> removeAllUserRelayLists() async {
    await dbRdy;
    final userRelayListBox = _objectBox.store.box<DbUserRelayList>();
    userRelayListBox.removeAll();
  }

  @override
  Future<void> removeContactList(String pubKey) async {
    await dbRdy;
    final contactListBox = _objectBox.store.box<DbContactList>();
    final existingContact = contactListBox
        .query(DbContactList_.pubKey.equals(pubKey))
        .build()
        .findFirst();
    if (existingContact != null) {
      contactListBox.remove(existingContact.dbId);
    }
  }

  @override
  Future<void> removeEvent(String id) async {
    await dbRdy;
    final eventBox = _objectBox.store.box<DbNip01Event>();
    final existingEvent =
        eventBox.query(DbNip01Event_.nostrId.equals(id)).build().findFirst();
    if (existingEvent != null) {
      eventBox.remove(existingEvent.dbId);
    }
  }

  @override
  Future<void> removeMetadata(String pubKey) async {
    await dbRdy;
    final metadataBox = _objectBox.store.box<DbMetadata>();
    final existingMetadata = metadataBox
        .query(DbMetadata_.pubKey.equals(pubKey))
        .build()
        .findFirst();
    if (existingMetadata != null) {
      metadataBox.remove(existingMetadata.dbId);
    }
  }

  @override
  Future<void> removeNip05(String pubKey) async {
    await dbRdy;
    final box = _objectBox.store.box<DbNip05>();
    final existing = box.query(DbNip05_.pubKey.equals(pubKey)).build().find();
    if (existing.isNotEmpty) {
      box.removeMany(existing.map((e) => e.dbId).toList());
    }
  }

  @override
  Future<void> removeRelaySet(String name, String pubKey) async {
    throw UnimplementedError(
        'removeRelaySet is not implemented in DbObjectBox');
  }

  @override
  Future<void> removeUserRelayList(String pubKey) async {
    await dbRdy;
    final userRelayListBox = _objectBox.store.box<DbUserRelayList>();
    final existingUserRelayList = userRelayListBox
        .query(DbUserRelayList_.pubKey.equals(pubKey))
        .build()
        .findFirst();
    if (existingUserRelayList != null) {
      userRelayListBox.remove(existingUserRelayList.dbId);
    }
  }

  @override
  Future<void> saveNip05(Nip05 nip05) async {
    await dbRdy;
    final box = _objectBox.store.box<DbNip05>();
    final existing = box
        .query(DbNip05_.pubKey.equals(nip05.pubKey))
        .order(DbNip05_.networkFetchTime, flags: Order.descending)
        .build()
        .find();
    if (existing.length > 1) {
      box.removeMany(existing.map((e) => e.dbId).toList());
    }
    if (existing.isNotEmpty &&
        nip05.networkFetchTime! < existing[0].networkFetchTime!) {
      return;
    }
    box.put(DbNip05.fromNdk(nip05));
  }

  @override
  Future<void> saveNip05s(List<Nip05> nip05s) async {
    await dbRdy;
    for (final nip05 in nip05s) {
      await saveNip05(nip05);
    }
  }

  @override
  Future<void> saveRelaySet(RelaySet relaySet) async {
    // No operation for unimplemented method
    throw UnimplementedError('saveRelaySet is not implemented in DbObjectBox');
  }

  @override
  Future<void> saveUserRelayList(UserRelayList userRelayList) async {
    await dbRdy;
    final userRelayListBox = _objectBox.store.box<DbUserRelayList>();
    final existingUserRelayList = userRelayListBox
        .query(DbUserRelayList_.pubKey.equals(userRelayList.pubKey))
        .order(DbUserRelayList_.createdAt, flags: Order.descending)
        .build()
        .findFirst();
    if (existingUserRelayList != null) {
      userRelayListBox.remove(existingUserRelayList.dbId);
    }
    userRelayListBox.put(DbUserRelayList.fromNdk(userRelayList));
  }

  @override
  Future<void> saveUserRelayLists(List<UserRelayList> userRelayLists) async {
    final wait = <Future>[];
    for (final userRelayList in userRelayLists) {
      wait.add(saveUserRelayList(userRelayList));
    }
    await Future.wait(wait);
  }

  // Search by name, nip05
  @override
  Future<Iterable<Metadata>> searchMetadatas(String search, int limit) async {
    await dbRdy;
    final metadataBox = _objectBox.store.box<DbMetadata>();

    // Create a query with OR condition
    final query = metadataBox
        .query(DbMetadata_.splitNameWords
            .containsElement(search, caseSensitive: false)
            .or(DbMetadata_.name
                .startsWith(search, caseSensitive: false)
                .or(DbMetadata_.splitDisplayNameWords
                    .containsElement(search, caseSensitive: false))
                .or(DbMetadata_.displayName
                    .startsWith(search, caseSensitive: false))
                .or(DbMetadata_.nip05
                    .startsWith(search, caseSensitive: false))))
        .order(DbMetadata_.name, flags: Order.descending)
        .build();
    query..limit = limit;
    final results = query.find();

    return results.map((dbMetadata) => dbMetadata.toNdk()).take(limit);
  }

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
    await dbRdy;
    final eventBox = _objectBox.store.box<DbNip01Event>();

    // Build conditions
    Condition<DbNip01Event>? condition;

    // Add search condition if provided (NIP-50)
    if (search != null && search.isNotEmpty) {
      condition = DbNip01Event_.content.contains(search, caseSensitive: false);
    }

    // Add ids filter
    if (ids != null && ids.isNotEmpty) {
      Condition<DbNip01Event> idsCondition = DbNip01Event_.nostrId.oneOf(ids);
      condition =
          (condition == null) ? idsCondition : condition.and(idsCondition);
    }

    // Add authors filter
    if (authors != null && authors.isNotEmpty) {
      Condition<DbNip01Event> authorsCondition =
          DbNip01Event_.pubKey.oneOf(authors);
      condition = (condition == null)
          ? authorsCondition
          : condition.and(authorsCondition);
    }

    // Add kinds filter
    if (kinds != null && kinds.isNotEmpty) {
      Condition<DbNip01Event> kindsCondition = DbNip01Event_.kind.oneOf(kinds);
      condition =
          (condition == null) ? kindsCondition : condition.and(kindsCondition);
    }

    // Add since filter
    if (since != null) {
      Condition<DbNip01Event> sinceCondition =
          DbNip01Event_.createdAt.greaterOrEqual(since);
      condition =
          (condition == null) ? sinceCondition : condition.and(sinceCondition);
    }

    // Add until filter
    if (until != null) {
      Condition<DbNip01Event> untilCondition =
          DbNip01Event_.createdAt.lessOrEqual(until);
      condition =
          (condition == null) ? untilCondition : condition.and(untilCondition);
    }

    // Create and build the query
    QueryBuilder<DbNip01Event> queryBuilder;
    if (condition != null) {
      queryBuilder = eventBox.query(condition);
    } else {
      queryBuilder = eventBox.query();
    }

    // Apply sorting
    queryBuilder.order(DbNip01Event_.createdAt, flags: Order.descending);

    // Build and execute the query
    final query = queryBuilder.build();
    query..limit = limit;
    final results = query.find();

    // For tag filtering, we need to do it in memory since ObjectBox doesn't support
    // complex JSON querying within arrays
    List<DbNip01Event> filteredResults = results;

    // Apply tag filters in memory if needed
    if (tags != null && tags.isNotEmpty) {
      filteredResults = results.where((event) {
        // Check if the event matches all tag filters
        return tags.entries.every((tagEntry) {
          String tagKey = tagEntry.key;
          List<String> tagValues = tagEntry.value;

          // Handle the special case where tag key starts with '#'
          if (tagKey.startsWith('#') && tagKey.length > 1) {
            tagKey = tagKey.substring(1); // Remove the '#' prefix
          }

          // Get all tags with this key
          List<DbTag> eventTags =
              event.tags.where((t) => t.key == tagKey).toList();

          // Check if any of the event's tags with this key have a value in the requested values
          return eventTags.any((tag) =>
              tagValues.contains(tag.value) ||
              tagValues.contains(tag.value.toLowerCase()));
        });
      }).toList();
    }

    return filteredResults.map((dbEvent) => dbEvent.toNdk()).take(limit);
  }

  @override
  Future<List<CahsuKeyset>> getKeysets({String? mintUrl}) async {
    await dbRdy;
    if (mintUrl == null || mintUrl.isEmpty) {
      // return all keysets if no mintUrl
      return _objectBox.store
          .box<DbWalletCahsuKeyset>()
          .getAll()
          .map((dbKeyset) => dbKeyset.toNdk())
          .toList();
    }

    return _objectBox.store
        .box<DbWalletCahsuKeyset>()
        .query(DbWalletCahsuKeyset_.mintUrl.equals(mintUrl))
        .build()
        .find()
        .map((dbKeyset) => dbKeyset.toNdk())
        .toList();
  }

  @override
  Future<List<CashuProof>> getProofs({
    String? mintUrl,
    String? keysetId,
  }) async {
    /// returns all proofs if no filters are applied
    await dbRdy;

    final proofBox = _objectBox.store.box<DbWalletCashuProof>();

    // Build conditions
    Condition<DbWalletCashuProof>? condition;

    /// specify keysetId
    if (keysetId != null && keysetId.isNotEmpty) {
      condition =
          DbWalletCashuProof_.keysetId.contains(keysetId, caseSensitive: false);
    }

    if (mintUrl != null && mintUrl.isNotEmpty) {
      /// get all keysets for the mintUrl
      /// and filter proofs by keysetId
      ///
      final keysets = await getKeysets(mintUrl: mintUrl);
      if (keysets.isNotEmpty) {
        final keysetIds = keysets.map((k) => k.id).toList();
        final mintUrlCondition = DbWalletCashuProof_.keysetId.oneOf(keysetIds);
        condition = (condition == null)
            ? mintUrlCondition
            : condition.and(mintUrlCondition);
      } else {
        // If no keysets found for the mintUrl, return empty list
        return [];
      }
    }

    QueryBuilder<DbWalletCashuProof> queryBuilder;
    if (condition != null) {
      queryBuilder = proofBox.query(condition);
    } else {
      queryBuilder = proofBox.query();
    }

    // Apply sorting
    queryBuilder.order(DbWalletCashuProof_.amount, flags: Order.descending);

    // Build and execute the query
    final query = queryBuilder.build();

    final results = query.find();
    return results.map((dbProof) => dbProof.toNdk()).toList();
  }

  @override
  Future<void> removeProofs({
    required List<CashuProof> proofs,
    required String mintUrl,
  }) async {
    await dbRdy;
    final proofBox = _objectBox.store.box<DbWalletCashuProof>();

    // find all proofs, ignoring mintUrl
    final proofSecrets = proofs.map((p) => p.secret).toList();
    final existingProofs = proofBox
        .query(DbWalletCashuProof_.secret.oneOf(proofSecrets))
        .build()
        .find();

    // remove them
    if (existingProofs.isNotEmpty) {
      proofBox.removeMany(existingProofs.map((p) => p.dbId).toList());
    }
  }

  @override
  Future<void> saveKeyset(CahsuKeyset keyset) async {
    _objectBox.store.box<DbWalletCahsuKeyset>().put(
          DbWalletCahsuKeyset.fromNdk(keyset),
        );
    return Future.value();
  }

  @override
  Future<void> saveProofs({
    required List<CashuProof> tokens,
    required String mintUrl,
  }) async {
    await dbRdy;

    final proofBox = _objectBox.store.box<DbWalletCashuProof>();

    await proofBox.putMany(
      tokens.map((t) => DbWalletCashuProof.fromNdk(t)).toList(),
    );
    return Future.value();
  }

  @override
  Future<List<WalletTransaction>> getTransactions(
      {int? limit, String? walletId, String? unit}) {
    // TODO: implement getTransactions
    throw UnimplementedError();
  }

  @override
  Future<void> saveTransactions(
      {required List<WalletTransaction> transactions}) {
    // TODO: implement saveTransactions
    throw UnimplementedError();
  }

  @override
  Future<List<Wallet>?> getWallets(List<String>? ids) async {
    await dbRdy;

    return Future.value(
      _objectBox.store.box<DbWallet>().getAll().map((dbWallet) {
        return dbWallet.toNdk();
      }).where((wallet) {
        if (ids == null || ids.isEmpty) {
          return true; // return all wallets
        }
        return ids.contains(wallet.id);
      }).toList(),
    );
  }

  @override
  Future<void> removeWallet(String walletId) async {
    await dbRdy;
    // find wallet by id
    final walletBox = _objectBox.store.box<DbWallet>();
    final existingWallet = await walletBox
        .query(DbWallet_.id.equals(walletId))
        .build()
        .findFirst();
    if (existingWallet != null) {
      await walletBox.remove(existingWallet.dbId);
    }
    return Future.value();
  }

  @override
  Future<void> saveWallet(Wallet wallet) async {
    await dbRdy;
    await _objectBox.store.box<DbWallet>().put(DbWallet.fromNdk(wallet));
    return Future.value();
  }
}
