import 'package:dart_ndk/nips/nip01/filter.dart';
import 'package:dart_ndk/relay.dart';
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
  static handleRequest(NostrRequestJit originalRequest, Filter filter,
      List<Relay> connectedRelays, int desiredCoverage, bool closeOnEOSE) {
    List<String> combindedPubkeys = [...?filter.authors, ...?filter.pTags];

    for (var connectedRelay in connectedRelays) {}
  }
}
