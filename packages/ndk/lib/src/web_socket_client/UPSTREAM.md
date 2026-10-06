# Internal WebSocket client

Source: https://github.com/felangel/web_socket_client
Baseline: published web_socket_client 0.2.1 from pub.dev.
License: MIT, Copyright (c) 2024 Felix Angelov (see LICENSE).

This directory contains NDK's internal copy of the upstream client. The original
library layout is preserved: web_socket_client.dart exports src/web_socket.dart,
connection types, backoff strategies, and platform-specific connectors/adapters.
It is not exported from package:ndk/ndk.dart and is not a separate pub package.

The wrapper, connection state equality, backoff algorithms, protocols, headers,
ping interval, timeout, browser binary type, and selected protocol getter retain
upstream behavior. Dart and web_socket_channel still implement the WebSocket
protocol itself.

Deliberate differences from 0.2.1:

- Imports point to this internal NDK directory.
- WebSocket captures compressionEnabled (default true) and passes it to each
  connector on every connection attempt, including reconnects.
- The IO connector maps that boolean to Dart's compressionDefault/compressionOff.
- Web and unsupported-platform connectors accept the option without using it.

All connection types and exponential, linear, and constant backoff strategies
are local. Neither web_socket_client nor ndk_web_socket_client is a dependency.
Keep future changes small and record any additional behavioral deviations here.

Tests under test/data_layer/web_socket_client/ include upstream wrapper,
connection-state, and backoff tests, plus a native compression integration test.
test/relays/websocket_compression_test.dart exercises NdkConfig and both engines.

When adopting an upstream fix, compare it against this baseline, preserve the
documented compression changes, and run the client and relay tests plus a web
compilation check. Dependency updates cannot update this internal client.
