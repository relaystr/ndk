import 'dart:convert';

import '../domain_layer/entities/contact_list.dart';
import '../domain_layer/entities/filter.dart';
import '../domain_layer/entities/metadata.dart';
import '../domain_layer/entities/nip_01_event.dart';
import '../domain_layer/entities/nip_51_list.dart';
import '../domain_layer/entities/nip_65.dart';
import '../domain_layer/entities/read_write.dart';
import '../domain_layer/entities/read_write_marker.dart';
import '../domain_layer/entities/relay_set.dart';
import '../domain_layer/entities/user_relay_list.dart';
import '../domain_layer/repositories/event_signer.dart';
import '../domain_layer/repositories/event_verifier.dart';
import '../domain_layer/usecases/follows/follows.dart';
import '../domain_layer/usecases/relay_manager.dart';
import '../domain_layer/usecases/relay_sets_engine.dart';
import '../domain_layer/usecases/requests/requests.dart';
import '../shared/helpers/relay_helper.dart';
import '../shared/logger/logger.dart';
import '../shared/nips/nip01/helpers.dart';
import '../shared/nips/nip09/deletion.dart';
import '../shared/nips/nip25/reactions.dart';
import '../domain_layer/entities/global_state.dart';
import 'init.dart';
import 'ndk_config.dart';

// some global obj that schuld be kept in memory by lib user
class Ndk {
  // placeholder
  final NdkConfig config;
  static final GlobalState globalState = GlobalState();

  // global initialization use to access rdy repositories
  final Initialization _initialization;

  Ndk(this.config)
      : _initialization = Initialization(
          config: config,
          globalState: globalState,
        );

  Requests get requests => _initialization.requests;
  RelayManager get relays => _initialization.relayManager;
  Follows get follows => _initialization.follows;

  Future<RelaySet> calculateRelaySet(
      {required String name,
      required String ownerPubKey,
      required List<String> pubKeys,
      required RelayDirection direction,
      required int relayMinCountPerPubKey,
      Function(String, int, int)? onProgress}) async {
    if (_initialization.engine is! RelaySetsEngine) {
      throw UnimplementedError(
          "this engine doesn't support calculation of relay sets");
    }

    final RelaySetsEngine myEngine = _initialization.engine as RelaySetsEngine;

    return await myEngine.calculateRelaySet(
        name: name,
        ownerPubKey: ownerPubKey,
        pubKeys: pubKeys,
        direction: direction,
        relayMinCountPerPubKey: relayMinCountPerPubKey);
  }

  // TODO try to use generic query with cacheRead/Write mechanism
  Future<Metadata?> getSingleMetadata(
    String pubKey, {
    bool forceRefresh = false,
    int idleTimeout = RelayManager.DEFAULT_STREAM_IDLE_TIMEOUT,
  }) async {
    Metadata? metadata = config.cache.loadMetadata(pubKey);
    if (metadata == null || forceRefresh) {
      Metadata? loadedMetadata;
      try {
        await for (final event in requests.query(
          idPrefix: 'metadata-',
          filters: [
            Filter(kinds: [Metadata.KIND], authors: [pubKey], limit: 1)
          ],
        ).stream) {
          if (loadedMetadata == null ||
              loadedMetadata.updatedAt == null ||
              loadedMetadata.updatedAt! < event.createdAt) {
            loadedMetadata = Metadata.fromEvent(event);
          }
        }
      } catch (e) {
        // probably timeout;
      }
      if (loadedMetadata != null &&
          (metadata == null ||
              loadedMetadata.updatedAt == null ||
              metadata.updatedAt == null ||
              loadedMetadata.updatedAt! < metadata.updatedAt! ||
              forceRefresh)) {
        loadedMetadata.refreshedTimestamp = Helpers.now;
        await config.cache.saveMetadata(loadedMetadata);
        metadata = loadedMetadata;
      }
    }
    return metadata;
  }

  // TODO try to use generic query with cacheRead/Write mechanism
  Future<List<Metadata>> loadMissingMetadatas(
      List<String> pubKeys, RelaySet relaySet,
      {bool splitRequestsByPubKeyMappings = true,
      Function(Metadata)? onLoad}) async {
    List<String> missingPubKeys = [];
    for (var pubKey in pubKeys) {
      Metadata? userMetadata = config.cache.loadMetadata(pubKey);
      if (userMetadata == null) {
        // TODO check if not too old (time passed since last refreshed timestamp)
        missingPubKeys.add(pubKey);
      }
    }
    Map<String, Metadata> metadatas = {};

    if (missingPubKeys.isNotEmpty) {
      print("loading missing user metadatas ${missingPubKeys.length}");
      try {
        await for (final event in (requests.query(
                // idleTimeout: 1,
                // splitRequestsByPubKeyMappings: splitRequestsByPubKeyMappings,
                idPrefix: "missing-metadatas-",
                filters: [
                  Filter(authors: missingPubKeys, kinds: [Metadata.KIND])
                ],
                relaySet: relaySet))
            .stream
            .timeout(const Duration(seconds: 5), onTimeout: (sink) {
          print("timeout metadatas.length:${metadatas.length}");
        })) {
          if (metadatas[event.pubKey] == null ||
              metadatas[event.pubKey]!.updatedAt! < event.createdAt) {
            metadatas[event.pubKey] = Metadata.fromEvent(event);
            metadatas[event.pubKey]!.refreshedTimestamp = Helpers.now;
            await config.cache.saveMetadata(metadatas[event.pubKey]!);
            if (onLoad != null) {
              onLoad(metadatas[event.pubKey]!);
            }
          }
        }
      } catch (e) {
        Logger.log.e(e);
      }
      Logger.log.d("Loaded ${metadatas.length} user metadatas ");
    }
    return metadatas.values.toList();
  }

  Future<void> loadMissingRelayListsFromNip65OrNip02(List<String> pubKeys,
      {Function(String stepName, int count, int total)? onProgress,
      bool forceRefresh = false}) async {
    List<String> missingPubKeys = [];
    for (var pubKey in pubKeys) {
      UserRelayList? userRelayList = config.cache.loadUserRelayList(pubKey);
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
            ]))
            .stream) {
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
      await config.cache.saveUserRelayLists(relayLists.toList());

      // also save to cache any fresher contact list
      List<ContactList> contactListsSave = [];
      for (ContactList contactList in contactLists) {
        ContactList? existing =
            config.cache.loadContactList(contactList.pubKey);
        if (existing == null || existing.createdAt < contactList.createdAt) {
          contactListsSave.add(contactList);
        }
      }
      await config.cache.saveContactLists(contactListsSave);

      if (onProgress != null) {
        onProgress.call(
            "loading missing relay lists", found.length, missingPubKeys.length);
      }
    }
    Logger.log.d("Loaded ${found.length} relay lists ");
  }

  Future<UserRelayList?> getSingleUserRelayList(String pubKey,
      {bool forceRefresh = false}) async {
    UserRelayList? userRelayList = config.cache.loadUserRelayList(pubKey);
    if (userRelayList == null || forceRefresh) {
      await loadMissingRelayListsFromNip65OrNip02([pubKey],
          forceRefresh: forceRefresh);
      userRelayList = config.cache.loadUserRelayList(pubKey);
    }
    return userRelayList;
  }

  Future<Nip51List?> getCachedNip51List(int kind, EventSigner signer) async {
    List<Nip01Event>? events = config.cache
        .loadEvents(pubKeys: [signer.getPublicKey()], kinds: [kind]);
    events.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );
    return events.isNotEmpty
        ? await Nip51List.fromEvent(events.first, signer)
        : null;
  }

  Future<Nip51List?> getSingleNip51List(int kind, EventSigner signer,
      {bool forceRefresh = false, int timeout = 5}) async {
    Nip51List? list =
        !forceRefresh ? await getCachedNip51List(kind, signer) : null;
    if (list == null) {
      Nip51List? refreshedList;
      await for (final event in requests.query(
        filters: [
          Filter(
            authors: [signer.getPublicKey()],
            kinds: [kind],
          )
        ],
      ).stream) {
        if (refreshedList == null ||
            refreshedList.createdAt <= event.createdAt) {
          refreshedList = await Nip51List.fromEvent(event, signer);
          // if (Helpers.isNotBlank(event.content)) {
          //   Nip51List? decryptedList = await Nip51List.fromEvent(event, signer);
          //   refreshedList = decryptedList;
          // }
          await config.cache.saveEvent(event);
        }
      }
      return refreshedList;
    }
    return list;
  }

  Future<Nip51Set?> getCachedNip51RelaySet(
      String name, EventSigner signer) async {
    List<Nip01Event>? events = config.cache.loadEvents(
        pubKeys: [signer.getPublicKey()], kinds: [Nip51List.RELAY_SET]);
    events = events.where((event) {
      if (event.getDtag() != null && event.getDtag() == name) {
        return true;
      }
      return false;
    }).toList();
    events.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );
    return events.isNotEmpty
        ? await Nip51Set.fromEvent(events.first, signer)
        : null;
  }

  Future<Nip51Set?> getSingleNip51RelaySet(String name, EventSigner signer,
      {bool forceRefresh = false}) async {
    Nip51Set? relaySet = await getCachedNip51RelaySet(name, signer);
    if (relaySet == null || forceRefresh) {
      Nip51Set? newRelaySet;
      await for (final event in requests.query(filters: [
        Filter(
          authors: [signer.getPublicKey()],
          kinds: [Nip51List.RELAY_SET],
          dTags: [name],
        )
      ], cacheRead: !forceRefresh).stream) {
        if (newRelaySet == null || newRelaySet.createdAt < event.createdAt) {
          if (event.getDtag() != null && event.getDtag() == name) {
            newRelaySet = await Nip51Set.fromEvent(event, signer);
            await config.cache.saveEvent(event);
          } else if (Helpers.isNotBlank(event.content)) {
            Nip51Set? decryptedRelaySet =
                await Nip51Set.fromEvent(event, signer);
            if (decryptedRelaySet != null && decryptedRelaySet.name == name) {
              newRelaySet = decryptedRelaySet;
              await config.cache.saveEvent(event);
            }
          }
        }
      }
      return newRelaySet;
    }
    return relaySet;
  }

  Future<List<Nip51Set>?> getNip51RelaySets(int kind, EventSigner signer,
      {bool forceRefresh = false}) async {
    Nip51Set? relaySet; //getCachedNip51RelaySets(signer);
    if (relaySet == null || forceRefresh) {
      Map<String, Nip51Set> newRelaySets = {};
      await for (final event in requests.query(filters: [
        Filter(
          authors: [signer.getPublicKey()],
          kinds: [kind],
        )
      ], cacheRead: !forceRefresh).stream) {
        if (event.getDtag() != null) {
          Nip51Set? newRelaySet = newRelaySets[event.getDtag()];
          if (newRelaySet == null || newRelaySet.createdAt < event.createdAt) {
            if (event.getDtag() != null) {
              newRelaySet = await Nip51Set.fromEvent(event, signer);
            }
            if (newRelaySet != null) {
              await config.cache.saveEvent(event);
              newRelaySets[newRelaySet.name] = newRelaySet;
            }
          }
        }
      }
      return newRelaySets.values.toList();
    }
    return [];
  }

  Future<Nip01Event?> getSingleMetadataEvent(EventSigner signer) async {
    Nip01Event? loaded;
    await for (final event in requests.query(filters: [
      Filter(kinds: [Metadata.KIND], authors: [signer.getPublicKey()], limit: 1)
    ]).stream) {
      if (loaded == null || loaded.createdAt < event.createdAt) {
        loaded = event;
      }
    }
    return loaded;
  }

  /// hot swap EventVerifier
  changeEventVerifier(EventVerifier newEventVerifier) {
    config.eventVerifier = newEventVerifier;
  }

  /// hot swap EventSigner
  changeEventSigner(EventSigner? newEventSigner) {
    config.eventSigner = newEventSigner;
  }

  /// **********************************************************************************************************

  /// ! this is just an example
  /// event is event to publish
  /// broadcast config (could be optional) defines relays to broadcast to
  // Future<dynamic> broadcastEvent(dynamic event, dynamic broadcastConfig) {
  //   // calls uncase with config
  //   throw UnimplementedError();
  // }

  /// *******************************************************************************************************************

  Future<Metadata> broadcastMetadata(
      Metadata metadata, Iterable<String> broadcastRelays) async {
    if (config.eventSigner == null) {
      throw Exception("event signer required for broadcasting signed events");
    }
    Nip01Event? event = await getSingleMetadataEvent(config.eventSigner!);
    if (event != null) {
      Map<String, dynamic> map = json.decode(event.content);
      map.addAll(metadata.toJson());
      event = Nip01Event(
          pubKey: event.pubKey,
          kind: event.kind,
          tags: event.tags,
          content: json.encode(map),
          createdAt: Helpers.now);
    } else {
      event = metadata.toEvent();
    }
    await broadcastEvent(event, broadcastRelays);

    metadata.updatedAt = Helpers.now;
    metadata.refreshedTimestamp = Helpers.now;
    await config.cache.saveMetadata(metadata);

    return metadata;
  }

  /// *******************************************************************************************************************

  /// *************************************************************************************************

  // if cached user relay list is older that now minus this duration that we should go refresh it,
  // otherwise we risk adding/removing relays to a list that is out of date and thus loosing relays other client has added/removed since.
  static const Duration REFRESH_USER_RELAY_DURATION = Duration(minutes: 10);

  Future<UserRelayList?> ensureUpToDateUserRelayList(EventSigner signer) async {
    UserRelayList? userRelayList =
        config.cache.loadUserRelayList(signer.getPublicKey());
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
      ReadWriteMarker marker, Iterable<String> broadcastRelays) async {
    if (config.eventSigner == null) {
      throw Exception("event signer required for broadcasting signed events");
    }
    UserRelayList? userRelayList =
        await ensureUpToDateUserRelayList(config.eventSigner!);
    if (userRelayList == null) {
      int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      userRelayList = UserRelayList(
          pubKey: config.eventSigner!.getPublicKey(),
          relays: {
            for (String url in broadcastRelays) url: ReadWriteMarker.readWrite
          },
          createdAt: now,
          refreshedTimestamp: now);
    }
    userRelayList.relays[relayUrl] = marker;
    await Future.wait([
      broadcastEvent(userRelayList.toNip65().toEvent(), broadcastRelays),
      config.cache.saveUserRelayList(userRelayList)
    ]);
    return userRelayList;
  }

  Future<UserRelayList?> broadcastRemoveNip65Relay(
      String relayUrl, Iterable<String> broadcastRelays) async {
    if (config.eventSigner == null) {
      throw Exception("event signer required for broadcasting signed events");
    }
    UserRelayList? userRelayList =
        await ensureUpToDateUserRelayList(config.eventSigner!);
    if (userRelayList == null) {
      int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      userRelayList = UserRelayList(
          pubKey: config.eventSigner!.getPublicKey(),
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
        broadcastEvent(userRelayList.toNip65().toEvent(), broadcastRelays),
        config.cache.saveUserRelayList(userRelayList)
      ]);
    }
    return userRelayList;
  }

  Future<UserRelayList?> broadcastUpdateNip65RelayMarker(String relayUrl,
      ReadWriteMarker marker, Iterable<String> broadcastRelays) async {
    if (config.eventSigner == null) {
      throw Exception("event signer required for broadcasting signed events");
    }
    UserRelayList? userRelayList =
        await ensureUpToDateUserRelayList(config.eventSigner!);
    if (userRelayList == null) {
      int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      userRelayList = UserRelayList(
          pubKey: config.eventSigner!.getPublicKey(),
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
      await broadcastEvent(userRelayList.toNip65().toEvent(), broadcastRelays);
      await config.cache.saveUserRelayList(userRelayList);
    }
    return userRelayList;
  }

  /// *************************************************************************************************

  Future<Nip51Set> broadcastAddNip51SetRelay(
      String relayUrl, String name, Iterable<String> broadcastRelays,
      {bool private = false}) async {
    if (config.eventSigner == null ||
        private && !config.eventSigner!.canSign()) {
      throw Exception(
          "cannot broadcast private nip51 list without a signer that can sign");
    }
    Nip51Set? list = await getSingleNip51RelaySet(name, config.eventSigner!,
        forceRefresh: true);
    list ??= Nip51Set(
        name: name,
        pubKey: config.eventSigner!.getPublicKey(),
        createdAt: Helpers.now,
        elements: []);
    list.addRelay(relayUrl, private);
    list.createdAt = Helpers.now;
    Nip01Event event = await list.toEvent(config.eventSigner!);
    //print(event);
    await Future.wait([
      broadcastEvent(event, broadcastRelays),
    ]);
    List<Nip01Event>? events = config.cache.loadEvents(
        pubKeys: [config.eventSigner!.getPublicKey()],
        kinds: [Nip51List.RELAY_SET]);
    events = events.where((event) {
      if (event.getDtag() != null && event.getDtag() == name) {
        return true;
      }
      return false;
    }).toList();
    for (var event in events) {
      config.cache.removeEvent(event.id);
    }

    await config.cache.saveEvent(event);
    return list;
  }

  Future<Nip51Set?> broadcastRemoveNip51SetRelay(
      String relayUrl, String name, Iterable<String> broadcastRelays,
      {List<String>? defaultRelaysIfEmpty, bool private = false}) async {
    if (config.eventSigner == null ||
        private && !config.eventSigner!.canSign()) {
      throw Exception(
          "cannot broadcast private nip51 list without a signer that can sign");
    }
    Nip51Set? relaySet = await getSingleNip51RelaySet(
      name,
      config.eventSigner!,
      forceRefresh: true,
    );
    if ((relaySet == null || relaySet.allRelays.isEmpty) &&
        defaultRelaysIfEmpty != null &&
        defaultRelaysIfEmpty.isNotEmpty) {
      relaySet = Nip51Set(
          name: name,
          pubKey: config.eventSigner!.getPublicKey(),
          createdAt: Helpers.now,
          elements: []);
      relaySet.privateRelays = defaultRelaysIfEmpty;
    }
    if (relaySet != null) {
      relaySet.removeRelay(relayUrl);
      relaySet.createdAt = Helpers.now;
      Nip01Event event = await relaySet.toEvent(config.eventSigner!);
      await Future.wait([
        broadcastEvent(event, broadcastRelays),
      ]);
      List<Nip01Event>? events = config.cache.loadEvents(
          pubKeys: [config.eventSigner!.getPublicKey()],
          kinds: [Nip51List.RELAY_SET]);
      events = events.where((event) {
        if (event.getDtag() != null && event.getDtag() == name) {
          return true;
        }
        return false;
      }).toList();
      for (var event in events) {
        config.cache.removeEvent(event.id);
      }
      await config.cache.saveEvent(event);
    }
    return relaySet;
  }

  Future<Nip51List> broadcastAddNip51ListRelay(
      int kind, String relayUrl, Iterable<String> broadcastRelays,
      {bool private = false}) async {
    if (config.eventSigner == null ||
        private && !config.eventSigner!.canSign()) {
      throw Exception(
          "cannot broadcast private nip51 list without a signer that can sign");
    }
    Nip51List? list =
        await getSingleNip51List(kind, config.eventSigner!, forceRefresh: true);
    list ??= Nip51List(
        kind: kind,
        pubKey: config.eventSigner!.getPublicKey(),
        createdAt: Helpers.now,
        elements: []);
    list.addRelay(relayUrl, private);
    list.createdAt = Helpers.now;
    Nip01Event event = await list.toEvent(config.eventSigner!);
    // print(event);
    await Future.wait([
      broadcastEvent(event, broadcastRelays),
    ]);
    List<Nip01Event>? events = config.cache.loadEvents(
        pubKeys: [config.eventSigner!.getPublicKey()], kinds: [kind]);
    for (var event in events) {
      config.cache.removeEvent(event.id);
    }
    await config.cache.saveEvent(event);
    return list;
  }

  Future<Nip51List?> broadcastRemoveNip51Relay(
      int kind, String relayUrl, Iterable<String> broadcastRelays,
      {List<String>? defaultRelaysIfEmpty}) async {
    if (config.eventSigner == null || !config.eventSigner!.canSign()) {
      throw Exception(
          "cannot broadcast private nip51 list without a signer that can sign");
    }
    Nip51List? list = await getSingleNip51List(
      kind,
      config.eventSigner!,
      forceRefresh: true,
    );
    if ((list == null || list.allRelays.isEmpty) &&
        defaultRelaysIfEmpty != null &&
        defaultRelaysIfEmpty.isNotEmpty) {
      list = Nip51List(
          kind: kind,
          pubKey: config.eventSigner!.getPublicKey(),
          createdAt: Helpers.now,
          elements: []);
      list.privateRelays = defaultRelaysIfEmpty;
    }
    if (list != null && list.allRelays.isNotEmpty) {
      list.removeRelay(relayUrl);
      list.createdAt = Helpers.now;
      Nip01Event event = await list.toEvent(config.eventSigner!);
      await Future.wait([
        broadcastEvent(event, broadcastRelays),
      ]);
      List<Nip01Event>? events = config.cache.loadEvents(
          pubKeys: [config.eventSigner!.getPublicKey()], kinds: [kind]);
      for (var event in events) {
        config.cache.removeEvent(event.id);
      }
      await config.cache.saveEvent(event);
    }
    return list;
  }

  Future<Nip51List?> broadcastRemoveNip51ListElement(int kind, String tag,
      String value, Iterable<String> broadcastRelays) async {
    if (config.eventSigner == null || !config.eventSigner!.canSign()) {
      throw Exception(
          "cannot broadcast private nip51 list without a signer that can sign");
    }
    Nip51List? list = await getSingleNip51List(kind, config.eventSigner!,
        forceRefresh: true, timeout: 2);
    if (list == null || list.elements.isEmpty) {
      list = Nip51List(
          kind: kind,
          pubKey: config.eventSigner!.getPublicKey(),
          createdAt: Helpers.now,
          elements: []);
    }
    if (list.elements.isNotEmpty) {
      list.removeElement(tag, value);
      list.createdAt = Helpers.now;
      Nip01Event event = await list.toEvent(config.eventSigner!);
      await Future.wait([
        broadcastEvent(event, broadcastRelays),
      ]);
      List<Nip01Event>? events = config.cache.loadEvents(
          pubKeys: [config.eventSigner!.getPublicKey()], kinds: [kind]);
      for (var event in events) {
        config.cache.removeEvent(event.id);
      }
      await config.cache.saveEvent(event);
    }
    return list;
  }

  Future<Nip51List> broadcastAddNip51ListElement(
      int kind, String tag, String value, Iterable<String> broadcastRelays,
      {bool private = false}) async {
    if (config.eventSigner == null ||
        private && !config.eventSigner!.canSign()) {
      throw Exception(
          "cannot broadcast private nip51 list without a signer that can sign");
    }
    Nip51List? list = await getSingleNip51List(kind, config.eventSigner!,
        forceRefresh: true, timeout: 2);
    list ??= Nip51List(
        kind: kind,
        pubKey: config.eventSigner!.getPublicKey(),
        createdAt: Helpers.now,
        elements: []);
    list.addElement(tag, value, private);
    list.createdAt = Helpers.now;
    Nip01Event event = await list.toEvent(config.eventSigner!);
    // print(event);
    await Future.wait([
      broadcastEvent(event, broadcastRelays),
    ]);
    List<Nip01Event>? events = config.cache.loadEvents(
        pubKeys: [config.eventSigner!.getPublicKey()], kinds: [kind]);
    for (var event in events) {
      config.cache.removeEvent(event.id);
    }
    await config.cache.saveEvent(event);
    return list;
  }

  /// *************************************************************************************************

  Future<Nip01Event> broadcastReaction(String eventId, Iterable<String> relays,
      {String reaction = "+"}) async {
    if (config.eventSigner == null) {
      throw Exception("event signer required for broadcasting signed events");
    }
    Nip01Event event = Nip01Event(
        pubKey: config.eventSigner!.getPublicKey(),
        kind: Reaction.KIND,
        tags: [
          ["e", eventId]
        ],
        content: reaction,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000);
    await broadcastEvent(event, relays);
    return event;
  }

  Future<Nip01Event> broadcastDeletion(
      String eventId, Iterable<String> relays, EventSigner signer) async {
    if (config.eventSigner == null) {
      throw Exception("event signer required for broadcasting signed events");
    }
    Nip01Event event = Nip01Event(
        pubKey: signer.getPublicKey(),
        kind: Deletion.KIND,
        tags: [
          ["e", eventId]
        ],
        content: "delete",
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000);
    await broadcastEvent(event, relays);
    return event;
  }

  List<String> blockedRelays() {
    return _initialization.relayManager.blockedRelays;
  }

  Future<void> broadcastEvent(
      Nip01Event event, Iterable<String> broadcastRelays,
      {EventSigner? signer}) async {
    if (config.eventSigner != null && config.eventSigner!.canSign()) {
      return await _initialization.relayManager
          .broadcastEvent(event, broadcastRelays, config.eventSigner!);
    }
    throw Exception("event signer required for broadcasting signed events");
  }
}
