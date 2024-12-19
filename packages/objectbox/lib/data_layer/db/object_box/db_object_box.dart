import 'dart:async';

import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_objectbox/data_layer/db/object_box/schema/db_nip_05.dart';

import '../../../objectbox.g.dart';
import 'db_init_object_box.dart';
import 'schema/db_contact_list.dart';
import 'schema/db_metadata.dart';
import 'schema/db_nip_01_event.dart';

class DbObjectBox implements CacheManager {
  final Completer _initCompleter = Completer();
  Future get _dbRdy => _initCompleter.future;
  late ObjectBoxInit _objectBox;

  DbObjectBox() {
    _init();
  }

  Future _init() async {
    final objectbox = await ObjectBoxInit.create();
    _objectBox = objectbox;
    _initCompleter.complete();
  }

  @override
  Future<ContactList?> loadContactList(String pubKey) async {
    await _dbRdy;
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
    await _dbRdy;
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
    await _dbRdy;
    final eventBox = _objectBox.store.box<DbNip01Event>();

    var query = kinds != null && kinds.isNotEmpty
        ? eventBox.query(DbNip01Event_.pubKey
            .oneOf(pubKeys!)
            .and(DbNip01Event_.kind.oneOf(kinds)))
        : eventBox.query(DbNip01Event_.pubKey.oneOf(pubKeys!));

    query = query.order(DbNip01Event_.createdAt, flags: Order.descending);

    final foundDb = query.build().find();

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
    await _dbRdy;
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
    await _dbRdy;
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
    await _dbRdy;
    final contactListBox = _objectBox.store.box<DbContactList>();
    contactListBox.removeAll();
  }

  @override
  Future<void> removeAllEvents() async {
    await _dbRdy;
    final eventBox = _objectBox.store.box<DbNip01Event>();
    eventBox.removeAll();
  }

  @override
  Future<void> removeAllEventsByPubKey(String pubKey) async {
    await _dbRdy;
    final eventBox = _objectBox.store.box<DbNip01Event>();
    final events =
        eventBox.query(DbNip01Event_.pubKey.equals(pubKey)).build().find();
    eventBox.removeMany(events.map((e) => e.dbId).toList());
  }

  @override
  Future<void> removeAllMetadatas() async {
    await _dbRdy;
    final metadataBox = _objectBox.store.box<DbMetadata>();
    metadataBox.removeAll();
  }

  @override
  Future<void> saveContactList(ContactList contactList) async {
    await _dbRdy;
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
    await _dbRdy;
    final contactListBox = _objectBox.store.box<DbContactList>();
    contactListBox
        .putMany(contactLists.map((cl) => DbContactList.fromNdk(cl)).toList());
  }

  @override
  Future<void> saveEvent(Nip01Event event) async {
    await _dbRdy;
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
    await _dbRdy;
    final eventBox = _objectBox.store.box<DbNip01Event>();
    eventBox.putMany(events.map((e) => DbNip01Event.fromNdk(e)).toList());
  }

  @override
  Future<void> saveMetadata(Metadata metadata) async {
    await _dbRdy;
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
    await _dbRdy;
    for (final metadata in metadatas) {
      await saveMetadata(metadata);
    }
  }

  @override
  Future<Nip05?> loadNip05(String pubKey) async {
    await _dbRdy;
    final box = _objectBox.store.box<DbNip05>();
    final existing = box
        .query(DbNip05_.pubKey.equals(pubKey))
        .order(DbNip05_.updatedAt, flags: Order.descending)
        .build()
        .findFirst();
    if (existing == null) {
      return null;
    }
    return existing.toNdk();
  }

  @override
  Future<List<Nip05?>> loadNip05s(List<String> pubKeys) async {
    await _dbRdy;
    final box = _objectBox.store.box<DbNip05>();
    final existing = box
        .query(DbNip05_.pubKey.oneOf(pubKeys))
        .order(DbNip05_.updatedAt, flags: Order.descending)
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
    return null;
  }

  @override
  Future<void> removeAllNip05s() async {
    // No operation for unimplemented method
  }

  @override
  Future<void> removeAllRelaySets() async {
    // No operation for unimplemented method
  }

  @override
  Future<void> removeAllUserRelayLists() async {
    // No operation for unimplemented method
  }

  @override
  Future<void> removeContactList(String pubKey) async {
    // No operation for unimplemented method
  }

  @override
  Future<void> removeEvent(String id) async {
    // No operation for unimplemented method
  }

  @override
  Future<void> removeMetadata(String pubKey) async {
    // No operation for unimplemented method
  }

  @override
  Future<void> removeNip05(String pubKey) async {
    // No operation for unimplemented method
  }

  @override
  Future<void> removeRelaySet(String name, String pubKey) async {
    // No operation for unimplemented method
  }

  @override
  Future<void> removeUserRelayList(String pubKey) async {
    // No operation for unimplemented method
  }

  @override
  Future<void> saveNip05(Nip05 nip05) async {
    await _dbRdy;
    final box = _objectBox.store.box<DbNip05>();
    final existing = box
        .query(DbNip05_.pubKey.equals(nip05.pubKey))
        .order(DbNip05_.updatedAt, flags: Order.descending)
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
    await _dbRdy;
    for (final nip05 in nip05s) {
      await saveNip05(nip05);
    }
  }

  @override
  Future<void> saveRelaySet(RelaySet relaySet) async {
    // No operation for unimplemented method
  }

  @override
  Future<void> saveUserRelayList(UserRelayList userRelayList) async {
    // No operation for unimplemented method
  }

  @override
  Future<void> saveUserRelayLists(List<UserRelayList> userRelayLists) async {
    // No operation for unimplemented method
  }

  @override
  Future<Iterable<Metadata>> searchMetadatas(String search, int limit) async {
    return [];
  }
}
