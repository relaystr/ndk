## 0.3.2
- improvement: add NWC get_budget method support
- improvement: adds percent consider broadcast done

## 0.3.1
- improvement: generic filter tags
- fix: blossom parsing issues
- fix: log invalid signed events

## 0.3.0

- blossom improvmements
- accounts usecase (switch signer)
- docs: enable gossip guide, accounts

## 0.2.6

- full blossom support
- new docs

## 0.2.5

- fix async of send auth challenge after signing

## 0.2.4

- fix wrongly timeouts being triggered
- fix using same relays from zap request for zap receipts

## 0.2.2

- fix passing ZapRequest to lnurl nostr param

## 0.2.1

- NIP-47 Nostr Wallet Connect
- NIP-57 Zaps support
- NIP-42 Authentication of clients to relays
- NIP-44 Encrypted Payloads (Versioned)
- Unification of RelayManager in JIT
- Web_socket_client nostr transport implementation with backoff reconnects
- Melos support, separated monorepos
- Objectbox cache initial support of basic models
- Isar cache support
- many bugfixes and improvements in relay timeout handling

## 0.1.3

- upgrade to flutter_rust_bridge 2.6.0
- close usecase in requests
- async cache manager
- set contact list usecase
- use broadcast usecase for other usecases

## 0.1.2

- upgrade to flutter_rust_bridge 2.5.0

## 0.1.1

- LF line break issue linux

## 0.1.0

- complete re architecture of the lib [ADR](https://github.com/relaystr/ndk/blob/master/doc/ADRs/layerd-architecture.md)
- gossip read support in two engines [LISTS, JIT]
- caching support
- rust event verifier
- drop support for acinq verifier
- examples and sample app
- improved testing
- requests middleware
- convenience methods for common nostr usecases
- rename repo `dart_ndk` => `ndk`

## 0.1.0-dev996

- upgrade to bip340 0.3.0

## 0.1.0-dev995

- link working rust_lib_ndk
- readme
- examples

## 0.1.0-dev994

- static fixes

## 0.1.0-dev993

- test examples

## 0.1.0-dev992

- refine example

## 0.1.0-dev991

- update examples

## 0.1.0-dev99

- re-subscribe to in flight subscription requests after relay reconnection

## 0.1.0-dev98

- add documentation for public members

## 0.1.0-dev94

- add replyETags getter to Nip01Event

## 0.1.0-dev92

- add example README.md

## 0.1.0-dev91

- major architecure refactor
- rust event verifier
- removed acinq verifier

## 0.1.0-dev8

- use fork of amberflutter for isAppInstalled method

## 0.1.0-dev6

- amber event signer

## 0.1.0-dev6

- acinq sec256k1 event verifier (native android)

## 0.1.0-dev5

- set isar maxSizeMiB to 1024
- use compactOnLaunch: const CompactCondition(minRatio: 2.0, minBytes: 100 _ 1024 _ 1024, minFileSize: 256 _ 1024 _ 1024),

## 0.1.0-dev3

- fixed reconnect method

## 0.1.0-dev1

- gossip outbox/inbox model implemented

## 0.0.1

- TODO: Describe initial release.
