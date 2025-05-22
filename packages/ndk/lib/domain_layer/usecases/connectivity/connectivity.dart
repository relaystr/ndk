import '../../entities/relay_connectivity.dart';
import '../relay_manager.dart';

/// get connectivity status \
/// & update ndk about your application connectivity for faster reconnects
class Connectivy {
  final RelayManager _relayManager;

  Connectivy(this._relayManager);

  /// streams connectivity status of all relays \
  /// key: relay url/identifier
  /// value: relay connectivity
  Stream<Map<String, RelayConnectivity>> get relayConnectivityChanges =>
      _relayManager.relayConnectivityChanges;

  /// forces all relays to reconnect \
  /// use this for faster reconnects based on your application/os connectivity \
  Future<void> tryReconnect() async {
    for (final rConnectivity in _relayManager.globalState.relays.values) {
      if (!rConnectivity.isConnected) {
        await _relayManager
            .reconnectRelay(
          rConnectivity.url,
          connectionSource: rConnectivity.relay.connectionSource,
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
