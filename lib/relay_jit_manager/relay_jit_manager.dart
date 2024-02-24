import 'package:dart_ndk/nips/nip01/event.dart';
import 'package:dart_ndk/nips/nip65/read_write_marker.dart';
import 'package:dart_ndk/relay.dart';
import 'package:dart_ndk/relay_jit_manager/relay_jit.dart';
import 'package:dart_ndk/relay_jit_manager/relay_jit_request_strategies/relay_jit_pubkey_strategy.dart';
import 'package:dart_ndk/relay_jit_manager/request_jit.dart';

List<Relay> SEED_RELAYs = [
  Relay('wss://relay.camelus.app'),
  Relay('wss://relay.snort.social'),
  Relay('wss://relay.damus.io'),
  Relay('wss://nostr.lu.ke'),
  Relay('wss://relay.mostr.pub')
];

class RelayJitManager {
  List<RelayJit> connectedRelays = [];

  /// If you request anything from the nostr network put it here and
  /// the relay jit manager will try to find the right relay and use it
  /// if no relay is found the request will be blasted to all connected relays (on start seed Relays)
  handleRequest(NostrRequestJit request,
      {desiredCoverage = 2, closeOnEOSE = true}) {
    /// ["REQ", <subscription_id>, <filters1>, <filters2>, ...]
    /// user can provide multiple filters
    for (var filter in request.filters) {
      // filter different types of filters/requests because each requires a different strategy

      if ((filter.authors != null && filter.authors!.isNotEmpty)) {
        RelayJitPubkeyStrategy.handleRequest(
          originalRequest: request,
          filter: filter,
          connectedRelays: connectedRelays,
          desiredCoverage: desiredCoverage,
          closeOnEOSE: closeOnEOSE,
          direction: ReadWriteMarker
              .writeOnly, // the author should write on the persons write relays
        );
        continue;
      }

      if (filter.pTags?.isNotEmpty != null && filter.pTags!.isNotEmpty) {
        RelayJitPubkeyStrategy.handleRequest(
          originalRequest: request,
          filter: filter,
          connectedRelays: connectedRelays,
          desiredCoverage: desiredCoverage,
          closeOnEOSE: closeOnEOSE,
          direction: ReadWriteMarker
              .readOnly, // others should mention on the persons read relays
        );
        continue;
      }

      if (filter.search != null) {
        throw UnimplementedError("search filter not implemented yet");
      }

      if (filter.ids != null) {
        throw UnimplementedError("ids filter not implemented yet");
      }

      throw UnimplementedError(
          "filter not implemented yet - strategy not found - blast to all connected relays");
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
      RelayJit relay, String pubkey, ReadWriteMarker direction) {
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
}