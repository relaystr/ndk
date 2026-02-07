// ignore_for_file: constant_identifier_names

import 'package:ndk/src/version.dart';

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

  /// query timeout
  static const Duration DEFAULT_QUERY_TIMEOUT = Duration(seconds: 10);

  /// default User-Agent header value used for websocket connections
  static const String DEFAULT_USER_AGENT = "dart-NDK/$packageVersion";

  /// default timeout for AUTH callbacks (how long to wait for AUTH OK)
  static const Duration DEFAULT_AUTH_CALLBACK_TIMEOUT = Duration(seconds: 30);

  /// default timeout for bunker/NIP-46 remote signer requests
  static const Duration DEFAULT_BUNKER_REQUEST_TIMEOUT = Duration(minutes: 3);
}
