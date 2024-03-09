import 'package:dart_ndk/cache_manager.dart';
import 'package:dart_ndk/mem_cache_manager.dart';
import 'package:dart_ndk/nips/nip01/event.dart';
import 'package:dart_ndk/nips/nip65/read_write_marker.dart';
import 'package:dart_ndk/relay.dart';
import 'package:dart_ndk/relay_jit_manager/relay_jit.dart';
import 'package:dart_ndk/relay_jit_manager/relay_jit_config.dart';
import 'package:dart_ndk/relay_jit_manager/relay_jit_request_strategies/relay_jit_blast_all_strategy.dart';
import 'package:dart_ndk/relay_jit_manager/relay_jit_request_strategies/relay_jit_pubkey_strategy.dart';
import 'package:dart_ndk/relay_jit_manager/request_jit.dart';
import 'package:logger/logger.dart';
import 'dart:developer' as developer;

var logger = Logger(
  printer: PrettyPrinter(),
);

class RelayJitManager {
  List<RelayJit> connectedRelays = [];
  late CacheManager cacheManager;

  RelayJitManager({
    List<String> seedRelays = RelayJitConfig.SEED_RELAYS,
    CacheManager? cacheManager,
  }) {
    this.cacheManager = cacheManager ?? MemCacheManager();

    // init seed relays
    for (var seedRelay in seedRelays) {
      var relay = RelayJit(seedRelay);
      relay.connect().then((success) => {
            if (success) {connectedRelays.add(relay)}
          });
    }
  }

  /// If you request anything from the nostr network put it here and
  /// the relay jit manager will try to find the right relay and use it
  /// if no relay is found the request will be blasted to all connected relays (on start seed Relays)
  void handleRequest(
    NostrRequestJit request, {
    desiredCoverage = 2,
    closeOnEOSE = true,
    List<String> ignoreRelays = const [],
  }) {
    //clean ignore relays
    List<String> cleanIgnoreRelays = _cleanRelayUrls(ignoreRelays);

    /// ["REQ", <subscription_id>, <filters1>, <filters2>, ...]
    /// user can provide multiple filters
    for (var filter in request.filters) {
      // filter different types of filters/requests because each requires a different strategy

      if ((filter.authors != null && filter.authors!.isNotEmpty)) {
        RelayJitPubkeyStrategy.handleRequest(
          originalRequest: request,
          cacheManager: cacheManager,
          filter: filter,
          connectedRelays: connectedRelays,
          desiredCoverage: desiredCoverage,
          closeOnEOSE: closeOnEOSE,
          direction: ReadWriteMarker
              .writeOnly, // the author should write on the persons write relays
          ignoreRelays: cleanIgnoreRelays,
        );
        continue;
      }

      if (filter.pTags?.isNotEmpty != null && filter.pTags!.isNotEmpty) {
        RelayJitPubkeyStrategy.handleRequest(
          originalRequest: request,
          cacheManager: cacheManager,
          filter: filter,
          connectedRelays: connectedRelays,
          desiredCoverage: desiredCoverage,
          closeOnEOSE: closeOnEOSE,
          direction: ReadWriteMarker
              .readOnly, // others should mention on the persons read relays
          ignoreRelays: cleanIgnoreRelays,
        );
        continue;
      }

      if (filter.search != null) {
        throw UnimplementedError("search filter not implemented yet");
      }

      if (filter.ids != null) {
        throw UnimplementedError("ids filter not implemented yet");
      }

      /// unknown filter strategy, blast to all connected relays
      RelayJitBlastAllStrategy.handleRequest(
        originalRequest: request,
        filter: filter,
        connectedRelays: connectedRelays,
        closeOnEOSE: closeOnEOSE,
      );
    }
  }

  handleEventPublish(Nip01Event nostrEvent) {
    throw UnimplementedError();
  }

  // close a relay subscription, the relay connection will be kept open and closed automatically (garbage collected)
  handleCloseSubscription(String id) {
    throw UnimplementedError();
  }

  static doesRelayCoverPubkey(
    RelayJit relay,
    String pubkey,
    ReadWriteMarker direction,
  ) {
    for (RelayJitAssignedPubkey assignedPubkey in relay.assignedPubkeys) {
      if (assignedPubkey.pubkey == pubkey) {
        switch (direction) {
          case ReadWriteMarker.readOnly:
            return assignedPubkey.direction.isRead;
          case ReadWriteMarker.writeOnly:
            return assignedPubkey.direction.isWrite;
          case ReadWriteMarker.readWrite:
            return assignedPubkey.direction == ReadWriteMarker.readWrite;
          default:
            return false;
        }
      }
    }
    return false;
  }

  _cleanRelayUrls(List<String> urls) {
    List<String> cleanUrls = [];
    for (var url in urls) {
      String? cleanUrl = Relay.cleanUrl(url);
      if (cleanUrl == null) {
        continue;
      }
      cleanUrls.add(cleanUrl);
    }
    return cleanUrls;
  }
}
