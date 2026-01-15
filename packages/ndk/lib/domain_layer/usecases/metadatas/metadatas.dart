import 'dart:convert';

import '../../../config/metadata_defaults.dart';
import '../../../shared/logger/logger.dart';
import '../../../shared/nips/nip01/helpers.dart';
import '../../entities/filter.dart';
import '../../entities/metadata.dart';
import '../../entities/nip_01_event.dart';
import '../../entities/relay_set.dart';
import '../../repositories/cache_manager.dart';
import '../../repositories/event_signer.dart';
import '../accounts/accounts.dart';
import '../broadcast/broadcast.dart';
import '../requests/requests.dart';

/// nostr metadata usecase
class Metadatas {
  final Requests _requests;
  final CacheManager _cacheManager;
  final Broadcast _broadcast;
  final Accounts _accounts;

  /// create a new instance of Metadatas
  Metadatas({
    required Requests requests,
    required CacheManager cacheManager,
    required Broadcast broadcast,
    required Accounts accounts,
  })  : _cacheManager = cacheManager,
        _requests = requests,
        _accounts = accounts,
        _broadcast = broadcast;

  void _checkSigner() {
    if (!_accounts.canSign) {
      throw "Not logged in";
    }
  }

  EventSigner get _signer {
    return _accounts.getLoggedAccount()!.signer;
  }

  /// load metadata for a pubkey
  /// if [forceRefresh] is true, it will use the network to refresh the metadata
  Future<Metadata?> loadMetadata(
    String pubKey, {
    bool forceRefresh = false,
    Duration idleTimeout = METADATA_IDLE_TIMEOUT,
  }) async {
    Metadata? metadata =
        !forceRefresh ? await _cacheManager.loadMetadata(pubKey) : null;
    if (metadata == null || forceRefresh) {
      Metadata? loadedMetadata;
      try {
        await for (final event in _requests.query(
          name: 'metadata',
          cacheRead: !forceRefresh,
          timeout: idleTimeout,
          filters: [
            Filter(kinds: [Metadata.kKind], authors: [pubKey], limit: 1)
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
        await _cacheManager.saveMetadata(loadedMetadata);
        metadata = loadedMetadata;
      }
    }
    return metadata;
  }

  // TODO try to use generic query with cacheRead/Write mechanism
  Future<List<Metadata>> loadMetadatas(List<String> pubKeys, RelaySet? relaySet,
      {Function(Metadata)? onLoad}) async {
    List<String> missingPubKeys = [];
    Map<String, Metadata> metadatas = {};
    for (var pubKey in pubKeys) {
      Metadata? userMetadata = await _cacheManager.loadMetadata(pubKey);
      if (userMetadata == null) {
        // TODO check if not too old (time passed since last refreshed timestamp)
        missingPubKeys.add(pubKey);
      } else {
        metadatas[pubKey] = userMetadata;
      }
    }

    if (missingPubKeys.isNotEmpty) {
      Logger.log.d("loading missing user metadatas ${missingPubKeys.length}");
      try {
        await for (final event in (_requests.query(
                name: "load-metadatas",
                filters: [
                  Filter(authors: missingPubKeys, kinds: [Metadata.kKind])
                ],
                relaySet: relaySet))
            .stream
            .timeout(const Duration(seconds: 5), onTimeout: (sink) {
          Logger.log.w("timeout metadatas.length:${metadatas.length}");
        })) {
          if (metadatas[event.pubKey] == null ||
              metadatas[event.pubKey]!.updatedAt! < event.createdAt) {
            metadatas[event.pubKey] = Metadata.fromEvent(event);
            metadatas[event.pubKey]!.refreshedTimestamp = Helpers.now;
            await _cacheManager.saveMetadata(metadatas[event.pubKey]!);
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

  Future<Nip01Event?> _refreshMetadataEvent() async {
    _checkSigner();
    Nip01Event? loaded;
    await for (final event in _requests.query(filters: [
      Filter(
          kinds: [Metadata.kKind], authors: [_signer.getPublicKey()], limit: 1)
    ]).stream) {
      if (loaded == null || loaded.createdAt < event.createdAt) {
        loaded = event;
      }
    }
    return loaded;
  }

  /// *******************************************************************************************************************

  Future<Metadata> broadcastMetadata(
    Metadata metadata, {
    Iterable<String>? specificRelays,
  }) async {
    _checkSigner();
    Nip01Event? event = await _refreshMetadataEvent();
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
    final bResult = _broadcast.broadcast(
      nostrEvent: event,
      specificRelays: specificRelays,
    );

    await bResult.broadcastDoneFuture;

    metadata.updatedAt = Helpers.now;
    metadata.refreshedTimestamp = Helpers.now;
    await _cacheManager.saveMetadata(metadata);

    return metadata;
  }

  /// *******************************************************************************************************************
}
