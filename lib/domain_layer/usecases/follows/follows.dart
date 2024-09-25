import '../../../shared/logger/logger.dart';
import '../../../shared/nips/nip01/helpers.dart';
import '../../entities/contact_list.dart';
import '../../entities/filter.dart';
import '../../repositories/cache_manager.dart';
import '../../repositories/event_signer.dart';
import '../relay_manager.dart';
import '../requests/requests.dart';

/// Follows usecase
class Follows {
  final Requests _requests;
  final CacheManager _cacheManager;
  final RelayManager _relayManager;

  Follows({
    required Requests requests,
    required CacheManager cacheManager,
    required RelayManager relayManager,
  })  : _relayManager = relayManager,
        _cacheManager = cacheManager,
        _requests = requests;

  /// contact list of a given pubkey, not intended to get followers
  Future<ContactList?> getContactList(
    String pubKey, {
    /// skips the cache
    bool forceRefresh = false,
    int idleTimeout = Requests.DEFAULT_QUERY_TIMEOUT,
  }) async {
    ContactList? contactList = _cacheManager.loadContactList(pubKey);

    if (contactList != null && !forceRefresh) {
      return contactList;
    }

    ContactList? loadedContactList;
    try {
      await for (final event in _requests.query(
        filters: [
          Filter(kinds: [ContactList.KIND], authors: [pubKey], limit: 1)
        ],
      ).stream) {
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
      await _cacheManager.saveContactList(loadedContactList);
      contactList = loadedContactList;
    }

    return contactList;
  }

  // coverage:ignore-start

  // if cached contact list is older that now minus this duration that we should go refresh it,
  // otherwise we risk adding/removing contacts to a list that is out of date and thus loosing contacts other client has added/removed since.
  static const Duration REFRESH_CONTACT_LIST_DURATION = Duration(minutes: 10);
  Future<ContactList> _ensureUpToDateContactListOrEmpty(
      EventSigner signer) async {
    ContactList? contactList =
        _cacheManager.loadContactList(signer.getPublicKey());
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

  Future<ContactList> _broadcastAddContactInCollection(
      String toAdd,
      Iterable<String> relays,
      EventSigner signer,
      List<String> Function(ContactList) collectionAccessor) async {
    ContactList contactList = await _ensureUpToDateContactListOrEmpty(signer);
    List<String> collection = collectionAccessor(contactList);
    if (!collection.contains(toAdd)) {
      collection.add(toAdd);
      contactList.loadedTimestamp = Helpers.now;
      contactList.createdAt = Helpers.now;
      await _relayManager.broadcastEvent(contactList.toEvent(), relays, signer);
      await _cacheManager.saveContactList(contactList);
    }
    return contactList;
  }

  /// broadcast adding of contact
  Future<ContactList> broadcastAddContact(
      String add, Iterable<String> relays, EventSigner signer) async {
    return _broadcastAddContactInCollection(
        add, relays, signer, (list) => list.contacts);
  }

  /// broadcast adding of followed tag
  Future<ContactList> broadcastAddFollowedTag(
      String add, Iterable<String> relays, EventSigner signer) async {
    return _broadcastAddContactInCollection(
        add, relays, signer, (list) => list.followedTags);
  }

  /// broadcast adding of followed community
  Future<ContactList> broadcastAddFollowedCommunity(
      String toAdd, Iterable<String> relays, EventSigner signer) async {
    return _broadcastAddContactInCollection(
        toAdd, relays, signer, (list) => list.followedCommunities);
  }

  /// broadcast adding of followed event
  Future<ContactList> broadcastAddFollowedEvent(
      String toAdd, Iterable<String> relays, EventSigner signer) async {
    return _broadcastAddContactInCollection(
        toAdd, relays, signer, (list) => list.followedEvents);
  }

  Future<ContactList?> _broadcastRemoveContactInCollection(
      String toRemove,
      Iterable<String> relays,
      EventSigner signer,
      List<String> Function(ContactList) collectionAccessor) async {
    ContactList? contactList = await _ensureUpToDateContactListOrEmpty(signer);
    List<String> collection = collectionAccessor(contactList);
    if (collection.contains(toRemove)) {
      collection.remove(toRemove);
      contactList.loadedTimestamp = Helpers.now;
      contactList.createdAt = Helpers.now;
      await _relayManager.broadcastEvent(contactList.toEvent(), relays, signer);
      await _cacheManager.saveContactList(contactList);
    }
    return contactList;
  }

  /// broadcast removal of contact
  Future<ContactList?> broadcastRemoveContact(
      String toRemove, Iterable<String> relays, EventSigner signer) async {
    return _broadcastRemoveContactInCollection(
        toRemove, relays, signer, (list) => list.contacts);
  }

  /// broadcast removal of followed tag
  Future<ContactList?> broadcastRemoveFollowedTag(
      String toRemove, Iterable<String> relays, EventSigner signer) async {
    return _broadcastRemoveContactInCollection(
        toRemove, relays, signer, (list) => list.followedTags);
  }

  /// broadcast removal of followed community
  Future<ContactList?> broadcastRemoveFollowedCommunity(
      String toRemove, Iterable<String> relays, EventSigner signer) async {
    return _broadcastRemoveContactInCollection(
        toRemove, relays, signer, (list) => list.followedCommunities);
  }

  /// broadcast removal of followed event
  Future<ContactList?> broadcastRemoveFollowedEvent(
      String toRemove, Iterable<String> relays, EventSigner signer) async {
    return _broadcastRemoveContactInCollection(
        toRemove, relays, signer, (list) => list.followedEvents);
  }
  // coverage:ignore-end
}
