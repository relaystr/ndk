import '../../../shared/logger/logger.dart';
import '../../../shared/nips/nip01/helpers.dart';
import '../../entities/contact_list.dart';
import '../../entities/filter.dart';
import '../../repositories/cache_manager.dart';
import '../../repositories/event_signer.dart';
import '../broadcast/broadcast.dart';
import '../relay_manager.dart';
import '../requests/requests.dart';

/// Follows usecase
class Follows {
  final Requests _requests;
  final Broadcast _broadcast;
  final CacheManager _cacheManager;
  final RelayManager _relayManager;
  final EventSigner? _signer;

  Follows({
    required Requests requests,
    required Broadcast broadcast,
    required CacheManager cacheManager,
    required RelayManager relayManager,
    required EventSigner? signer,
  })  : _relayManager = relayManager,
        _cacheManager = cacheManager,
        _requests = requests,
        _signer = signer,
        _broadcast = broadcast;

  _checkSigner() {
    if (_signer == null) {
      throw "cannot sign without a signer";
    }
  }

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
    String pubkey,
  ) async {
    ContactList? contactList = _cacheManager.loadContactList(pubkey);
    int sometimeAgo = DateTime.now()
            .subtract(REFRESH_CONTACT_LIST_DURATION)
            .millisecondsSinceEpoch ~/
        1000;
    bool refresh = contactList == null ||
        contactList.loadedTimestamp == null ||
        contactList.loadedTimestamp! < sometimeAgo;
    if (refresh) {
      contactList = await getContactList(pubkey, forceRefresh: true);
    }
    contactList ??= ContactList(pubKey: pubkey, contacts: []);
    return contactList;
  }

  Future<ContactList> _broadcastAddContactInCollection(
    String toAdd,
    List<String>? customRelays,
    List<String> Function(ContactList) collectionAccessor,
  ) async {
    _checkSigner();
    ContactList contactList =
        await _ensureUpToDateContactListOrEmpty(_signer!.getPublicKey());
    List<String> collection = collectionAccessor(contactList);
    if (!collection.contains(toAdd)) {
      collection.add(toAdd);
      contactList.loadedTimestamp = Helpers.now;
      contactList.createdAt = Helpers.now;

      final bResult = _broadcast.broadcast(
        nostrEvent: contactList.toEvent(),
        specificRelays: customRelays,
      );
      //await bResult.publishDone;
      await _cacheManager.saveContactList(contactList);
    }
    return contactList;
  }

  /// broadcast adding of contact
  Future<ContactList> broadcastAddContact(
    String add, {
    List<String>? customRelays,
  }) async {
    return _broadcastAddContactInCollection(
        add, customRelays, (list) => list.contacts);
  }

  /// broadcast adding of followed tag
  Future<ContactList> broadcastAddFollowedTag(
    String add, {
    List<String>? customRelays,
  }) async {
    return _broadcastAddContactInCollection(
        add, customRelays, (list) => list.followedTags);
  }

  /// broadcast adding of followed community
  Future<ContactList> broadcastAddFollowedCommunity(
    String toAdd, {
    List<String>? relays,
  }) async {
    return _broadcastAddContactInCollection(
        toAdd, relays, (list) => list.followedCommunities);
  }

  /// broadcast adding of followed event
  Future<ContactList> broadcastAddFollowedEvent(
    String toAdd, {
    List<String>? relays,
  }) async {
    return _broadcastAddContactInCollection(
        toAdd, relays, (list) => list.followedEvents);
  }

  Future<ContactList?> _broadcastRemoveContactInCollection(
    String toRemove,
    List<String>? customRelays,
    List<String> Function(ContactList) collectionAccessor,
  ) async {
    _checkSigner();
    ContactList? contactList =
        await _ensureUpToDateContactListOrEmpty(_signer!.getPublicKey());
    List<String> collection = collectionAccessor(contactList);
    if (collection.contains(toRemove)) {
      collection.remove(toRemove);
      contactList.loadedTimestamp = Helpers.now;
      contactList.createdAt = Helpers.now;

      final bResult = _broadcast.broadcast(
        nostrEvent: contactList.toEvent(),
        specificRelays: customRelays,
      );
      //await bResult.publishDone;
      await _cacheManager.saveContactList(contactList);
    }
    return contactList;
  }

  /// broadcast removal of contact
  Future<ContactList?> broadcastRemoveContact(
    String toRemove, {
    List<String>? relays,
  }) async {
    return _broadcastRemoveContactInCollection(
        toRemove, relays, (list) => list.contacts);
  }

  /// broadcast removal of followed tag
  Future<ContactList?> broadcastRemoveFollowedTag(
    String toRemove, {
    List<String>? customRelays,
  }) async {
    return _broadcastRemoveContactInCollection(
        toRemove, customRelays, (list) => list.followedTags);
  }

  /// broadcast removal of followed community
  Future<ContactList?> broadcastRemoveFollowedCommunity(
    String toRemove, {
    List<String>? customRelays,
  }) async {
    return _broadcastRemoveContactInCollection(
        toRemove, customRelays, (list) => list.followedCommunities);
  }

  /// broadcast removal of followed event
  Future<ContactList?> broadcastRemoveFollowedEvent(
    String toRemove, {
    List<String>? customRelays,
  }) async {
    return _broadcastRemoveContactInCollection(
        toRemove, customRelays, (list) => list.followedEvents);
  }
  // coverage:ignore-end
}
