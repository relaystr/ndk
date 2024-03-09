import 'package:dart_ndk/cache_manager.dart';
import 'package:dart_ndk/nips/nip01/client_msg.dart';
import 'package:dart_ndk/nips/nip01/event.dart';
import 'package:dart_ndk/nips/nip01/filter.dart';
import 'package:dart_ndk/nips/nip65/nip65.dart';
import 'package:dart_ndk/nips/nip65/read_write_marker.dart';
import 'package:dart_ndk/nips/nip65/relay_ranking.dart';
import 'package:dart_ndk/relay_jit_manager/relay_jit.dart';
import 'package:dart_ndk/relay_jit_manager/relay_jit_manager.dart';
import 'package:dart_ndk/relay_jit_manager/request_jit.dart';

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

class RelayJitPubkeyStrategy {
  static handleRequest(
      {required NostrRequestJit originalRequest,
      required Filter filter,
      required List<RelayJit> connectedRelays,

      /// used to get the nip65 data if its necessary to look for not covered pubkeys
      required CacheManager cacheManager,
      required int desiredCoverage,
      required bool closeOnEOSE,
      required ReadWriteMarker direction,
      required List<String> ignoreRelays}) {
    List<String> combindedPubkeys = [
      ...?filter.authors,
      ...?filter.pTags
    ]; // not perfect but probably fine, request got split earlier

    // init coveragePubkeys
    List<CoveragePubkey> coveragePubkeys = [];
    for (var pubkey in combindedPubkeys) {
      coveragePubkeys
          .add(CoveragePubkey(pubkey, desiredCoverage, desiredCoverage));
    }

    for (var connectedRelay in connectedRelays) {
      var coveredPubkeysForRelay = <String>[];

      for (var coveragePubkey in coveragePubkeys) {
        if (RelayJitManager.doesRelayCoverPubkey(
            connectedRelay, coveragePubkey.pubkey, direction)) {
          coveredPubkeysForRelay.add(coveragePubkey.pubkey);
          coveragePubkey.missingCoverage--;
        }
      }

      connectedRelay.touched++;
      if (coveredPubkeysForRelay.isEmpty) {
        continue;
      }
      connectedRelay.touchUseful++;

      /// create splitFilter that only contains the pubkeys for the relay
      Filter splitFilter;
      if (filter.authors != null && filter.authors!.isNotEmpty) {
        splitFilter = filter.cloneWithAuthors(coveredPubkeysForRelay);
      } else if (filter.pTags != null && filter.pTags!.isNotEmpty) {
        splitFilter = filter.cloneWithPTags(coveredPubkeysForRelay);
      } else {
        throw Exception("filter does not contain authors or pTags");
      }

      _sendRequestToSocket(connectedRelay, originalRequest, [splitFilter]);

      // clear out fully covered pubkeys
      _removeFullyCoveredPubkeys(coveragePubkeys);
    }

    if (coveragePubkeys.isEmpty) {
      // we are done
      return;
    }

    //todo: resolve not covered pubkeys
    // look in nip65 data for not covered pubkeys
    List<Nip65> nip65Data = _getNip65Data(
        coveragePubkeys.map((e) => e.pubkey).toList(), cacheManager);

    // by finding the best relays to connect and send out the request
    RelayRankingResult relayRanking = rankRelays(
      direction: direction,
      searchingPubkeys: coveragePubkeys,
      eventData: nip65Data,
      boostRelays: connectedRelays.map((e) => e.url).toList(),
      ignoreRelays: ignoreRelays,
    );
  }

  static List<Nip65> _getNip65Data(
      List<String> pubkeys, CacheManager cacheManager) {
    List<Nip01Event> events =
        cacheManager.loadEvents(kinds: [Nip65.KIND], pubKeys: pubkeys);

    List<Nip65> nip65Data = [];
    for (var event in events) {
      nip65Data.add(Nip65.fromEvent(event));
    }
    return nip65Data;
  }
}

_removeFullyCoveredPubkeys(List<CoveragePubkey> coveragePubkeys) {
  coveragePubkeys.removeWhere((element) => element.missingCoverage == 0);
}

void _sendRequestToSocket(RelayJit connectedRelay,
    NostrRequestJit originalRequest, List<Filter> filters) {
  // check if the subscription already exists and if its need to be modified
  if (connectedRelay.hasActiveSubscription(originalRequest.id)) {
    // modify the existing subscription

    // add the filters to the existing subscription
    // to concat the filters is probably not the best way to do it but should be fine
    connectedRelay.activeSubscriptions[originalRequest.id]!.filters
        .addAll(filters);

    // send out the updated request
    connectedRelay.send(ClientMsg(
      ClientMsgType.REQ,
      id: originalRequest.id,
      filters: connectedRelay.activeSubscriptions[originalRequest.id]!.filters,
    ));

    return;
  }
  // create a new subscription
  // send out the request
  connectedRelay.send(ClientMsg(
    ClientMsgType.REQ,
    id: originalRequest.id,
    filters: filters,
  ));

  // link the request id to the relay
  connectedRelay.activeSubscriptions[originalRequest.id] =
      RelayActiveSubscription(originalRequest.id, filters, originalRequest);
}

class CoveragePubkey {
  final String pubkey;
  int desiredCoverage;
  int missingCoverage;

  CoveragePubkey(this.pubkey, this.desiredCoverage, this.missingCoverage);
}
