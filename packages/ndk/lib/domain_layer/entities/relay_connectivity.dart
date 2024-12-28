import 'dart:async';

import '../../shared/logger/logger.dart';
import '../repositories/nostr_transport.dart';
import 'relay.dart';
import 'relay_info.dart';
import 'relay_stats.dart';

/// Represents the connectivity of a relay.
class RelayConnectivity<T> {
  /// relay data including connection state
  final Relay relay;

  /// user facing relay info
  RelayInfo? relayInfo;

  /// relay stats
  RelayStats stats = RelayStats();

  /// transport layer for this relay, usually websocket
  NostrTransport? relayTransport;

  /// stream subscription
  StreamSubscription? _streamSubscription;

  /// starts listening on nostr transport
  void listen(
      void Function(dynamic) onData, {
        Function? onError,
        void Function()? onDone,
      }) {
    _streamSubscription = relayTransport!.listen(onData, onDone: onDone, onError: onError);
  }

  /// cancels stream subscription and closes relay transport
  Future<void> close() async {
    if (_streamSubscription != null) {
      _streamSubscription!.cancel();
    }
    if (relayTransport != null && relayTransport!.isOpen()) {
      Logger.log.t("closing $url webSocket");
      relayTransport!
          .close()
          .timeout(const Duration(seconds: 3), onTimeout: () {
        Logger.log.w("timeout while trying to close socket $url");
      });
    }
  }

  /// specific data that a engine might require for algorithms to work
  final T? specificEngineData;

  /// relay url/identifier
  String get url => relay.url;

  /// Creates a new relay connectivity.
  /// relayTransport == null => relay is not connected and is not in connecting state
  RelayConnectivity({
    required this.relay,
    this.relayInfo,
    this.relayTransport,
    this.specificEngineData,
  });

}
