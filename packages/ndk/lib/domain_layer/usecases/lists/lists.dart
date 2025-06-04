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

/// Lists usecase for access to nip51 lists & sets
class Lists {
  final Requests _requests;
  final CacheManager _cacheManager;
  final Broadcast _broadcast;
  final Accounts _accounts;

  /// lists
  Lists({
    required Requests requests,
    required CacheManager cacheManager,
    required Broadcast broadcast,
    required Accounts accounts,
  })  : _cacheManager = cacheManager,
        _requests = requests,
        _broadcast = broadcast,
        _accounts = accounts;

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

  /// return nip51 list by given kind
  Future<Nip51List?> getSingleNip51List(
    int kind,
    EventSigner signer, {
    bool forceRefresh = false,
    Duration timeout = const Duration(seconds: 5),
  }) async {
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

  /// use getSetByName instead
  @Deprecated("use getSetByName instead")
  Future<Nip51Set?> getSingleNip51RelaySet(
    String name,
    EventSigner signer, {
    bool forceRefresh = false,
  }) async {
    return getSetByName(
      name: name,
      kind: Nip51List.kRelaySet,
      customSigner: signer,
    );
  }

  /// [name] name of the set \
  /// [kind] kind of the set @see Nip51List class \
  /// [customSigner] optional, logged in account used per default \
  /// [forceRefresh] skip cache \
  /// get a set by name identifier (d tag) for the logged in pubkey (or signer)
  Future<Nip51Set?> getSetByName({
    required String name,
    required int kind,
    EventSigner? customSigner,
    bool forceRefresh = false,
  }) async {
    final EventSigner signer;

    if (customSigner != null) {
      signer = customSigner;
    } else {
      if (_accounts.isNotLoggedIn) {
        throw Exception("getSetByName() no account");
      }
      signer = _accounts.getLoggedAccount()!.signer;
    }

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

  /// returns the public sets of a given pubkey
  Stream<Iterable<Nip51Set>?> getPublicSets({
    required int kind,
    required String publicKey,
    bool forceRefresh = false,
  }) {
    final mySigner = Bip340EventSigner(privateKey: null, publicKey: publicKey);
    return _getSets(kind, mySigner, forceRefresh: forceRefresh);
  }

  // coverage:ignore-start

  /// return list of all nip51 relay sets that match a given kind
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

  /// return single public nip51 set that match given name and pubkey \
  /// use getSetByName instead
  @Deprecated("use getSetByName instead")
  Future<Nip51Set?> getSinglePublicNip51RelaySet({
    required String name,
    required String publicKey,
    bool forceRefresh = false,
  }) async {
    //? not perfect to use bip340 signer here
    final mySigner = Bip340EventSigner(privateKey: null, publicKey: publicKey);
    return getSingleNip51RelaySet(name, mySigner, forceRefresh: forceRefresh);
  }

  /// use getPublicSets() instead
  @Deprecated("use getPublicSets() instead")
  Future<List<Nip51Set>?> getPublicNip51RelaySets({
    required int kind,
    required String publicKey,
    bool forceRefresh = false,
  }) async {
    final mySigner = Bip340EventSigner(privateKey: null, publicKey: publicKey);
    return getNip51RelaySets(kind, mySigner, forceRefresh: forceRefresh);
  }

  EventSigner? get _eventSigner {
    return _accounts.getLoggedAccount()?.signer;
  }

  Future<Nip51Set> broadcastAddNip51SetRelay(
    String relayUrl,
    String name,
    Iterable<String>? broadcastRelays, {
    bool private = false,
  }) async {
    if (_eventSigner == null) {
      throw Exception(
          "cannot broadcast private nip51 list without a signer that can sign");
    }
    Nip51Set? list =
        await getSingleNip51RelaySet(name, _eventSigner!, forceRefresh: true);
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
      _eventSigner!,
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
    Nip51List? list =
        await getSingleNip51List(kind, _eventSigner!, forceRefresh: true);
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
      _eventSigner!,
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

  Future<Nip51List?> broadcastRemoveNip51ListElement(
    int kind,
    String tag,
    String value,
    Iterable<String>? broadcastRelays,
  ) async {
    if (_eventSigner == null) {
      throw Exception(
          "cannot broadcast private nip51 list without a signer that can sign");
    }
    Nip51List? list = await getSingleNip51List(
      kind,
      _eventSigner!,
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

  Future<Nip51List> broadcastAddNip51ListElement(
    int kind,
    String tag,
    String value,
    Iterable<String>? broadcastRelays, {
    bool private = false,
  }) async {
    if (_eventSigner == null) {
      throw Exception(
          "cannot broadcast private nip51 list without a signer that can sign");
    }
    Nip51List? list = await getSingleNip51List(
      kind,
      _eventSigner!,
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
  // coverage:ignore-end
}
