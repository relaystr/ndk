import 'package:rxdart/rxdart.dart';

import '../../../data_layer/repositories/signers/bip340_event_signer.dart';
import '../../../shared/nips/nip01/helpers.dart';
import '../../entities/filter.dart';
import '../../entities/nip_01_event.dart';
import '../../entities/nip_51_list.dart';
import '../../repositories/cache_manager.dart';
import '../../repositories/event_signer.dart';

import '../accounts/accounts.dart';
import '../broadcast/broadcast.dart';
import '../requests/requests.dart';

/// Lists usecase for access to NIP-51 lists and sets.
///
/// This class provides methods to manage Nostr lists and sets according to NIP-51,
/// including creating, reading, updating, and deleting list elements and sets.
class Lists {
  final Requests _requests;
  final CacheManager _cacheManager;
  final Broadcast _broadcast;
  final Accounts _accounts;

  /// Creates a Lists usecase instance.
  Lists({
    required Requests requests,
    required CacheManager cacheManager,
    required Broadcast broadcast,
    required Accounts accounts,
  })  : _cacheManager = cacheManager,
        _requests = requests,
        _broadcast = broadcast,
        _accounts = accounts;

  EventSigner? get _eventSigner {
    return _accounts.getLoggedAccount()?.signer;
  }

  ///* lists *///

  Future<Nip51List?> _getCachedNip51List(int kind, EventSigner signer) async {
    List<Nip01Event>? events = await _cacheManager
        .loadEvents(pubKeys: [signer.getPublicKey()], kinds: [kind]);
    events.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );
    return events.isNotEmpty
        ? await Nip51List.fromEvent(events.first, signer)
        : null;
  }

  /// Returns a NIP-51 list by the given kind.
  ///
  /// Retrieves the most recent list event for the specified kind.
  /// First checks cache unless [forceRefresh] is true, then queries relays.
  ///
  /// [kind] the kind of NIP-51 list to retrieve \
  /// [forceRefresh] if true, bypass cache and query relays directly \
  /// [timeout] maximum duration to wait for relay responses
  ///
  /// Returns the list if found, null otherwise.
  Future<Nip51List?> getSingleNip51List(
    int kind, {
    bool forceRefresh = false,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (_eventSigner == null) {
      throw Exception("cannot get nip51 list without a signer");
    }
    final signer = _eventSigner!;
    Nip51List? list =
        !forceRefresh ? await _getCachedNip51List(kind, signer) : null;
    if (list == null) {
      Nip51List? refreshedList;
      await for (final event in _requests.query(filters: [
        Filter(
          authors: [signer.getPublicKey()],
          kinds: [kind],
        )
      ], timeout: timeout).stream) {
        if (refreshedList == null ||
            refreshedList.createdAt <= event.createdAt) {
          refreshedList = await Nip51List.fromEvent(event, signer);
          // if (Helpers.isNotBlank(event.content)) {
          //   Nip51List? decryptedList = await Nip51List.fromEvent(event, signer);
          //   refreshedList = decryptedList;
          // }
          await _cacheManager.saveEvent(event);
        }
      }
      return refreshedList;
    }
    return list;
  }

  /// Returns a NIP-51 list by kind for a given public key.
  ///
  /// Retrieves the most recent list event for the specified kind and public key.
  /// Unlike [getSingleNip51List], this works with any public key, not just
  /// the logged-in user.
  ///
  /// [kind] the kind of NIP-51 list to retrieve \
  /// [publicKey] the public key of the user whose list to retrieve \
  /// [forceRefresh] if true, bypass cache and query relays directly \
  /// [timeout] maximum duration to wait for relay responses
  ///
  /// Returns the list if found, null otherwise.
  Future<Nip51List?> getPublicList({
    required int kind,
    required String publicKey,
    bool forceRefresh = false,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final signer = Bip340EventSigner(privateKey: null, publicKey: publicKey);

    Nip51List? list =
        !forceRefresh ? await _getCachedNip51List(kind, signer) : null;

    if (list == null) {
      Nip51List? refreshedList;
      await for (final event in _requests.query(filters: [
        Filter(
          authors: [publicKey],
          kinds: [kind],
          limit: 1,
        )
      ], timeout: timeout).stream) {
        if (refreshedList == null ||
            refreshedList.createdAt < event.createdAt) {
          refreshedList = await Nip51List.fromEvent(event, signer);
          await _cacheManager.saveEvent(event);
        }
      }
      return refreshedList;
    }
    return list;
  }

  /// Adds an element to a NIP-51 list.
  ///
  /// If the list doesn't exist, it will be created. The updated list is
  /// then broadcast to relays and cached locally.
  ///
  /// [kind] the kind of NIP-51 list \
  /// [tag] the tag type for the element (e.g., 'p' for pubkey, 'e' for event) \
  /// [value] the value to add to the list \
  /// [broadcastRelays] optional specific relays to broadcast to \
  /// [private] if true, encrypt the element in the list content
  ///
  /// Returns the updated list.\
  /// Throws an exception if no event signer is available.
  Future<Nip51List> addElementToList({
    required int kind,
    required String tag,
    required String value,
    Iterable<String>? broadcastRelays,
    bool private = false,
  }) async {
    if (_eventSigner == null) {
      throw Exception(
          "cannot broadcast private nip51 list without a signer that can sign");
    }
    Nip51List? list = await getSingleNip51List(
      kind,
      forceRefresh: true,
    );
    list ??= Nip51List(
        kind: kind,
        pubKey: _eventSigner!.getPublicKey(),
        createdAt: Helpers.now,
        elements: []);
    list.addElement(tag, value, private);
    list.createdAt = Helpers.now;
    Nip01Event event = await list.toEvent(_eventSigner);

    final broadcastResponse = _broadcast.broadcast(
      nostrEvent: event,
      specificRelays: broadcastRelays,
      customSigner: _eventSigner,
    );
    await broadcastResponse.broadcastDoneFuture;

    List<Nip01Event>? events = await _cacheManager
        .loadEvents(pubKeys: [_eventSigner!.getPublicKey()], kinds: [kind]);
    for (var event in events) {
      _cacheManager.removeEvent(event.id);
    }
    await _cacheManager.saveEvent(event);
    return list;
  }

  /// Removes an element from a NIP-51 list.
  ///
  /// Updates the list by removing the specified element, then broadcasts
  /// the updated list to relays and updates the cache.
  ///
  /// [kind] the kind of NIP-51 list \
  /// [tag] the tag type of the element to remove \
  /// [value] the value to remove from the list \
  /// [broadcastRelays] optional specific relays to broadcast to
  ///
  /// Returns the updated list, or null if the list doesn't exist.\
  /// Throws an exception if no event signer is available.
  Future<Nip51List?> removeElementFromList({
    required int kind,
    required String tag,
    required String value,
    Iterable<String>? broadcastRelays,
  }) async {
    if (_eventSigner == null) {
      throw Exception(
          "cannot broadcast private nip51 list without a signer that can sign");
    }
    Nip51List? list = await getSingleNip51List(
      kind,
      forceRefresh: true,
    );
    if (list == null || list.elements.isEmpty) {
      list = Nip51List(
          kind: kind,
          pubKey: _eventSigner!.getPublicKey(),
          createdAt: Helpers.now,
          elements: []);
    }
    if (list.elements.isNotEmpty) {
      list.removeElement(tag, value);
      list.createdAt = Helpers.now;
      Nip01Event event = await list.toEvent(_eventSigner);

      final broadcastResponse = _broadcast.broadcast(
        nostrEvent: event,
        specificRelays: broadcastRelays,
        customSigner: _eventSigner,
      );
      await broadcastResponse.broadcastDoneFuture;

      List<Nip01Event>? events = await _cacheManager
          .loadEvents(pubKeys: [_eventSigner!.getPublicKey()], kinds: [kind]);
      for (var event in events) {
        _cacheManager.removeEvent(event.id);
      }
      await _cacheManager.saveEvent(event);
    }
    return list;
  }

  ///* sets *///

  /// gets set by name with the specified signer
  Future<Nip51Set?> _getCachedSetByName(
    String name,
    EventSigner signer,
    int kind,
  ) async {
    List<Nip01Event>? events = await _cacheManager
        .loadEvents(pubKeys: [signer.getPublicKey()], kinds: [kind]);
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

  /// get a nip51 set
  Stream<Iterable<Nip51Set>?> _getSets(
    int kind,
    EventSigner signer, {
    bool forceRefresh = false,
  }) {
    final relaySets = <String, Nip51Set>{};

    return _requests
        .query(
          filters: [
            Filter(
              authors: [signer.getPublicKey()],
              kinds: [kind],
            )
          ],
          cacheRead: !forceRefresh,
        )
        .stream
        .where((event) => event.getDtag() != null)
        .asyncMap((event) async {
          final dtag = event.getDtag()!;
          final existingSet = relaySets[dtag];

          if (existingSet == null || existingSet.createdAt < event.createdAt) {
            final newSet = await Nip51Set.fromEvent(event, signer);
            if (newSet != null) {
              await _cacheManager.saveEvent(event);
              relaySets[newSet.name] = newSet;
              return relaySets.values;
            }
          }
          return null;
        })
        .where((sets) => sets != null)
        // emit nothing to distinguis from loading
        .defaultIfEmpty(<Nip51Set>[]);
  }

  /// Gets a NIP-51 set by name identifier (d tag).
  ///
  /// Retrieves a specific set for the logged-in user or a custom signer.
  /// The set is identified by its name (d tag) and kind.
  ///
  /// [name] name of the set (d tag identifier) \
  /// [kind] kind of the set, see Nip51List class for constants \
  /// [customSigner] optional signer, defaults to logged-in account \
  /// [forceRefresh] if true, skip cache and query relays directly
  ///
  /// Returns the set if found, null otherwise. \
  /// Throws an exception if no account is logged in and no custom signer is provided.
  Future<Nip51Set?> getSetByName({
    required String name,
    required int kind,
    bool forceRefresh = false,
  }) async {
    final EventSigner signer;

    if (_eventSigner == null) {
      throw Exception("getSetByName() no account");
    }
    signer = _eventSigner!;

    Nip51Set? relaySet = await _getCachedSetByName(name, signer, kind);
    if (relaySet == null || forceRefresh) {
      Nip51Set? newRelaySet;
      await for (final event in _requests.query(filters: [
        Filter(
          authors: [signer.getPublicKey()],
          kinds: [kind],
          tags: {
            "#d": [name]
          },
        )
      ], cacheRead: !forceRefresh).stream) {
        if (newRelaySet == null || newRelaySet.createdAt < event.createdAt) {
          if (event.getDtag() != null && event.getDtag() == name) {
            newRelaySet = await Nip51Set.fromEvent(event, signer);
            await _cacheManager.saveEvent(event);
          } else if (Helpers.isNotBlank(event.content)) {
            Nip51Set? decryptedRelaySet =
                await Nip51Set.fromEvent(event, signer);
            if (decryptedRelaySet != null && decryptedRelaySet.name == name) {
              newRelaySet = decryptedRelaySet;
              await _cacheManager.saveEvent(event);
            }
          }
        }
      }
      return newRelaySet;
    }
    return relaySet;
  }

  /// Returns a stream of public sets for a given public key, default is pubkey of logged in user.
  ///
  /// Queries relays for all sets of the specified kind belonging to the
  /// given public key. Only public (non-encrypted) sets are returned.
  ///
  /// [kind] the kind of sets to retrieve \
  /// [publicKey] the public key of the user whose sets to retrieve, default logged in pubkey \
  /// [forceRefresh] if true, skip cache and query relays directly
  ///
  /// Returns a stream that emits collections of sets as they are discovered.
  Stream<Iterable<Nip51Set>?> getPublicSets({
    required int kind,
    String? publicKey,
    bool forceRefresh = false,
  }) {
    final EventSigner mySigner;
    if (publicKey == null) {
      if (_eventSigner == null) {
        throw Exception("getPublicSets() no account");
      }
      mySigner = _eventSigner!;
    } else {
      mySigner = Bip340EventSigner(privateKey: null, publicKey: publicKey);
    }

    return _getSets(kind, mySigner, forceRefresh: forceRefresh);
  }

  /// Adds an element to a NIP-51 set.
  ///
  /// If the set doesn't exist, it will be created. The updated set is
  /// then broadcast to relays and cached locally.
  ///
  /// [name] name of the set (d tag identifier) \
  /// [tag] the tag type for the element (e.g., 'relay', 'p', 'e') \
  /// [value] the value to add to the set \
  /// [kind] kind of the set \
  /// [private] if true, encrypt the element in the set content \
  /// [specificRelays] optional specific relays to broadcast to
  ///
  /// Returns the updated set.
  Future<Nip51Set?> addElementToSet({
    required String name,
    required String tag,
    required String value,
    required int kind,
    bool private = false,
    Iterable<String>? specificRelays,
  }) async {
    Nip51Set? set =
        await getSetByName(name: name, kind: kind, forceRefresh: true);
    set ??= Nip51Set(
        name: name,
        pubKey: _eventSigner!.getPublicKey(),
        kind: Nip51List.kRelaySet,
        createdAt: Helpers.now,
        elements: []);
    set.addElement(tag, value, private);
    set.createdAt = Helpers.now;
    Nip01Event event = await set.toEvent(_eventSigner);

    final broadcastResponse = _broadcast.broadcast(
      nostrEvent: event,
      specificRelays: specificRelays,
      customSigner: _eventSigner,
    );
    await broadcastResponse.broadcastDoneFuture;

    List<Nip01Event>? events = await _cacheManager
        .loadEvents(pubKeys: [_eventSigner!.getPublicKey()], kinds: [kind]);
    events = events.where((event) {
      if (event.getDtag() != null && event.getDtag() == name) {
        return true;
      }
      return false;
    }).toList();
    for (final event in events) {
      _cacheManager.removeEvent(event.id);
    }

    await _cacheManager.saveEvent(event);
    return set;
  }

  /// Removes an element from a NIP-51 set.
  ///
  /// Updates the set by removing the specified element, then broadcasts
  /// the updated set to relays and updates the cache.
  ///
  /// [name] name of the set (d tag identifier) \
  /// [value] the value to remove from the set \
  /// [tag] the tag type of the element to remove \
  /// [kind] kind of the set \
  /// [private] if true, the element was encrypted \
  /// [specificRelays] optional specific relays to broadcast to
  ///
  /// Returns the updated set.
  /// Throws an exception if no event signer is available.
  Future<Nip51Set?> removeElementFromSet({
    required String name,
    required String value,
    required String tag,
    required int kind,
    bool private = false,
    Iterable<String>? specificRelays,
  }) async {
    if (_eventSigner == null) {
      throw Exception(
          "cannot broadcast private nip51 list without a signer that can sign");
    }
    Nip51Set? mySet = await getSetByName(
      name: name,
      kind: kind,
      forceRefresh: true,
    );
    if ((mySet == null || mySet.allRelays.isEmpty)) {
      mySet = Nip51Set(
          name: name,
          kind: Nip51List.kRelaySet,
          pubKey: _eventSigner!.getPublicKey(),
          createdAt: Helpers.now,
          elements: []);
    }

    mySet.removeElement(tag, value);
    mySet.createdAt = Helpers.now;
    Nip01Event event = await mySet.toEvent(_eventSigner);

    final broadcastResponse = _broadcast.broadcast(
      nostrEvent: event,
      specificRelays: specificRelays,
      customSigner: _eventSigner,
    );
    await broadcastResponse.broadcastDoneFuture;

    List<Nip01Event>? events = await _cacheManager.loadEvents(
        pubKeys: [_eventSigner!.getPublicKey()], kinds: [Nip51List.kRelaySet]);
    events = events.where((event) {
      if (event.getDtag() != null && event.getDtag() == name) {
        return true;
      }
      return false;
    }).toList();
    for (var event in events) {
      _cacheManager.removeEvent(event.id);
    }
    await _cacheManager.saveEvent(event);

    return mySet;
  }

  /// Overwrites or creates a complete NIP-51 set.
  ///
  /// **Warning:** This replaces the entire set. Consider using
  /// [addElementToSet] or [removeElementFromSet] for incremental updates.
  ///
  /// [set] the complete set to broadcast \
  /// [kind] kind of the set \
  /// [specificRelays] optional specific relays to broadcast to
  ///
  /// Returns the set after broadcasting.
  Future<Nip51Set> setCompleteSet({
    required Nip51Set set,
    required int kind,
    Iterable<String>? specificRelays,
  }) async {
    Nip01Event event = await set.toEvent(_eventSigner);

    final broadcastResponse = _broadcast.broadcast(
      nostrEvent: event,
      specificRelays: specificRelays,
      customSigner: _eventSigner,
    );
    await broadcastResponse.broadcastDoneFuture;

    /// update cache, remove old set and set the new one
    List<Nip01Event>? events = await _cacheManager
        .loadEvents(pubKeys: [_eventSigner!.getPublicKey()], kinds: [kind]);
    events = events.where((event) {
      if (event.getDtag() != null && event.getDtag() == set.name) {
        return true;
      }
      return false;
    }).toList();
    for (final event in events) {
      _cacheManager.removeEvent(event.id);
    }

    await _cacheManager.saveEvent(event);
    return set;
  }

  /// Deletes a NIP-51 set by name.
  ///
  /// Broadcasts a deletion event for the set and removes it from the cache.
  /// Uses the logged-in account's signer.
  ///
  /// [name] name of the set (d tag identifier) \
  /// [kind] kind of the set \
  /// [specificRelays] optional specific relays to broadcast the deletion to
  ///
  /// Throws an exception if no event signer is available.
  Future deleteSet({
    required String name,
    required int kind,
    Iterable<String>? specificRelays,
  }) async {
    if (_eventSigner == null) {
      throw Exception(
          "cannot broadcast private nip51 list without a signer that can sign");
    }

    /// remove all from cache
    List<Nip01Event>? eventsInCache = await _cacheManager
        .loadEvents(pubKeys: [_eventSigner!.getPublicKey()], kinds: [kind]);
    eventsInCache = eventsInCache.where((event) {
      if (event.getDtag() != null && event.getDtag() == name) {
        return true;
      }
      return false;
    }).toList();

    Nip51Set? set = await getSetByName(name: name, kind: kind);
    if (set != null) {
      final broadcastResponse = _broadcast.broadcastDeletion(
        eventId: set.id,
        customSigner: _eventSigner,
      );
      await broadcastResponse.broadcastDoneFuture;

      for (final event in eventsInCache) {
        await _cacheManager.removeEvent(event.id);
      }
    }
  }

  //* deprecated methods *//

  /// Use [getSetByName] instead.
  @Deprecated("use getSetByName instead")
  Future<Nip51Set?> getSingleNip51RelaySet(
    String name, {
    bool forceRefresh = false,
  }) async {
    return getSetByName(
      name: name,
      kind: Nip51List.kRelaySet,
    );
  }

  /// Use [getPublicSets] instead.
  @Deprecated("use getSet() instead")
  Future<List<Nip51Set>?> getNip51RelaySets(
    int kind,
    EventSigner signer, {
    bool forceRefresh = false,
  }) async {
    // Nip51Set? relaySet;//  await getCachedNip51RelaySet(signer);
    // if (relaySet == null || forceRefresh) {
    Map<String, Nip51Set> newRelaySets = {};
    await for (final event in _requests.query(
      filters: [
        Filter(
          authors: [signer.getPublicKey()],
          kinds: [kind],
        )
      ],
      cacheRead: !forceRefresh,
    ).stream) {
      if (event.getDtag() != null) {
        Nip51Set? newRelaySet = newRelaySets[event.getDtag()];
        if (newRelaySet == null || newRelaySet.createdAt < event.createdAt) {
          if (event.getDtag() != null) {
            newRelaySet = await Nip51Set.fromEvent(event, signer);
          }
          if (newRelaySet != null) {
            await _cacheManager.saveEvent(event);
            newRelaySets[newRelaySet.name] = newRelaySet;
          }
        }
      }
    }
    return newRelaySets.values.toList();
    // }
    // return [];
  }

  /// Use [getPublicSets] instead.
  @Deprecated("use getPublicSets()")
  Future<List<Nip51Set>?> getPublicNip51RelaySets({
    required int kind,
    required String publicKey,
    bool forceRefresh = false,
  }) async {
    final mySigner = Bip340EventSigner(privateKey: null, publicKey: publicKey);
    return getNip51RelaySets(kind, mySigner, forceRefresh: forceRefresh);
  }

  /// Use [addElementToSet] instead.
  @Deprecated("use addElementToSet()")
  Future<Nip51Set> broadcastAddNip51SetRelay(
    String relayUrl,
    String name,
    Iterable<String>? broadcastRelays, {
    bool private = false,
  }) async {
    Nip51Set? list = await getSingleNip51RelaySet(name, forceRefresh: true);
    list ??= Nip51Set(
        name: name,
        pubKey: _eventSigner!.getPublicKey(),
        kind: Nip51List.kRelaySet,
        createdAt: Helpers.now,
        elements: []);
    list.addRelay(relayUrl, private);
    list.createdAt = Helpers.now;
    Nip01Event event = await list.toEvent(_eventSigner);
    //print(event);

    final broadcastResponse = _broadcast.broadcast(
      nostrEvent: event,
      specificRelays: broadcastRelays,
      customSigner: _eventSigner,
    );
    await broadcastResponse.broadcastDoneFuture;

    List<Nip01Event>? events = await _cacheManager.loadEvents(
        pubKeys: [_eventSigner!.getPublicKey()], kinds: [Nip51List.kRelaySet]);
    events = events.where((event) {
      if (event.getDtag() != null && event.getDtag() == name) {
        return true;
      }
      return false;
    }).toList();
    for (var event in events) {
      _cacheManager.removeEvent(event.id);
    }

    await _cacheManager.saveEvent(event);
    return list;
  }

  /// Use [removeElementFromSet] instead.
  @Deprecated("use removeElementFromSet()")
  Future<Nip51Set?> broadcastRemoveNip51SetRelay(
    String relayUrl,
    String name,
    Iterable<String>? broadcastRelays, {
    List<String>? defaultRelaysIfEmpty,
    bool private = false,
  }) async {
    if (_eventSigner == null) {
      throw Exception(
          "cannot broadcast private nip51 list without a signer that can sign");
    }
    Nip51Set? relaySet = await getSingleNip51RelaySet(
      name,
      forceRefresh: true,
    );
    if ((relaySet == null || relaySet.allRelays.isEmpty) &&
        defaultRelaysIfEmpty != null &&
        defaultRelaysIfEmpty.isNotEmpty) {
      relaySet = Nip51Set(
          name: name,
          kind: Nip51List.kRelaySet,
          pubKey: _eventSigner!.getPublicKey(),
          createdAt: Helpers.now,
          elements: []);
      relaySet.privateRelays = defaultRelaysIfEmpty;
    }
    if (relaySet != null) {
      relaySet.removeRelay(relayUrl);
      relaySet.createdAt = Helpers.now;
      Nip01Event event = await relaySet.toEvent(_eventSigner);

      final broadcastResponse = _broadcast.broadcast(
        nostrEvent: event,
        specificRelays: broadcastRelays,
        customSigner: _eventSigner,
      );
      await broadcastResponse.broadcastDoneFuture;

      List<Nip01Event>? events = await _cacheManager.loadEvents(
          pubKeys: [_eventSigner!.getPublicKey()],
          kinds: [Nip51List.kRelaySet]);
      events = events.where((event) {
        if (event.getDtag() != null && event.getDtag() == name) {
          return true;
        }
        return false;
      }).toList();
      for (var event in events) {
        _cacheManager.removeEvent(event.id);
      }
      await _cacheManager.saveEvent(event);
    }
    return relaySet;
  }

  /// Use [addElementToList] instead.
  @Deprecated("use removeElementFromList()")
  Future<Nip51List> broadcastAddNip51ListRelay(
    int kind,
    String relayUrl,
    Iterable<String>? broadcastRelays, {
    bool private = false,
  }) async {
    if (_eventSigner == null) {
      throw Exception(
          "cannot broadcast private nip51 list without a signer that can sign");
    }
    Nip51List? list = await getSingleNip51List(kind, forceRefresh: true);
    list ??= Nip51List(
        kind: kind,
        pubKey: _eventSigner!.getPublicKey(),
        createdAt: Helpers.now,
        elements: []);
    list.addRelay(relayUrl, private);
    list.createdAt = Helpers.now;
    Nip01Event event = await list.toEvent(_eventSigner);

    final broadcastResponse = _broadcast.broadcast(
      nostrEvent: event,
      specificRelays: broadcastRelays,
      customSigner: _eventSigner,
    );

    await broadcastResponse.broadcastDoneFuture;

    List<Nip01Event>? events = await _cacheManager
        .loadEvents(pubKeys: [_eventSigner!.getPublicKey()], kinds: [kind]);
    for (var event in events) {
      _cacheManager.removeEvent(event.id);
    }
    await _cacheManager.saveEvent(event);
    return list;
  }

  /// Use [removeElementFromSet] instead.
  @Deprecated("use removeElementFromSet()")
  Future<Nip51List?> broadcastRemoveNip51Relay(
    int kind,
    String relayUrl,
    Iterable<String>? broadcastRelays, {
    List<String>? defaultRelaysIfEmpty,
  }) async {
    if (_eventSigner == null) {
      throw Exception(
          "cannot broadcast private nip51 list without a signer that can sign");
    }
    Nip51List? list = await getSingleNip51List(
      kind,
      forceRefresh: true,
    );
    if ((list == null || list.allRelays.isEmpty) &&
        defaultRelaysIfEmpty != null &&
        defaultRelaysIfEmpty.isNotEmpty) {
      list = Nip51List(
          kind: kind,
          pubKey: _eventSigner!.getPublicKey(),
          createdAt: Helpers.now,
          elements: []);
      list.privateRelays = defaultRelaysIfEmpty;
    }
    if (list != null && list.allRelays.isNotEmpty) {
      list.removeRelay(relayUrl);
      list.createdAt = Helpers.now;
      Nip01Event event = await list.toEvent(_eventSigner);

      final broadcastResponse = _broadcast.broadcast(
        nostrEvent: event,
        specificRelays: broadcastRelays,
        customSigner: _eventSigner,
      );

      await broadcastResponse.broadcastDoneFuture;

      List<Nip01Event>? events = await _cacheManager
          .loadEvents(pubKeys: [_eventSigner!.getPublicKey()], kinds: [kind]);
      for (var event in events) {
        _cacheManager.removeEvent(event.id);
      }
      await _cacheManager.saveEvent(event);
    }
    return list;
  }

  /// Use [addElementToList] instead.
  @Deprecated("use broadcastAddElementToList()")
  Future<Nip51List> broadcastAddNip51ListElement(
    int kind,
    String tag,
    String value,
    Iterable<String>? broadcastRelays, {
    bool private = false,
  }) {
    return addElementToList(kind: kind, tag: tag, value: value);
  }

  /// Use [removeElementFromList] instead.
  @Deprecated("use broadcastRemoveElementFromList()")
  Future<Nip51List?> broadcastRemoveNip51ListElement(
    int kind,
    String tag,
    String value,
    Iterable<String>? broadcastRelays,
  ) async {
    return removeElementFromList(kind: kind, tag: tag, value: value);
  }

  /// return single public nip51 set that match given name and pubkey \
  /// use [getSetByName] instead
  @Deprecated("use getSetByName instead")
  Future<Nip51Set?> getSinglePublicNip51RelaySet({
    required String name,
    required String publicKey,
    bool forceRefresh = false,
  }) async {
    return getSingleNip51RelaySet(name, forceRefresh: forceRefresh);
  }
}
