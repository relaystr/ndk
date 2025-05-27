---
label: Home
order: 101
icon: home
---

# Dart Nostr Development Kit (NDK)

[![Build Status](https://github.com/relaystr/ndk/actions/workflows/tests.yaml/badge.svg?branch=master)](https://github.com/relaystr/ndk/actions?query=workflow%3A"tests"+branch%3Amaster) [![Coverage](https://img.shields.io/codecov/c/github/relaystr/ndk?color=green)](https://codecov.io/github/relaystr/ndk) [![Pub](https://img.shields.io/pub/v/ndk.svg)](https://pub.dev/packages/ndk) [![License](https://img.shields.io/github/license/relaystr/ndk.svg)](LICENSE.txt)

NDK (Nostr Development Kit) is a Dart library that enhances the Nostr development experience.\
NDK supplies you with high-level usecases like lists or metadata while still allowing you to use low-level queries enhanced with inbox/outbox (gossip) by default.\
Our Target is to make it easy to build constrained Nostr clients, particularly for mobile devices.

## Apps using NDK

- [sample app](https://github.com/relaystr/ndk/releases)
- [yana](https://github.com/frnandu/yana)
- [camelus](https://github.com/leo-lox/camelus)
- [zap.stream](https://github.com/nostrlabs-io/zap-stream-flutter)
- [zapstore](https://github.com/zapstore/zapstore)
- [freeflow](https://github.com/nostrlabs-io/freeflow)
- [hostr](https://github.com/sudonym-btc/hostr)

[!ref](/guides/getting-started.md)

# Features / what does NDK do?

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
- nip05 caching
- nip-47 [Nostr wallet connect](https://github.com/relaystr/ndk/blob/master/packages/ndk/lib/domain_layer/usecases/nwc/README.md)
- nip-42 Authentication of clients to relays
- nip-57 Zaps
- blossom file support

## not Included

- ready to use feeds, you have to build them on your own (🚫 not planned)
- create && manage keypairs. You have to provide them (🚫 not planned)
- threading, you can do this on your own if you move ndk or only the event_verifier into its own thread (🔜 planned)
- support for request overrides (you have to close and reopen requests) (🤔 unsure)

[!ref](/library-development/CONTRIBUTING.md)

---

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
- [x] Wallet Connect API ([NIP-47](https://github.com/nostr-protocol/nips/blob/master/47.md))
- [x] Zaps ([NIP-57](https://github.com/nostr-protocol/nips/blob/master/57.md))
- [x] Authentication of clients to relays ([NIP-42](https://github.com/nostr-protocol/nips/blob/master/42.md))
- [x] Encrypted Payloads (Versioned) ([NIP-44](https://github.com/nostr-protocol/nips/blob/master/44.md))
- [ ] Bech Encoding support ([NIP-19](https://github.com/nostr-protocol/nips/blob/master/19.md))
- [ ] Badges ([NIP-58](https://github.com/nostr-protocol/nips/blob/master/58.md))
