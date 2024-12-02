import '../repositories/nostr_transport.dart';
import 'relay.dart';
import 'relay_info.dart';

/// Represents the connectivity of a relay.
class RelayConnectivity<T> {
  /// relay data including connection state
  final Relay relay;

  /// user facing relay info
  RelayInfo? relayInfo;

  /// transport layer for this relay, usually websocket
  NostrTransport? relayTransport;

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
