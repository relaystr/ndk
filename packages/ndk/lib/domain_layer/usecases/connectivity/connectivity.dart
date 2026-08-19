import '../../entities/relay_connectivity.dart';
import '../relay_manager.dart';

/// get connectivity status \
/// & update ndk about your application connectivity for faster reconnects
class Connectivy {
  final RelayManager _relayManager;

  Connectivy(this._relayManager);

  /// streams connectivity status of every connection \
  /// a relay can hold several, so group by [RelayConnectivity.url] if needed
  Stream<List<RelayConnectivity>> get relayConnectivityChanges =>
      _relayManager.relayConnectivityChanges;

  /// forces all relays to reconnect \
  /// use this for faster reconnects based on your application/os connectivity \
  Future<void> tryReconnect() async {
    final relayConnectivities =
        _relayManager.globalState.relays.values.toList();

    for (final rConnectivity in relayConnectivities) {
      if (!rConnectivity.isConnected) {
        await _relayManager
            .reconnectConnection(
          rConnectivity.key,
          connectionSource: rConnectivity.relay.connectionSource,
          force: true,
        )
            .then((connected) {
          _relayManager.updateRelayConnectivity();
          if (connected) {
            _relayManager.reSubscribeInFlightSubscriptions(rConnectivity);
          }
        });
      }
    }
  }
}
