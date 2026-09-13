# Upstream source

Source: https://github.com/felangel/web_socket_client
Baseline: published web_socket_client 0.2.1 from pub.dev.
License: MIT, Copyright (c) 2024 Felix Angelov (see LICENSE).

Copied files retain their upstream paths: `lib/src/web_socket.dart`,
`lib/src/connection.dart`, platform connectors/channel adapters, and
`test/src/web_socket_test.dart`.

Deliberate differences:

- Package imports point to ndk_web_socket_client.
- The public library re-exports upstream public types except WebSocket.
- ConnectionController uses upstream's public Connection rather than copying it.
- WebSocket captures a boolean compressionEnabled (default true) and passes it
  to the platform connector on every attempt.
- The IO connector maps that boolean to Dart's compressionDefault/compressionOff.
- Web and unsupported-platform connectors accept the option without using it.

Backoff strategies, connection state classes, and Connection remain supplied by
the hosted upstream dependency. Do not import its private `src` libraries.

When updating the baseline, compare copied files with the new upstream release,
reapply the documented changes, and run both upstream wrapper tests and local
compression tests. Dependency updates alone do not update the copied wrapper.
