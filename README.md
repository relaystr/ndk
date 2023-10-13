<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->


[![Build Status](https://github.com/relaystr/dart_ndk/workflows/tests/badge.svg)](https://github.com/relaystr/dart_ndk/actions?query=workflow%3A"tests"+branch%3Amaster)
[![Coverage](https://codecov.io/github/relaystr/dart_ndk/graph/badge.svg?token=OP3PZCXCML)](https://codecov.io/github/relaystr/dart_ndk)
[![Pub](https://img.shields.io/pub/v/dart_ndk.svg)](https://pub.dev/packages/dart_ndk)

Dart Nostr Development Kit

## Features

- gossip/outbox model of relay discovery and connectivity
<img src="https://mikedilger.com/gossip-model/gossip-model.png" style="width:400px; height:400px"/>
more details on https://mikedilger.com/gossip-model/

## Getting started
Add the following to your `pubspec.yaml` file:

```yaml
dependencies:
  dart_nostr: any
```

## Usage


```dart
  RelayManager manager = RelayManager();
  
  await manager.connect();
  
  Stream<Nip01Event> query = await manager.query(
      Filter(kinds: [Nip01Event.textNoteKind], authors: [key4.publicKey]));
  await for (final event in query.take(4)) {
    print(event);
  }
```

## Additional information
