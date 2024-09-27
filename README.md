[![Build Status](https://github.com/relaystr/dart_ndk/actions/workflows/tests.yaml/badge.svg?branch=master)](https://github.com/relaystr/dart_ndk/actions?query=workflow%3A"tests"+branch%3Amaster)
[![Coverage](https://codecov.io/github/relaystr/dart_ndk/graph/badge.svg?token=OP3PZCXCML)](https://codecov.io/github/relaystr/dart_ndk)
[![Pub](https://img.shields.io/pub/v/ndk.svg)](https://pub.dev/packages/ndk)
[![License](https://img.shields.io/github/license/relaystr/dart_ndk.svg)](LICENSE.txt)

# Dart Nostr Development Kit (NDK)

NDK (Nostr Development Kit) is a Dart library designed to enhance the Nostr development experience. It provides streamlined solutions for common use cases and abstracts away complex relay management, making it ideal for building constrained Nostr clients, particularly on mobile devices.\
NDK implements the inbox/outbox (gossip) model by default, optimizing network usage and improving performance.

$~~~~~~~~~~~$

## Prerequisites

- android SDK (also for desktop builds)
- flutter SDK
- rust ( + toolchain for target)

Rust toolchain android:

```bash
rustup target add \
    aarch64-linux-android \
    armv7-linux-androideabi \
    x86_64-linux-android \
    i686-linux-android
```

Rust toolchain ios:

```bash
# 64 bit targets (real device & simulator):
rustup target add aarch64-apple-ios x86_64-apple-ios
# New simulator target for Xcode 12 and later
rustup target add aarch64-apple-ios-sim
# 32 bit targets (you probably don't need these):
rustup target add armv7-apple-ios i386-apple-ios
```

## Getting started

### Install

```bash
flutter pub add ndk
```

### Import

```dart
import 'package:ndk/ndk.dart';
```

## Usage

> **usage [examples](https://github.com/relaystr/dart_ndk/tree/master/example)**

```dart
import 'package:ndk/ndk.dart';

// init
Ndk ndk = Ndk(
  NdkConfig(
    eventVerifier: RustEventVerifier(),
    cache: MemCacheManager(),
  ),
);

// query
NdkResponse response = ndk.requests.query(
  filters: [
    Filter(
      authors: ['hexPubkey']
      kinds: [Nip01Event.TEXT_NODE_KIND],
      limit: 10,
    ),
  ],
);

// result
await for (final event in response.stream) {
  print(event);
}
```

$~~~~~~~~~~~$

---

# Features / what does dart_ndk do? (clear borders)

- return nostr data based on filters (any kind).
- automatically discover the best relays to satisfy the provided request (using gossip)
- specify desired coverage on each request (e.g. x relays per pubkey)
- publish nostr events to optimal relays or explicit relays
- cache responses to save network bandwidth
- stream directly from cache and network (if needed)
- query and subscription, e.g., get data once; subscribe to data.
- plugin cache interface, bring your own db or use included ones: `inMemory`
- plug in verifier interface, bring your own event verifier, or use included ones: `bip340, rust`
- plug in event signer interface, bring your own event signer, or use included ones: `bip340, amber`
- contact list support, you can convert nostr_event to contact_list
- nip51 list support, you can convert nostr_event to nip51_list

## not Included

- ready to use feeds, you have to build them on your own (🚫 not planned)
- create && manage keypairs. You have to provide them (🚫 not planned)
- file upload (🔜 planned)
- nip05 caching (🔜 planned)
- threading, you can do this on your own if you move dart_ndk or only the event_verifier into its own thread (🔜 planned)
- support for request overrides (you have to close and reopen requests) (🤔 unsure)

---

### Gossip/outbox model of relay discovery and connectivity

The simplest characterization of the gossip model is just this: _reading the posts of people you follow from the relays that they wrote them to._

<img src="https://mikedilger.com/gossip-model/gossip-model.png" style="width:400px; height:400px"/>

more details on https://mikedilger.com/gossip-model/

## NIPs

- [x] Event Builders / WebSocket Subscriptions ([NIP-01](https://github.com/nostr-protocol/nips/blob/master/01.md))
- [x] User Profiles (edit/follow/unfollow - [NIP-02](https://github.com/nostr-protocol/nips/blob/master/02.md))
- [x] Private Messages ([NIP-04](https://github.com/nostr-protocol/nips/blob/master/04.md))
- [x] Nostr Address ([NIP-05](https://github.com/nostr-protocol/nips/blob/master/05.md))
- [x] Event Deletion ([NIP-09](https://github.com/nostr-protocol/nips/blob/master/09.md))
- [x] Relay Info ([NIP-11](https://github.com/nostr-protocol/nips/blob/master/11.md))
- [x] Reactions ([NIP-25](https://github.com/nostr-protocol/nips/blob/master/25.md))
- [x] Lists ([NIP-51](https://github.com/nostr-protocol/nips/blob/master/51.md))
- [x] Relay List Metadata ([NIP-65](https://github.com/nostr-protocol/nips/blob/master/65.md))
- [ ] Bech Encoding support ([NIP-19](https://github.com/nostr-protocol/nips/blob/master/19.md))
- [ ] Wallet Connect API ([NIP-47](https://github.com/nostr-protocol/nips/blob/master/47.md))
- [ ] Zaps (private, public, anon, non-zap) ([NIP-57](https://github.com/nostr-protocol/nips/blob/master/57.md))
- [ ] Badges ([NIP-58](https://github.com/nostr-protocol/nips/blob/master/58.md))

# common terminology

| term                | explanation                                              | simmilar to                 |
| ------------------- | -------------------------------------------------------- | --------------------------- |
| **broadcastEvent**  | push event to nostr network/relays                       | postEvent, publishEvent     |
| **JIT**             | Just In Time, e.g. as it happens                         | -                           |
| **query**           | get data once and close the request                      | get request                 |
| **subscription**    | stream of events as they come in                         | stream of data              |
| **bootstrapRelays** | default relays to connect when nothing else is specified | seed relays, initial relays |

# [Changelog 🔗](https://github.com/relaystr/dart_ndk/blob/master/CHANGELOG.md)
