import '../../../shared/logger/logger.dart';
import '../../../shared/nips/nip01/helpers.dart';
import '../../entities/contact_list.dart';
import '../../entities/filter.dart';
import '../../repositories/cache_manager.dart';
import '../../repositories/event_signer.dart';
import '../relay_manager.dart';
import '../requests/requests.dart';

class Follows {
  Requests requests;
  CacheManager cacheManager;
  RelayManager relayManager;

  Follows(
      {required this.requests,
      required this.cacheManager,
      required this.relayManager});

  Future<ContactList?> getContactList(String pubKey,
      {bool forceRefresh = false,
      int idleTimeout = Requests.DEFAULT_QUERY_TIMEOUT}) async {
    ContactList? contactList = cacheManager.loadContactList(pubKey);
    if (contactList == null || forceRefresh) {
      ContactList? loadedContactList;
      try {
        await for (final event in requests.query(filters: [
          Filter(kinds: [ContactList.KIND], authors: [pubKey], limit: 1)
        ]).stream) {
          if (loadedContactList == null ||
              loadedContactList.createdAt < event.createdAt) {
            loadedContactList = ContactList.fromEvent(event);
          }
        }
      } catch (e) {
        // probably timeout;
        Logger.log.e(e);
      }
      if (loadedContactList != null &&
          (contactList == null ||
              contactList.createdAt < loadedContactList.createdAt)) {
        loadedContactList.loadedTimestamp =
            DateTime.now().millisecondsSinceEpoch ~/ 1000;
        await cacheManager.saveContactList(loadedContactList);
        contactList = loadedContactList;
      }
    }
    return contactList;
  }

  // if cached contact list is older that now minus this duration that we should go refresh it,
  // otherwise we risk adding/removing contacts to a list that is out of date and thus loosing contacts other client has added/removed since.
  static const Duration REFRESH_CONTACT_LIST_DURATION = Duration(minutes: 10);

  Future<ContactList> ensureUpToDateContactListOrEmpty(
      EventSigner signer) async {
    ContactList? contactList =
        cacheManager.loadContactList(signer.getPublicKey());
    int sometimeAgo = DateTime.now()
            .subtract(REFRESH_CONTACT_LIST_DURATION)
            .millisecondsSinceEpoch ~/
        1000;
    bool refresh = contactList == null ||
        contactList.loadedTimestamp == null ||
        contactList.loadedTimestamp! < sometimeAgo;
    if (refresh) {
      contactList =
          await getContactList(signer.getPublicKey(), forceRefresh: true);
    }
    contactList ??= ContactList(pubKey: signer.getPublicKey(), contacts: []);
    return contactList;
  }

  Future<ContactList> broadcastAddContactInCollection(
      String toAdd,
      Iterable<String> relays,
      EventSigner signer,
      List<String> Function(ContactList) collectionAccessor) async {
    ContactList contactList = await ensureUpToDateContactListOrEmpty(signer);
    List<String> collection = collectionAccessor(contactList);
    if (!collection.contains(toAdd)) {
      collection.add(toAdd);
      contactList.loadedTimestamp = Helpers.now;
      contactList.createdAt = Helpers.now;
      await relayManager.broadcastEvent(contactList.toEvent(), relays, signer);
      await cacheManager.saveContactList(contactList);
    }
    return contactList;
  }

  Future<ContactList> broadcastAddContact(
      String add, Iterable<String> relays, EventSigner signer) async {
    return broadcastAddContactInCollection(
        add, relays, signer, (list) => list.contacts);
  }

  Future<ContactList> broadcastAddFollowedTag(
      String add, Iterable<String> relays, EventSigner signer) async {
    return broadcastAddContactInCollection(
        add, relays, signer, (list) => list.followedTags);
  }

  Future<ContactList> broadcastAddFollowedCommunity(
      String toAdd, Iterable<String> relays, EventSigner signer) async {
    return broadcastAddContactInCollection(
        toAdd, relays, signer, (list) => list.followedCommunities);
  }

  Future<ContactList> broadcastAddFollowedEvent(
      String toAdd, Iterable<String> relays, EventSigner signer) async {
    return broadcastAddContactInCollection(
        toAdd, relays, signer, (list) => list.followedEvents);
  }

  Future<ContactList?> broadcastRemoveContactInCollection(
      String toRemove,
      Iterable<String> relays,
      EventSigner signer,
      List<String> Function(ContactList) collectionAccessor) async {
    ContactList? contactList = await ensureUpToDateContactListOrEmpty(signer);
    List<String> collection = collectionAccessor(contactList);
    if (collection.contains(toRemove)) {
      collection.remove(toRemove);
      contactList.loadedTimestamp = Helpers.now;
      contactList.createdAt = Helpers.now;
      await relayManager.broadcastEvent(contactList.toEvent(), relays, signer);
      await cacheManager.saveContactList(contactList);
    }
    return contactList;
  }

  Future<ContactList?> broadcastRemoveContact(
      String toRemove, Iterable<String> relays, EventSigner signer) async {
    return broadcastRemoveContactInCollection(
        toRemove, relays, signer, (list) => list.contacts);
  }

  Future<ContactList?> broadcastRemoveFollowedTag(
      String toRemove, Iterable<String> relays, EventSigner signer) async {
    return broadcastRemoveContactInCollection(
        toRemove, relays, signer, (list) => list.followedTags);
  }

  Future<ContactList?> broadcastRemoveFollowedCommunity(
      String toRemove, Iterable<String> relays, EventSigner signer) async {
    return broadcastRemoveContactInCollection(
        toRemove, relays, signer, (list) => list.followedCommunities);
  }

  Future<ContactList?> broadcastRemoveFollowedEvent(
      String toRemove, Iterable<String> relays, EventSigner signer) async {
    return broadcastRemoveContactInCollection(
        toRemove, relays, signer, (list) => list.followedEvents);
  }
}
