// ignore_for_file: constant_identifier_names

/// defaults used by a low level nostr request
class RequestDefaults {
  /// timeout for query streams
  static const int DEFAULT_STREAM_IDLE_TIMEOUT = 5;

  /// websocket connection timeout
  static const int DEFAULT_WEB_SOCKET_CONNECT_TIMEOUT = 3;

  /// desiredCoverage: The number of relays per pubkey to subscribe/query to
  static const int DEFAULT_BEST_RELAYS_MIN_COUNT = 2;

  /// retry interval for relay connections
  static const int FAIL_RELAY_CONNECT_TRY_AFTER_SECONDS = 60;

  /// websocket ping interval
  static const int WEB_SOCKET_PING_INTERVAL_SECONDS = 3;
}
