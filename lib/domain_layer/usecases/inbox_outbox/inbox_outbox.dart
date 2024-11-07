import '../../entities/filter.dart';
import '../../entities/nip_01_event.dart';
import '../../entities/nip_65.dart';
import '../../entities/read_write_marker.dart';
import '../../repositories/cache_manager.dart';
import '../../repositories/event_signer.dart';
import '../broadcast/broadcast.dart';
import '../requests/requests.dart';

/// InboxOutbox usecase
class InboxOutbox {
  final CacheManager _cacheManager;
  final Requests? _requests;
  final Broadcast? _broadcast;
  final EventSigner? _signer;

  /// creates a new [InboxOutbox] instance
  InboxOutbox({
    required CacheManager cacheManager,
    Requests? requests,
    Broadcast? broadcast,
    EventSigner? signer,
  })  : _cacheManager = cacheManager,
        _broadcast = broadcast,
        _requests = requests,
        _signer = signer;

  _checkSigner() {
    if (_signer == null) {
      throw "cannot sign without a signer";
    }
  }

  _checkRequests() {
    if (_requests == null) {
      throw "cannot make requests without requests";
    }
  }

  _checkBroadcast() {
    if (_broadcast == null) {
      throw "cannot broadcast without broadcast";
    }
  }

  /// careful when using this method,
  /// it will overwrite the current inbox/outbox data. \
  ///
  /// this method writes to cache and broadcasts the new data to the network
  ///
  /// [nip65Data] the new data to be set
  /// you can use [customRelays] to broadcast to specific relays
  /// [returns] the new nip65 data
  Future<Nip65> setInboxOutbox(
    Nip65 newNip65Data, {
    Iterable<String>? customRelays,
  }) async {
    _checkBroadcast();
    await _cacheManager.saveEvent(newNip65Data.toEvent());
    final response = _broadcast!.broadcast(
      nostrEvent: newNip65Data.toEvent(),
      specificRelays: customRelays,
    );

    await response.publishDone;

    return newNip65Data;
  }

  /// adds a relay to the nip65 data
  Future<Nip65> addRelay({
    required String relayUrl,
    required ReadWriteMarker readWriteMarker,
  }) async {
    _checkSigner();

    final selfPubkey = _signer!.getPublicKey();
    final nip65Data = await getNip65(pubkeys: [selfPubkey], forceRefresh: true);

    if (nip65Data.isEmpty) {
      throw "no nip65 data found";
    }

    final myNip65 = nip65Data.first;

    myNip65.relays[relayUrl] = readWriteMarker;

    return setInboxOutbox(myNip65);
  }

  /// reads the latest nip65 data network and cache
  /// [pubkeys] pubkeys you want nip65 data for
  /// [forceRefresh] if true, will ignore cache and fetch from network
  /// [returns] the latest nip65 data if list is empty, no data was found
  Future<List<Nip65>> getNip65({
    required List<String> pubkeys,
    bool forceRefresh = false,
  }) async {
    _checkRequests();
    List<Nip65> nip65Cache = await getNip65CacheLatest(
      pubkeys: pubkeys,
      cacheManager: _cacheManager,
    );

    if (nip65Cache.isNotEmpty && !forceRefresh) {
      return nip65Cache;
    }

    final query = _requests!.query(
      filters: [
        Filter(
          kinds: [Nip65.KIND],
          authors: pubkeys,
          limit: 1,
        )
      ],
      cacheRead: false,
      cacheWrite: true,
    );

    final nip65NetworkEvents = await query.future;

    List<Nip65> nip65Network = [];

    for (final event in nip65NetworkEvents) {
      nip65Network.add(Nip65.fromEvent(event));
    }

    return _filterLatest([...nip65Cache, ...nip65Network]);
  }

  /// reads the latest nip65 data from cache
  /// [pubkeys] pubkeys you want nip65 data for
  /// [cacheManger] the cache manager you want to use
  static Future<List<Nip65>> getNip65CacheLatest({
    required List<String> pubkeys,
    required CacheManager cacheManager,
  }) async {
    List<Nip01Event> events =
        await cacheManager.loadEvents(kinds: [Nip65.KIND], pubKeys: pubkeys);

    List<Nip65> nip65Data =
        _filterLatest(events.map((e) => Nip65.fromEvent(e)).toList());

    return nip65Data;
  }

  /// reads the latest nip65 data from cache
  /// [pubkeys] pubkeys you want nip65 data for
  /// [cacheManger] the cache manager you want to use
  static Future<Nip65?> getNip65CacheLatestSingle({
    required String pubkey,
    required CacheManager cacheManager,
  }) async {
    final data = await getNip65CacheLatest(
      pubkeys: [pubkey],
      cacheManager: cacheManager,
    );
    if (data.isEmpty) {
      return null;
    }
    return data.first;
  }
}

/// return only the latest nip65 data for each pubkey
List<Nip65> _filterLatest(List<Nip65> uncleanData) {
  final List<Nip65> cleanData = [];

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
