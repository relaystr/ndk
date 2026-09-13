# ndk_web_socket_client

A reconnecting WebSocket client based on `web_socket_client` 0.2.1, with
per-client native compression control.

```dart
import 'package:ndk_web_socket_client/ndk_web_socket_client.dart';

final socket = WebSocket(
  Uri.parse('wss://relay.example.com'),
  compressionEnabled: false,
);
socket.messages.listen(print);
socket.send('["REQ", "example", {"kinds": [1], "limit": 1}]');
// When finished:
socket.close();
```

`compressionEnabled` defaults to true. On native platforms, false passes
`CompressionOptions.compressionOff` on every connection attempt, including
automatic reconnects. This can reduce memory and codec overhead, but increases
bytes transferred for compressible traffic and may hurt performance on slow
links. Browsers control compression negotiation: this option is a no-op on web.

The original options remain available: protocols, headers, ping interval,
backoff, timeout, and browser binary type. The client exposes messages,
connection states, the selected protocol, send, and close. Headers and ping
interval apply on native platforms; binary type applies on web.

## Maintenance

See [UPSTREAM.md](UPSTREAM.md) for source provenance and the patch boundary.
The original MIT copyright and license are preserved in [LICENSE](LICENSE).

This package depends on the hosted `web_socket_client` package for public
connection and backoff types. It does not depend on NDK. Publish this package
before publishing an NDK version that depends on it. Workspace resolution is
used only for local monorepo development.
