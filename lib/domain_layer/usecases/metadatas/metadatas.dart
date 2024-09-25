import 'dart:convert';

import '../../../shared/logger/logger.dart';
import '../../../shared/nips/nip01/helpers.dart';
import '../../entities/filter.dart';
import '../../entities/metadata.dart';
import '../../entities/nip_01_event.dart';
import '../../entities/relay_set.dart';
import '../../repositories/cache_manager.dart';
import '../../repositories/event_signer.dart';
import '../relay_manager.dart';
import '../requests/requests.dart';

/// nostr metadata usecase
class Metadatas {
  Requests _requests;
  CacheManager _cacheManager;
  RelayManager _relayManager;

  Metadatas({
    required Requests requests,
    required CacheManager cacheManager,
    required RelayManager relayManager,
  })  : _relayManager = relayManager,
        _cacheManager = cacheManager,
        _requests = requests;

  Future<Metadata?> loadMetadata(
    String pubKey, {
    bool forceRefresh = false,
    int idleTimeout = RelayManager.DEFAULT_STREAM_IDLE_TIMEOUT,
  }) async {
    Metadata? metadata = _cacheManager.loadMetadata(pubKey);
    if (metadata == null || forceRefresh) {
      Metadata? loadedMetadata;
      try {
        await for (final event in _requests.query(
          name: 'metadata',
          timeout: idleTimeout,
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
    for (var pubKey in pubKeys) {
      Metadata? userMetadata = _cacheManager.loadMetadata(pubKey);
      if (userMetadata == null) {
        // TODO check if not too old (time passed since last refreshed timestamp)
        missingPubKeys.add(pubKey);
      }
    }
    Map<String, Metadata> metadatas = {};

    if (missingPubKeys.isNotEmpty) {
      Logger.log.d("loading missing user metadatas ${missingPubKeys.length}");
      try {
        await for (final event in (_requests.query(
                name: "load-metadatas",
                filters: [
                  Filter(authors: missingPubKeys, kinds: [Metadata.KIND])
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

  // coverage:ignore-start
  Future<Nip01Event?> _refreshMetadataEvent(EventSigner signer) async {
    Nip01Event? loaded;
    await for (final event in _requests.query(filters: [
      Filter(kinds: [Metadata.KIND], authors: [signer.getPublicKey()], limit: 1)
    ]).stream) {
      if (loaded == null || loaded.createdAt < event.createdAt) {
        loaded = event;
      }
    }
    return loaded;
  }

  /// *******************************************************************************************************************

  Future<Metadata> broadcastMetadata(Metadata metadata,
      Iterable<String> broadcastRelays, EventSigner eventSigner) async {
    Nip01Event? event = await _refreshMetadataEvent(eventSigner);
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
    await _relayManager.broadcastEvent(event, broadcastRelays, eventSigner);
    metadata.updatedAt = Helpers.now;
    metadata.refreshedTimestamp = Helpers.now;
    await _cacheManager.saveMetadata(metadata);

    return metadata;
  }
  // coverage:ignore-end

  /// *******************************************************************************************************************
}
