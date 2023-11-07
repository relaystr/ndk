[![Build Status](https://github.com/relaystr/dart_ndk/actions/workflows/tests.yaml/badge.svg?branch=isar)](https://github.com/relaystr/dart_ndk/actions?query=workflow%3A"tests"+branch%3Aisar)
[![Coverage](https://codecov.io/github/relaystr/dart_ndk/graph/badge.svg?token=OP3PZCXCML)](https://codecov.io/github/relaystr/dart_ndk)
[![Pub](https://img.shields.io/pub/v/dart_ndk.svg)](https://pub.dev/packages/dart_ndk)
[![License](https://img.shields.io/github/license/relaystr/dart_ndk.svg)](LICENSE.txt)


Dart Nostr Development Kit

## Features

### Gossip/outbox model of relay discovery and connectivity

The simplest characterization of the gossip model is just this: *reading the posts of people you follow from the relays that they wrote them to.*

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
      Filter(kinds: [Nip01Event.textNoteKind], authors: [pubKey]));
  await for (final event in query) {
    print(event);
  }
```

## Additional information
