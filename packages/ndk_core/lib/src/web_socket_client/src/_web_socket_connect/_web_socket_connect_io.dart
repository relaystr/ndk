import 'dart:async';
import 'dart:io';

/// Create a WebSocket connection.
Future<WebSocket> connect(
  String url, {
  Iterable<String>? protocols,
  Map<String, dynamic>? headers,
  Duration? pingInterval,
  String? binaryType,
  bool compressionEnabled = true,
  Future<void>? abortTrigger,
}) async {
  // Each pending handshake owns its HTTP client. Closing it can abort an
  // accepted TCP/TLS connection whose peer never answers the HTTP upgrade.
  // An upgraded WebSocket is detached from the HTTP client and stays alive.
  final client = HttpClient()..userAgent = WebSocket.userAgent;
  var finished = false;
  if (abortTrigger != null) {
    unawaited(
      abortTrigger.then((_) {
        if (!finished) client.close(force: true);
      }),
    );
  }
  try {
    return await WebSocket.connect(
        url,
        headers: headers,
        protocols: protocols,
        customClient: client,
        compression: compressionEnabled
            ? CompressionOptions.compressionDefault
            : CompressionOptions.compressionOff,
      )
      ..pingInterval = pingInterval;
  } finally {
    finished = true;
    client.close(force: true);
  }
}
