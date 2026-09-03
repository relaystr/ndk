import 'package:ndk/domain_layer/repositories/cache_manager.dart';
import 'package:ndk/shared/logger/logger.dart';
import 'package:ndk/shared/nips/nip01/client_msg.dart';
import 'package:ndk/domain_layer/entities/filter.dart';
import 'package:ndk/domain_layer/entities/read_write_marker.dart';
import 'package:ndk/shared/nips/nip65/relay_ranking.dart';
import 'package:ndk/domain_layer/usecases/jit_engine/jit_engine.dart';
import 'package:ndk/domain_layer/usecases/jit_engine/relay_jit_request_strategies/relay_jit_blast_all_strategy.dart';

import '../../../entities/global_state.dart';
import '../../../entities/jit_engine_relay_connectivity_data.dart';
import '../../../entities/relay_connection_key.dart';
import '../../../entities/relay_connectivity.dart';
import '../../../entities/request_state.dart';
import '../../../entities/connection_source.dart';
import '../../../entities/user_relay_list.dart';
import '../../relay_manager.dart';
import '../../user_relay_lists/user_relay_lists.dart';

/// Strategy Description:
///
/// 1.) look for connected relays that cover the pubkey
///
/// 2.) if pubkey match, split and send out the splitted (only that pubkey) request; decrease desiredCoverage for pubkey
///
/// 3.) add the original request id to subscriptionHolder
///
/// 4.) continue search
///
/// 5.) for not covered pubkeys look for relays in nip65 data, while boosting already connected relays
///
/// 6.) case=> if no relay is found, blast the request to all connected relays
///
/// 7.) case=> good relay found add to connected, and send out the request
///

class RelayJitPubkeyStrategy with Logger {
  static Future<void> handleRequest({
    required RequestState requestState,
    required GlobalState globalState,

    // specific filter (only one for this request)
    required Filter filter,
    required List<RelayConnectivity<JitEngineRelayConnectivityData>>
        connectedRelays,
    required List<String> bootstrapRelays,

    /// used to get the nip65 data if its necessary to look for not covered pubkeys
    required CacheManager cacheManager,
    required int desiredCoverage,
    required bool closeOnEOSE,
    required ReadWriteMarker direction,
    required List<String> ignoreRelays,
    required RelayManager relayManager,
  }) async {
    List<String> combindedPubkeys = [
      ...?filter.authors,
      ...?filter.pTags,
    ]; // not perfect but probably fine, request got split earlier

    // init coveragePubkeys
    List<CoveragePubkey> coveragePubkeys = [];

    for (var pubkey in combindedPubkeys) {
      coveragePubkeys.add(
        CoveragePubkey(pubkey, desiredCoverage, desiredCoverage),
      );
    }

    // look for connected relays that cover the pubkey
    for (var connectedRelay in connectedRelays) {
      var coveredPubkeysForRelay = <String>[];

      for (var coveragePubkey in coveragePubkeys) {
        if (JitEngine.doesRelayCoverPubkey(
          connectedRelay,
          coveragePubkey.pubkey,
          direction,
        )) {
          coveredPubkeysForRelay.add(coveragePubkey.pubkey);
          coveragePubkey.missingCoverage--;
        }
      }

      connectedRelay.stats.touched++;
      if (coveredPubkeysForRelay.isEmpty) {
        continue;
      }
      connectedRelay.stats.touchUseful++;

      /// create splitFilter that only contains the pubkeys for the relay
      Filter splitFilter = _splitFilter(filter, coveredPubkeysForRelay);

      _sendRequestToSocket(
        connectedRelay,
        requestState,
        [splitFilter],
        globalState,
        relayManager,
      );

      // clear out fully covered pubkeys
      _removeFullyCoveredPubkeys(coveragePubkeys);
    }

    if (coveragePubkeys.isEmpty) {
      // we are done
      // all pubkeys are covered by already connected relays
      return;
    }

    final unresolvedPubkeys = await _findRelaysForUnresolvedPubkeys(
      requestState: requestState,
      globalState: globalState,
      relayManger: relayManager,
      filter: filter,
      coveragePubkeys: coveragePubkeys,
      connectedRelays: connectedRelays,
      cacheManager: cacheManager,
      desiredCoverage: desiredCoverage,
      direction: direction,
      ignoreRelays: ignoreRelays,
      closeOnEOSE: closeOnEOSE,
    );

    coveragePubkeys
      ..clear()
      ..addAll(unresolvedPubkeys);

    if (coveragePubkeys.isEmpty) {
      // we are done
      return;
    }

    Filter notFoundFilter = _splitFilter(
      filter,
      coveragePubkeys.map((e) => e.pubkey).toList(),
    ); // split the filter
    //  send out not found request to all connected relays
    RelayJitBlastAllStrategy.handleRequest(
      requestState: requestState,
      relayManager: relayManager,
      filter: notFoundFilter,
      connectedRelays: connectedRelays,
      closeOnEOSE: closeOnEOSE,
      bootstrapRelays: bootstrapRelays,
    );
  }

  // looks in nip65 data for not covered pubkeys
  // the result is relay candidates
  // connects to these candidates and sends out the request
  static Future<List<CoveragePubkey>> _findRelaysForUnresolvedPubkeys({
    required RelayManager relayManger,
    required RequestState requestState,
    required GlobalState globalState,
    required Filter filter,
    required List<CoveragePubkey> coveragePubkeys,
    required List<RelayConnectivity<JitEngineRelayConnectivityData>>
        connectedRelays,
    required CacheManager cacheManager,
    required int desiredCoverage,
    required ReadWriteMarker direction,
    required List<String> ignoreRelays,
    required bool closeOnEOSE,
  }) async {
    /// ### resolve not covered pubkeys ###
    // look in nip65 data for not covered pubkeys
    late final List<UserRelayList> nip65Data;
    try {
      nip65Data = await UserRelayLists.getUserRelayListCacheLatest(
        pubkeys: coveragePubkeys.map((e) => e.pubkey).toList(),
        cacheManager: cacheManager,
      );
    } catch (error, stackTrace) {
      Logger.log.w(
        () => "Could not load relay lists; falling back to bootstrap relays",
        error: error,
        stackTrace: stackTrace,
      );
      return coveragePubkeys
          .map(
            (pubkey) => CoveragePubkey(
              pubkey.pubkey,
              pubkey.desiredCoverage,
              pubkey.missingCoverage,
            ),
          )
          .toList();
    }

    // by finding the best relays to connect and send out the request
    RelayRankingResult relayRanking = rankRelays(
      direction: direction,
      searchingPubkeys: coveragePubkeys,
      eventData: nip65Data,
      boostRelays: connectedRelays.map((e) => e.url).toList(),
      ignoreRelays: ignoreRelays,
    );

    final unresolvedByPubkey = {
      for (final pubkey in relayRanking.notCoveredPubkeys)
        pubkey.pubkey: pubkey,
    };

    void markCandidateUnavailable(RelayRanking relayCandidate) {
      for (final coveredPubkey in relayCandidate.coveredPubkeys) {
        final unresolved = unresolvedByPubkey.putIfAbsent(
          coveredPubkey.pubkey,
          () => CoveragePubkey(coveredPubkey.pubkey, desiredCoverage, 0),
        );
        unresolved.missingCoverage++;
      }
    }

    // Start every candidate immediately. Awaiting inside this loop would make
    // an unreachable relay consume the full connection timeout before the next
    // useful candidate is even attempted.
    final connectionAttempts = <Future<void>>[];
    for (final relayCandidate in relayRanking.ranking) {
      if (relayCandidate.score <= 0) {
        continue;
      }
      connectionAttempts.add(() async {
        // check if the relayCandidate is already connected
        final alreadyConnected = connectedRelays.any(
          (element) => element.url == relayCandidate.relayUrl,
        );

        if (!alreadyConnected) {
          final success = await relayManger.connectRelay(
            dirtyUrl: relayCandidate.relayUrl,
            connectionSource: ConnectionSource.pubkeyStrategy,
          );
          if (!success.first) {
            markCandidateUnavailable(relayCandidate);
            Logger.log.w(
              () =>
                  "Could not connect to relay: ${relayCandidate.relayUrl} - errorHandling",
            );
            return;
          }
        }

        final myRelayConnectivity = globalState
            .relays[RelayConnectionKey.anonymous(relayCandidate.relayUrl)];
        if (myRelayConnectivity
            is! RelayConnectivity<JitEngineRelayConnectivityData>) {
          markCandidateUnavailable(relayCandidate);
          return;
        }

        myRelayConnectivity.specificEngineData!.addPubkeysToAssignedPubkeys(
          relayCandidate.coveredPubkeys.map((e) => e.pubkey).toList(),
          direction,
        );

        _sendRequestToSocket(
          myRelayConnectivity,
          requestState,
          [
            _splitFilter(
              filter,
              relayCandidate.coveredPubkeys.map((e) => e.pubkey).toList(),
            ),
          ],
          globalState,
          relayManger,
        );
      }());
    }
    await Future.wait(connectionAttempts);

    return unresolvedByPubkey.values
        .where((pubkey) => pubkey.missingCoverage > 0)
        .toList();
  }

  // adds the relay to ignoreRelays and retries the request for assigned pubkeys to this relay
  // static void _connectionErrorHandling({
  //   required RelayJit errorRelay,
  //   required RequestState requestState,
  //   required Filter filter,
  //   required List<RelayJit> connectedRelays,
  //   required CacheManager cacheManager,
  //   required int desiredCoverage,
  //   required bool closeOnEOSE,
  //   required ReadWriteMarker direction,
  //   required List<String> ignoreRelays,
  //   required Function(Nip01Event, RequestState) onMessage,
  // }) {
  //   Logger.log.w(
  //       "_connectionErrorHandling Error on connection to relay: ${errorRelay.url}");
  //   // cleanup
  //   connectedRelays.remove(errorRelay);

  //   // add to ignoreRelays
  //   ignoreRelays.add(errorRelay.url);

  //   List<CoveragePubkey> unresolvedPubkeysOfRelay = errorRelay.assignedPubkeys
  //       .map((e) => CoveragePubkey(e.pubkey, 1, 1))
  //       .toList();

  //   _findRelaysForUnresolvedPubkeys(
  //     requestState: requestState,
  //     filter: filter,
  //     coveragePubkeys: unresolvedPubkeysOfRelay,
  //     connectedRelays: connectedRelays,
  //     cacheManager: cacheManager,
  //     desiredCoverage: desiredCoverage,
  //     direction: direction,
  //     ignoreRelays: ignoreRelays,
  //     closeOnEOSE: closeOnEOSE,
  //     onMessage: onMessage,
  //   );
  // }
}

void _removeFullyCoveredPubkeys(List<CoveragePubkey> coveragePubkeys) {
  coveragePubkeys.removeWhere((element) => element.missingCoverage == 0);
}

void _sendRequestToSocket(
  RelayConnectivity<JitEngineRelayConnectivityData> connectedRelay,
  RequestState requestState,
  List<Filter> filters,
  GlobalState globalState,
  RelayManager relayManager,
) {
  if (!identical(globalState.inFlightRequests[requestState.id], requestState)) {
    return;
  }
  // link the request id to the relay
  relayManager.registerRelayRequest(
    reqId: requestState.id,
    connectionKey: connectedRelay.key,
    filters: filters,
  );

  // send out the request
  relayManager.send(
    connectedRelay,
    ClientMsg(ClientMsgType.kReq, id: requestState.id, filters: filters),
  );
}

Filter _splitFilter(Filter filter, List<String> pubkeysToInclude) {
  if (filter.authors != null && filter.authors!.isNotEmpty) {
    return filter.cloneWithAuthors(pubkeysToInclude);
  } else if (filter.pTags != null && filter.pTags!.isNotEmpty) {
    return filter.cloneWithPTags(pubkeysToInclude);
  } else {
    throw Exception("filter does not contain authors or pTags");
  }
}

class CoveragePubkey {
  final String pubkey;
  int desiredCoverage;
  int missingCoverage;

  CoveragePubkey(this.pubkey, this.desiredCoverage, this.missingCoverage);

  @override
  operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CoveragePubkey &&
        other.pubkey == pubkey &&
        other.desiredCoverage == desiredCoverage &&
        other.missingCoverage == missingCoverage;
  }

  @override
  int get hashCode =>
      pubkey.hashCode ^ desiredCoverage.hashCode ^ missingCoverage.hashCode;
}
