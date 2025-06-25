import '../../../config/user_relay_list_defaults.dart';
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
import '../accounts/accounts.dart';
import '../broadcast/broadcast.dart';
import '../requests/requests.dart';

/// similar to nip65, but also accepts values from nip02 \
/// gives you inbox/outbox data in various ways \
/// [UserRelayList] is a mapping of pubkey to relays with read/write markers
/// [UserRelayLists] is a usecase for managing [UserRelayList]s
class UserRelayLists {
  final Requests _requests;
  final CacheManager _cacheManager;
  final Broadcast _broadcast;
  final Accounts _accounts;

  /// user relay lists usecase
  UserRelayLists({
    required Requests requests,
    required CacheManager cacheManager,
    required Broadcast broadcast,
    required Accounts accounts,
  })  : _cacheManager = cacheManager,
        _requests = requests,
        _broadcast = broadcast,
        _accounts = accounts;

  EventSigner get _signer {
    if (_accounts.isNotLoggedIn) {
      throw "cannot sign without a signer";
    }
    return _accounts.getLoggedAccount()!.signer;
  }

  // TODO try to use generic query with cacheRead/Write mechanism
  /// load missing user relay lists from nip65 or kind 3 (kind02)
  Future<void> loadMissingRelayListsFromNip65OrNip02(
    List<String> pubKeys, {
    Function(String stepName, int count, int total)? onProgress,
    bool forceRefresh = false,
  }) async {
    List<String> missingPubKeys = [];
    for (var pubKey in pubKeys) {
      UserRelayList? userRelayList =
          await _cacheManager.loadUserRelayList(pubKey);
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
      Logger.log.d("loading missing relay lists ${missingPubKeys.length}");
      if (onProgress != null) {
        onProgress.call(
            "Loading missing relay lists", 0, missingPubKeys.length);
      }
      try {
        await for (final event in (_requests.query(
//                timeout: missingPubKeys.length > 1 ? 10 : 3,
            name: "user-relay-lists",
            filters: [
              Filter(
                  authors: missingPubKeys,
                  kinds: [Nip65.kKind, ContactList.kKind])
            ])).stream) {
          switch (event.kind) {
            case Nip65.kKind:
              Nip65 nip65 = Nip65.fromEvent(event);
              if (nip65.relays.isNotEmpty) {
                UserRelayList fromNip65 = UserRelayList.fromNip65(nip65);
                if (fromNip65s[event.pubKey] == null ||
                    fromNip65s[event.pubKey]!.createdAt < event.createdAt) {
                  fromNip65s[event.pubKey] = fromNip65;
                }
                if (onProgress != null) {
                  found.add(event.pubKey);
                  onProgress.call("Loading missing relay lists", found.length,
                      missingPubKeys.length);
                }
              }
            case ContactList.kKind:
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
                  onProgress.call("Loading missing relay lists", found.length,
                      missingPubKeys.length);
                }
              }
          }
        }
      } catch (e) {
        Logger.log.e(e);
      }
      Set<UserRelayList> relayLists = Set.of(fromNip65s.values);
      // Only add kind3 contents relays if there is no Nip65 for given pubKey.
      // This is because kind3 contents relay should be deprecated, and if we have a nip65 list should be considered more up-to-date.
      for (MapEntry<String, UserRelayList> entry in fromNip02Contacts.entries) {
        if (!fromNip65s.containsKey(entry.key)) {
          relayLists.add(entry.value);
        }
      }
      await _cacheManager.saveUserRelayLists(relayLists.toList());

      // also save to cache any fresher contact list
      List<ContactList> contactListsSave = [];
      for (ContactList contactList in contactLists) {
        ContactList? existing =
            await _cacheManager.loadContactList(contactList.pubKey);
        if (existing == null || existing.createdAt < contactList.createdAt) {
          contactListsSave.add(contactList);
        }
      }
      await _cacheManager.saveContactLists(contactListsSave);

      if (onProgress != null) {
        onProgress.call(
            "Loading missing relay lists", found.length, missingPubKeys.length);
      }
    }
    Logger.log.d("Loaded ${found.length} relay lists ");
  }

  /// return single user relay list
  Future<UserRelayList?> getSingleUserRelayList(
    String pubKey, {
    bool forceRefresh = false,
  }) async {
    UserRelayList? userRelayList =
        await _cacheManager.loadUserRelayList(pubKey);

    if (userRelayList == null || forceRefresh) {
      await loadMissingRelayListsFromNip65OrNip02(
        [pubKey],
        forceRefresh: forceRefresh,
      );
      userRelayList = await _cacheManager.loadUserRelayList(pubKey);
    }
    return userRelayList;
  }

  /// *************************************************************************************************

  Future<UserRelayList?> _ensureUpToDateUserRelayList() async {
    UserRelayList? userRelayList = await _cacheManager.loadUserRelayList(
      _signer.getPublicKey(),
    );

    /// if cached user relay list is older that now minus this duration that we should go refresh it,
    /// otherwise we risk adding/removing relays to a list that is out of date and thus loosing relays other client has added/removed since.
    int sometimeAgo = DateTime.now()
            .subtract(REFRESH_USER_RELAY_DURATION)
            .millisecondsSinceEpoch ~/
        1000;
    bool refresh =
        userRelayList == null || userRelayList.refreshedTimestamp < sometimeAgo;

    if (refresh) {
      userRelayList = await getSingleUserRelayList(
        _signer.getPublicKey(),
        forceRefresh: true,
      );
    }
    return userRelayList;
  }

  /// broadcast adding nip65 relay
  Future<UserRelayList> broadcastAddNip65Relay({
    required String relayUrl,
    required ReadWriteMarker marker,
    required Iterable<String> broadcastRelays,
    double? considerDonePercent,
    Duration? timeout,
  }) async {
    UserRelayList? userRelayList = await _ensureUpToDateUserRelayList();
    if (userRelayList == null) {
      int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      userRelayList = UserRelayList(
          pubKey: _signer.getPublicKey(),
          relays: {
            for (String url in broadcastRelays) url: ReadWriteMarker.readWrite
          },
          createdAt: now,
          refreshedTimestamp: now);
    }
    userRelayList.relays[relayUrl] = marker;

    final broadcastResponse = _broadcast.broadcast(
      nostrEvent: userRelayList.toNip65().toEvent(),
      specificRelays: broadcastRelays,
    );
    await Future.wait([
      broadcastResponse.broadcastDoneFuture,
      Future.delayed(Duration(seconds: 1)),
      _cacheManager.saveUserRelayList(userRelayList)
    ]);
    return userRelayList;
  }

  /// set initial user relay list can also be used to update the complete list /
  /// if you need to edit single entries prefer using [broadcastAddNip65Relay] or [broadcastRemoveNip65Relay] \
  ///
  /// [newUserRelayList] the new user relay list
  /// [returns] the new user relay list
  Future<UserRelayList> setInitialUserRelayList(
    UserRelayList newUserRelayList, {
    double? considerDonePercent,
    Duration? timeout,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    // set created at and refreshed timestamp
    newUserRelayList.refreshedTimestamp = now;
    newUserRelayList.createdAt = now;

    final broadcastResponse = _broadcast.broadcast(
      nostrEvent: newUserRelayList.toNip65().toEvent(),

      /// write to the new user relay list
      specificRelays: newUserRelayList.relays.keys,
    );

    await broadcastResponse.broadcastDoneFuture;

    await _cacheManager.saveUserRelayList(newUserRelayList);
    return newUserRelayList;
  }

  /// broadcast removal of nip65 relay
  Future<UserRelayList?> broadcastRemoveNip65Relay({
    required String relayUrl,
    required Iterable<String> broadcastRelays,
    double? considerDonePercent,
    Duration? timeout,
  }) async {
    UserRelayList? userRelayList = await _ensureUpToDateUserRelayList();

    if (userRelayList == null) {
      throw "no user relay list found, please make sure to set an initial list";
    }
    if (userRelayList.relays.keys.contains(relayUrl)) {
      userRelayList.relays.remove(relayUrl);
      userRelayList.refreshedTimestamp = Helpers.now;

      final broadcastResponse = _broadcast.broadcast(
        nostrEvent: userRelayList.toNip65().toEvent(),
        specificRelays: broadcastRelays,
      );
      await Future.wait([
        broadcastResponse.broadcastDoneFuture,
        Future.delayed(Duration(seconds: 1)),
        _cacheManager.saveUserRelayList(userRelayList)
      ]);
    }
    return userRelayList;
  }

  /// broadcast changing marker of nip65 relay\
  Future<UserRelayList?> broadcastUpdateNip65RelayMarker({
    required String relayUrl,
    required ReadWriteMarker marker,
    required Iterable<String> broadcastRelays,
  }) async {
    UserRelayList? userRelayList = await _ensureUpToDateUserRelayList();

    if (userRelayList == null) {
      throw "no user relay list found, please make sure to set an initial list";
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

      final broadcastResponse = _broadcast.broadcast(
          nostrEvent: userRelayList.toNip65().toEvent(),
          specificRelays: broadcastRelays);

      await broadcastResponse.broadcastDoneFuture;
      await Future.delayed(Duration(seconds: 1));

      await _cacheManager.saveUserRelayList(userRelayList);
    }
    return userRelayList;
  }

  /// reads the latest nip65 data from cache \
  /// [pubkeys] pubkeys you want nip65 data for \
  /// [cacheManger] the cache manager you want to use
  static Future<List<UserRelayList>> getUserRelayListCacheLatest({
    required List<String> pubkeys,
    required CacheManager cacheManager,
  }) async {
    // get the data from cache
    final List<UserRelayList> events = await Future.wait(
      pubkeys.map(
        (pubkey) => cacheManager.loadUserRelayList(pubkey),
      ),
    ).then((results) => results.whereType<UserRelayList>().toList());

    List<UserRelayList> nip65Data = _filterLatest(events);

    return nip65Data;
  }

  /// reads the latest nip65 data from cache \
  /// [pubkeys] pubkeys you want nip65 data for \
  /// [cacheManger] the cache manager you want to use
  static Future<UserRelayList?> getUserRelayListCacheLatestSingle({
    required String pubkey,
    required CacheManager cacheManager,
  }) async {
    final data = await getUserRelayListCacheLatest(
      pubkeys: [pubkey],
      cacheManager: cacheManager,
    );
    if (data.isEmpty) {
      return null;
    }
    return data.first;
  }

  /// return only the latest nip65 data for each pubkey
  static List<UserRelayList> _filterLatest(List<UserRelayList> uncleanData) {
    final List<UserRelayList> cleanData = [];

    for (final data in uncleanData) {
      final alreadyIn =
          cleanData.where((element) => element.pubKey == data.pubKey);

      if (alreadyIn.isNotEmpty) {
        final existing = alreadyIn.first;
        if (existing.createdAt > data.createdAt) {
          continue;
        } else {
          cleanData.remove(existing);
        }
      }

      cleanData.add(data);
    }
    return cleanData;
  }
}
