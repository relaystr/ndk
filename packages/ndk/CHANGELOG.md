## 0.6.0

 - Graduate package to a stable release. See pre-releases prior to this version for changelog entries.

## 0.6.0-dev.20

 - **REFACTOR**: remove param signer from lists api.
 - **REFACTOR**: use immutable event in toEvent().
 - **REFACTOR**: reoder, naming, description.
 - **FIX**: upgrade to nip44.
 - **FIX**: mock relay delete from memory.
 - **FIX**: calculate id in nip51set.
 - **FEAT**: lists nip04 backwards compatibility with nip04.
 - **FEAT**: delete set.

## 0.6.0-dev.19

 - **REFACTOR**: remove param signer from lists api.
 - **REFACTOR**: use immutable event in toEvent().
 - **REFACTOR**: reoder, naming, description.
 - **FIX**: upgrade to nip44.
 - **FIX**: mock relay delete from memory.
 - **FIX**: calculate id in nip51set.
 - **FEAT**: lists nip04 backwards compatibility with nip04.
 - **FEAT**: delete set.

## 0.6.0-dev.18

 - **FIX**: missing convert  dependency.
 - **FIX**: remove hex package depandance.

## 0.6.0-dev.17

 - **FIX**: missing convert  dependency.
 - **FIX**: remove hex package depandance.

## 0.6.0-dev.16

 - **FIX**: tests coverage.
 - **FIX**: remove hex package usage.
 - **FIX**: split long file.
 - **FIX**: round trip tests.
 - **FIX**: var to final.
 - **FIX**: move class to entities.
 - **FIX**: missing test coverage.
 - **FIX**: missing test coverage.
 - **FEAT**: nip19 getters on events.
 - **FEAT**: nprofile, naddr and nevent support.

## 0.6.0-dev.15

 - **FIX**: tests coverage.
 - **FIX**: remove hex package usage.
 - **FIX**: split long file.
 - **FIX**: round trip tests.
 - **FIX**: var to final.
 - **FIX**: move class to entities.
 - **FIX**: missing test coverage.
 - **FIX**: missing test coverage.
 - **FEAT**: nip19 getters on events.
 - **FEAT**: nprofile, naddr and nevent support.

## 0.6.0-dev.14

 - **FIX**: waiting for connection broadcast jit.

## 0.6.0-dev.13

 - **FIX**: waiting for connection broadcast jit.

## 0.6.0-dev.12

 - **FIX**: Use 0x100000000 instead of 1 << 32 for web compatibility.

## 0.6.0-dev.11

 - **FIX**: Use 0x100000000 instead of 1 << 32 for web compatibility.

## 0.6.0-dev.10

 - **FIX**: add id recalculation in Nip01Event.copyWith.
 - **FIX**: make the test "validate event: greater POW" predictable.
 - **FIX**: wrap json.decode with a try catch block.

## 0.6.0-dev.9

 - **FIX**: add id recalculation in Nip01Event.copyWith.
 - **FIX**: make the test "validate event: greater POW" predictable.
 - **FIX**: wrap json.decode with a try catch block.

## 0.6.0-dev.8

 - **FIX**: add test and call clean url during broadcast.

## 0.6.0-dev.7

 - **FIX**: add test and call clean url during broadcast.

## 0.6.0-dev.6

 - **FIX**: static analysis issues.

## 0.6.0-dev.5

 - **FIX**: static analysis issues.

## 0.6.0-dev.4

 - **FEAT**: log color, params.

## 0.6.0-dev.3

 - **FEAT**: log color, params.

## 0.6.0-dev.2

 - **REFACTOR**: concurrent streams with rxdart.
 - **FIX**: improved null filter.
 - **FIX**: drop invalid events.

## 0.6.0-dev.1

 - **REFACTOR**: concurrent streams with rxdart.
 - **FIX**: improved null filter.
 - **FIX**: drop invalid events.

## 0.6.0-dev.0

- Bump "ndk" to `0.6.0-dev.0`.

## 0.5.2-dev.2

- **FIX**: buffer not clearing.
- **FEAT**: concurrent event stream.

## 0.5.2-dev.1

- **FIX**: buffer not clearing.
- **FEAT**: concurrent event stream.

## 0.5.2-dev.0+1

- **FIX**: call dispose on destroy.
- **FIX**: BehaviorSubject for immediate values.
- **FIX**: copy value to fix modification.

## 0.5.1

- feat: nip46 signer
- feat: useragent identifier
- fix: limit in loadEvents
- dep: upgrade to pointycastle v4

## 0.5.0

- feat: NIP07 web signer support
- feat: sembast cache manager (+web support)

## 0.4.1

- fix: close relay only closes the specifi relay
- fix: fixed common ndk warnings
- fix: remove inFlight requests
- fix: jit engine connections to low value relays

## 0.4.0

- feat: nip 59 gift wrap
- feat: tlv decode nip19
- feat: search usecase
- feat: relayConnectivityChanges usecase
- feat: Add settleDeadline field to NwcNotification
- feat: Nip51 mute list event filterenhancementNew feature or request
- feat: NWC hold invoice support
- feat: Support NWC Primal Wallet specific behaviorenhancement
- fix: breaking realtime updates with multiple filters
- fix: add support for multiple filters on RELAYS_SET engine
- fix: Add NWC useETagForEachRequest & ignoreCapabilitiesCheck to connect
- fix: Fix connection to a bad relay blocking event delivery
- fix: Connection to a bad relay blocking broadcastenhancement
- fix: Filter with ids breaks realtime updatesbug
- fix: rust dependency with latest flutter version
- updated dependencies

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
