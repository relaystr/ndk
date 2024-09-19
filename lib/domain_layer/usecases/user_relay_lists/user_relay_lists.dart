import '../../../shared/helpers/relay_helper.dart';
import '../../../shared/logger/logger.dart';
import '../../../shared/nips/nip01/helpers.dart';
import '../../entities/contact_list.dart';
import '../../entities/filter.dart';
import '../../entities/nip_65.dart';
import '../../entities/read_write_marker.dart';
import '../../entities/user_relay_list.dart';
import '../../repositories/cache_manager.dart';
import '../../repositories/event_signer.dart';
import '../relay_manager.dart';
import '../requests/requests.dart';

class UserRelayLists {
  Requests requests;
  CacheManager cacheManager;
  RelayManager relayManager;

  UserRelayLists({
    required this.requests,
    required this.cacheManager,
    required this.relayManager,
  });

  // TODO try to use generic query with cacheRead/Write mechanism
  Future<void> loadMissingRelayListsFromNip65OrNip02(List<String> pubKeys,
      {Function(String stepName, int count, int total)? onProgress,
        bool forceRefresh = false}) async {
    List<String> missingPubKeys = [];
    for (var pubKey in pubKeys) {
      UserRelayList? userRelayList = cacheManager.loadUserRelayList(pubKey);
      if (userRelayList == null || forceRefresh) {
        // TODO check if not too old (time passed since last refreshed timestamp)
        missingPubKeys.add(pubKey);
      }
    }
    Map<String, UserRelayList> fromNip65s = {};
    Map<String, UserRelayList> fromNip02Contacts = {};
    Set<ContactList> contactLists = {};
    Set<String> found = {};

    if (missingPubKeys.isNotEmpty) {
      print("loading missing relay lists ${missingPubKeys.length}");
      if (onProgress != null) {
        onProgress.call(
            "loading missing relay lists", 0, missingPubKeys.length);
      }
      try {
        await for (final event in (requests.query(
//                timeout: missingPubKeys.length > 1 ? 10 : 3,
            filters: [
              Filter(
                  authors: missingPubKeys,
                  kinds: [Nip65.KIND, ContactList.KIND])
            ])).stream) {
          switch (event.kind) {
            case Nip65.KIND:
              Nip65 nip65 = Nip65.fromEvent(event);
              if (nip65.relays.isNotEmpty) {
                UserRelayList fromNip65 = UserRelayList.fromNip65(nip65);
                if (fromNip65s[event.pubKey] == null ||
                    fromNip65s[event.pubKey]!.createdAt < event.createdAt) {
                  fromNip65s[event.pubKey] = fromNip65;
                }
                if (onProgress != null) {
                  found.add(event.pubKey);
                  onProgress.call("loading missing relay lists", found.length,
                      missingPubKeys.length);
                }
              }
            case ContactList.KIND:
              ContactList contactList = ContactList.fromEvent(event);
              contactLists.add(contactList);
              if (event.content.isNotEmpty) {
                if (fromNip02Contacts[event.pubKey] == null ||
                    fromNip02Contacts[event.pubKey]!.createdAt <
                        event.createdAt) {
                  fromNip02Contacts[event.pubKey] =
                      UserRelayList.fromNip02EventContent(event);
                }
                if (onProgress != null) {
                  found.add(event.pubKey);
                  onProgress.call("loading missing relay lists", found.length,
                      missingPubKeys.length);
                }
              }
          }
        }
      } catch (e) {
        print(e);
      }
      Set<UserRelayList> relayLists = Set.of(fromNip65s.values);
      // Only add kind3 contents relays if there is no Nip65 for given pubKey.
      // This is because kind3 contents relay should be deprecated, and if we have a nip65 list should be considered more up-to-date.
      for (MapEntry<String, UserRelayList> entry in fromNip02Contacts.entries) {
        if (!fromNip65s.containsKey(entry.key)) {
          relayLists.add(entry.value);
        }
      }
      await cacheManager.saveUserRelayLists(relayLists.toList());

      // also save to cache any fresher contact list
      List<ContactList> contactListsSave = [];
      for (ContactList contactList in contactLists) {
        ContactList? existing =
        cacheManager.loadContactList(contactList.pubKey);
        if (existing == null || existing.createdAt < contactList.createdAt) {
          contactListsSave.add(contactList);
        }
      }
      await cacheManager.saveContactLists(contactListsSave);

      if (onProgress != null) {
        onProgress.call(
            "loading missing relay lists", found.length, missingPubKeys.length);
      }
    }
    Logger.log.d("Loaded ${found.length} relay lists ");
  }

  Future<UserRelayList?> getSingleUserRelayList(String pubKey,
      {bool forceRefresh = false}) async {
    UserRelayList? userRelayList = cacheManager.loadUserRelayList(pubKey);
    if (userRelayList == null || forceRefresh) {
      await loadMissingRelayListsFromNip65OrNip02([pubKey],
          forceRefresh: forceRefresh);
      userRelayList = cacheManager.loadUserRelayList(pubKey);
    }
    return userRelayList;
  }
  /// *************************************************************************************************

  // if cached user relay list is older that now minus this duration that we should go refresh it,
  // otherwise we risk adding/removing relays to a list that is out of date and thus loosing relays other client has added/removed since.
  static const Duration REFRESH_USER_RELAY_DURATION = Duration(minutes: 10);

  Future<UserRelayList?> ensureUpToDateUserRelayList(EventSigner signer) async {
    UserRelayList? userRelayList =
    cacheManager.loadUserRelayList(signer.getPublicKey());
    int sometimeAgo = DateTime.now()
        .subtract(REFRESH_USER_RELAY_DURATION)
        .millisecondsSinceEpoch ~/
        1000;
    bool refresh =
        userRelayList == null || userRelayList.refreshedTimestamp < sometimeAgo;
    if (refresh) {
      userRelayList = await getSingleUserRelayList(signer.getPublicKey(),
          forceRefresh: true);
    }
    return userRelayList;
  }

  Future<UserRelayList> broadcastAddNip65Relay(String relayUrl,
      ReadWriteMarker marker, Iterable<String> broadcastRelays, EventSigner eventSigner) async {
    UserRelayList? userRelayList =
    await ensureUpToDateUserRelayList(eventSigner);
    if (userRelayList == null) {
      int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      userRelayList = UserRelayList(
          pubKey: eventSigner.getPublicKey(),
          relays: {
            for (String url in broadcastRelays) url: ReadWriteMarker.readWrite
          },
          createdAt: now,
          refreshedTimestamp: now);
    }
    userRelayList.relays[relayUrl] = marker;
    await Future.wait([
      relayManager.broadcastEvent(userRelayList.toNip65().toEvent(), broadcastRelays, eventSigner),
      cacheManager.saveUserRelayList(userRelayList)
    ]);
    return userRelayList;
  }

  Future<UserRelayList?> broadcastRemoveNip65Relay(
      String relayUrl, Iterable<String> broadcastRelays, EventSigner eventSigner) async {
    UserRelayList? userRelayList =
    await ensureUpToDateUserRelayList(eventSigner);
    if (userRelayList == null) {
      int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      userRelayList = UserRelayList(
          pubKey: eventSigner.getPublicKey(),
          relays: {
            for (String url in broadcastRelays) url: ReadWriteMarker.readWrite
          },
          createdAt: now,
          refreshedTimestamp: now);
    }
    if (userRelayList.relays.keys.contains(relayUrl)) {
      userRelayList.relays.remove(relayUrl);
      userRelayList.refreshedTimestamp = Helpers.now;
      await Future.wait([
        relayManager.broadcastEvent(userRelayList.toNip65().toEvent(), broadcastRelays, eventSigner),
        cacheManager.saveUserRelayList(userRelayList)
      ]);
    }
    return userRelayList;
  }

  Future<UserRelayList?> broadcastUpdateNip65RelayMarker(String relayUrl,
      ReadWriteMarker marker, Iterable<String> broadcastRelays, EventSigner eventSigner) async {
    UserRelayList? userRelayList =
    await ensureUpToDateUserRelayList(eventSigner);
    if (userRelayList == null) {
      int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      userRelayList = UserRelayList(
          pubKey: eventSigner.getPublicKey(),
          relays: {
            for (String url in broadcastRelays) url: ReadWriteMarker.readWrite
          },
          createdAt: now,
          refreshedTimestamp: now);
    }
    String? url;
    if (userRelayList.relays.keys.contains(relayUrl)) {
      url = relayUrl;
    } else {
      String? cleanUrl = cleanRelayUrl(relayUrl);
      if (cleanUrl != null && userRelayList.relays.keys.contains(cleanUrl)) {
        url = cleanUrl;
      } else if (userRelayList.relays.keys.contains("$relayUrl/")) {
        url = "$relayUrl/";
      }
    }
    if (url != null) {
      userRelayList.relays[url] = marker;
      userRelayList.refreshedTimestamp = Helpers.now;
      await relayManager.broadcastEvent(userRelayList.toNip65().toEvent(), broadcastRelays, eventSigner);
      await cacheManager.saveUserRelayList(userRelayList);
    }
    return userRelayList;
  }

}
