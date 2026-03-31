## 0.8.0-dev.3

 - **FIX**: unused import. ([1a4d480f](https://github.com/relaystr/ndk/commit/1a4d480f512956b656edb80b0846d14cc4f2d915))
 - **FIX**: add missing path. ([a3b57e89](https://github.com/relaystr/ndk/commit/a3b57e8981b870334774f02c56c779e1a6462ef9))
 - **FIX**: use parallel broadcast pattern in relay_jit_broadcast_specific. ([ba318d85](https://github.com/relaystr/ndk/commit/ba318d85b161515b17867be03a8dd37fb3f31c5b))
 - **FIX**: parallel broadcast with Future.wait and address PR feedback. ([4f5096d2](https://github.com/relaystr/ndk/commit/4f5096d2d8fc3e2793057dd1faf315f91dcfae66))
 - **FIX**: apply moved rust code. ([610784b3](https://github.com/relaystr/ndk/commit/610784b310ab7a348100d13083a7cbd6faeda3af))
 - **FIX**(test): resolve port conflicts in broadcast_test.dart. ([5ae8db79](https://github.com/relaystr/ndk/commit/5ae8db7934bab16e10c3a6b7ca71a1ba170c2ddc))
 - **FIX**(test): generate MockRelay AUTH challenge once per server lifetime. ([ed90f058](https://github.com/relaystr/ndk/commit/ed90f0585cbb9b88ab117e9bf8fbddf9cfd36359))
 - **FIX**: start timeout after signing completes. ([f1534b37](https://github.com/relaystr/ndk/commit/f1534b373eae9a489796e3bad0cc3736342138bd))
 - **FIX**(test): implement missing EventSigner methods in MockSlowSigner. ([a941d7fb](https://github.com/relaystr/ndk/commit/a941d7fbe3f9e8d27bb42ca386ceb710c2ada71c))
 - **FIX**: fix imports. ([8a10dd61](https://github.com/relaystr/ndk/commit/8a10dd6143d16244ffd31211d91c96857de7609d))
 - **FIX**: fix imports. ([8351d005](https://github.com/relaystr/ndk/commit/8351d005d7b83ba69b115e6117dfeceff7fd3275))
 - **FIX**: fix imports. ([a23df4ea](https://github.com/relaystr/ndk/commit/a23df4ea44934cd4b683adbcd382eedaf98663a5))
 - **FIX**: move sembast to core. ([817569cf](https://github.com/relaystr/ndk/commit/817569cf7cd30d09e6f5550adebfd7d93b930041))
 - **FIX**: robust broadcast lifecycle and relay connection handling. ([0c2e56d3](https://github.com/relaystr/ndk/commit/0c2e56d3e2010fc9cec5e7e1bc89d4bd719dca0d))

## 0.8.0-dev.2

 - **REFACTOR**: filter keyset by active and unit.
 - **REFACTOR**: remove wallet prefix from cashu.
 - **REFACTOR**: rename removeWallet.
 - **REFACTOR**: remove acc prefix, clear seperation wallet.
 - **FIX**: log body http request.
 - **FIX**: cashu tests needed a wallet.
 - **FIX**: missing wallets.dispose in ndk.destroy.
 - **FIX**: initialization.
 - **FIX**: nwc connection.
 - **FIX**: broadcast state timeout.
 - **FIX**: rollback removal of walletsRepo from ndkConfig.
 - **FIX**: rollback removal of walletsRepo from ndkConfig.
 - **FIX**: removed feat combinedTransactions.
 - **FIX**: dispose combined balances activated.
 - **FIX**: separate wallets storage operations from cache manager.
 - **FIX**: usecase name.
 - **FIX**: restore save only unspend tokens.
 - **FIX**: type parsing.
 - **FIX**: spend, redeem exception handeling.
 - **FIX**: cashu redeem failed transaction state.
 - **FIX**: hook up deleteKnownMint to removeWallet.
 - **FIX**: add keysets to decorator.
 - **FIX**: store keysets from network.
 - **FIX**: null err.
 - **FIX**: cashu usecase naming.
 - **FIX**: wallet transaction state storage.
 - **FIX**: cleanup on ndk destroy.
 - **FIX**: melt map output blanks to change.
 - **FIX**: melt change parsing.
 - **FIX**: allow fee reserve 0.
 - **FIX**: swap split change, exact amount.
 - **FIX**: mintUrl in CashuMintBalance.
 - **FIX**: typo.
 - **FIX**: check completion when transcation rcv.
 - **FIX**: test secret comparison.
 - **FIX**: dismiss large keyset amounts.
 - **FIX**: sort swap outputs.
 - **FIX**: correct balance with inactive keysets.
 - **FIX**: getProofs mem cache manager.
 - **FIX**: identify cashu proof by pubKey.
 - **FIX**: dont add total balance.
 - **FIX**: filter keyset for unit.
 - **FIX**: cashuMintInfo fromJson add mintUrl.
 - **FIX**: wallet filter balances by mint.
 - **FIX**: save transaction to db.
 - **FIX**: cashu balances grouping.
 - **FEAT**: spending with state.
 - **FEAT**: cashu mnemonic.
 - **FEAT**: nut13 deterministic secrets.
 - **FEAT**: rust deriveSecret.
 - **FEAT**: seed phrase user api.
 - **FEAT**: CashuKeyDerivation support keysets v2.
 - **FEAT**: fast key derivation.
 - **FEAT**: fast multiply blind msg.
 - **FEAT**: optimized proof select.
 - **FEAT**: cashu restore.
 - **FEAT**: save pending transactions.
 - **FEAT**: auto detect wallet cache manager.
 - **FEAT**: cashu remove mint info.
 - **FEAT**: init combined streams lazy.
 - **FEAT**: dynamically create wallets based on usecase data.

## 0.8.0-dev.1

 - **REFACTOR**: filter keyset by active and unit.
 - **REFACTOR**: remove wallet prefix from cashu.
 - **REFACTOR**: rename removeWallet.
 - **REFACTOR**: remove acc prefix, clear seperation wallet.
 - **FIX**: log body http request.
 - **FIX**: cashu tests needed a wallet.
 - **FIX**: missing wallets.dispose in ndk.destroy.
 - **FIX**: initialization.
 - **FIX**: nwc connection.
 - **FIX**: broadcast state timeout.
 - **FIX**: rollback removal of walletsRepo from ndkConfig.
 - **FIX**: rollback removal of walletsRepo from ndkConfig.
 - **FIX**: removed feat combinedTransactions.
 - **FIX**: dispose combined balances activated.
 - **FIX**: separate wallets storage operations from cache manager.
 - **FIX**: usecase name.
 - **FIX**: restore save only unspend tokens.
 - **FIX**: type parsing.
 - **FIX**: spend, redeem exception handeling.
 - **FIX**: cashu redeem failed transaction state.
 - **FIX**: hook up deleteKnownMint to removeWallet.
 - **FIX**: add keysets to decorator.
 - **FIX**: store keysets from network.
 - **FIX**: null err.
 - **FIX**: cashu usecase naming.
 - **FIX**: wallet transaction state storage.
 - **FIX**: cleanup on ndk destroy.
 - **FIX**: melt map output blanks to change.
 - **FIX**: melt change parsing.
 - **FIX**: allow fee reserve 0.
 - **FIX**: swap split change, exact amount.
 - **FIX**: mintUrl in CashuMintBalance.
 - **FIX**: typo.
 - **FIX**: check completion when transcation rcv.
 - **FIX**: test secret comparison.
 - **FIX**: dismiss large keyset amounts.
 - **FIX**: sort swap outputs.
 - **FIX**: correct balance with inactive keysets.
 - **FIX**: getProofs mem cache manager.
 - **FIX**: identify cashu proof by pubKey.
 - **FIX**: dont add total balance.
 - **FIX**: filter keyset for unit.
 - **FIX**: cashuMintInfo fromJson add mintUrl.
 - **FIX**: wallet filter balances by mint.
 - **FIX**: save transaction to db.
 - **FIX**: cashu balances grouping.
 - **FEAT**: spending with state.
 - **FEAT**: cashu mnemonic.
 - **FEAT**: nut13 deterministic secrets.
 - **FEAT**: rust deriveSecret.
 - **FEAT**: seed phrase user api.
 - **FEAT**: CashuKeyDerivation support keysets v2.
 - **FEAT**: fast key derivation.
 - **FEAT**: fast multiply blind msg.
 - **FEAT**: optimized proof select.
 - **FEAT**: cashu restore.
 - **FEAT**: save pending transactions.
 - **FEAT**: auto detect wallet cache manager.
 - **FEAT**: cashu remove mint info.
 - **FEAT**: init combined streams lazy.
 - **FEAT**: dynamically create wallets based on usecase data.

## 0.7.2-dev.2

 - **FIX**: min sdk 3.6 for hooks.

## 0.7.2-dev.1

 - **FIX**: cleanup.
 - **FEAT**: cli.

## 0.7.2-dev.0

 - **FEAT**: paginated requests.

## 0.7.1

 - FEAT: cache known properties.
 - FEAT: isolate manager with stream response.
 - FEAT: improved upload progress report.
 - FEAT: blossom mirrorToServers().
 - FEAT: files api uploadFromFile(), downloadToFile().
 - FEAT: blossom file stream.
 - FEAT(broadcast): add NIP-09 compliant deletion with e, k, and a tags.
 - FEAT: implement RFC 3986 compliant relay URL normalization.
 - FEAT: expose signer API on Account entity.
 - FEAT: add SignerRequestRejectedException for remote signer rejections.
 - FEAT: add nip46 pending requests integration test.
 - FEAT: add unified pending requests API.
 - FEAT(cache): add removeEvents method for bulk event deletion.
 - FEAT(cache): add clearAll() method to CacheManager.
 - FEAT: add caching support for nip05.resolve() with identifier lookup.
 - FEAT: add caching support for nip05.resolve() with identifier lookup.
 - FEAT: add caching support for nip05.resolve() with identifier lookup.
 - FEAT: add of() method to fetch NIP-05 data without pubkey.
 - FEAT: add missing state field in lookup_invoice_response.dart.
 - FEAT: add missing getPublicList.
 - FEAT: change removeEvents to support flexible filtering.
 - FEAT: gift wrap add custom signer parameter.
 - FEAT: add saveToCache option for broadcast.
 - FEAT: nip42 multi auth.
 - REFACTOR: rename rawContent to content.
 - REFACTOR: uploadBlob use dataStreamFactory.
 - REFACTOR: extract URL normalization to separate file.
 - REFACTOR: make dispose() async.
 - REFACTOR: remove unused requestRelays method.
 - REFACTOR: rename nip05.fetch() to nip05.resolve().
 - REFACTOR: nip05 usecase.
 - FIX: concurent list modification.
 - FIX: allow blossom uploadBlob without login via temporary/custom signer.
 - FIX: tests passes.
 - FIX: toJson and fromJson.
 - FIX: meme cache mock.
 - FIX: tests.
 - FIX: use setter for known properties + content never null.
 - FIX: mem cache manager mock.
 - FIX: preserve tags and custom fields in metadata.
 - FIX: propagate signer exceptions through broadcast.
 - FIX: getPublicList() reduce db calls by saving last event.
 - FIX: getPublicList add limit.
 - FIX: getPublicList only save latest event.
 - FIX(broadcast): return immediately when all relays have responded.
 - FIX: web init.
 - FIX: use isolate manager for native hash calc.
 - FIX: get file hash for uploadBlobFromFile().
 - FIX: flanky blossom test depending on order.
 - FIX(perf): lazy log.
 - FIX: remove all event versions from cache on NIP-09 deletion.
 - FIX: flanky test.
 - FIX: close duplicate request when original completes.
 - FIX: fail fast when all relays are offline.
 - FIX: complete request when auth-required received without challenge.
 - FIX: complete request when relay requires auth but client cannot sign.
 - FIX: distinguish CLOSED from EOSE in relay request state.
 - FIX: add destroy in tear down.
 - FIX: ensure NIP-46 subscription is ready before sending remote requests.
 - FIX: subscribe before broadcast in connectWithBunkerUrl to avoid missing NIP-46 responses.
 - FIX: move authCallbackTimeout to NdkConfig.
 - FIX: add timeout for pending AUTH callbacks.
 - FIX: authenticate all accounts in authenticateAs for lazy auth mode.
 - FIX: handle NIP-42 auth-required by re-sending REQ/EVENT after AUTH.
 - FIX: rename stateChanges to authStateChanges.
 - FIX: minIsolatePoolSize.
 - FIX: use Accounts instead of pubkeys to authenticate.


## 0.7.1-dev.20

 - **REFACTOR**: rename rawContent to content.
 - **FIX**: concurent list modification.
 - **FIX**: allow blossom uploadBlob without login via temporary/custom signer.
 - **FIX**: tests passes.
 - **FIX**: toJson and fromJson.
 - **FIX**: meme cache mock.
 - **FIX**: tests.
 - **FIX**: use setter for known properties + content never null.
 - **FIX**: mem cache manager mock.
 - **FIX**: preserve tags and custom fields in metadata.
 - **FEAT**: cache known properties.

## 0.7.1-dev.19

 - **FIX**: propagate signer exceptions through broadcast.

## 0.7.1-dev.18

 - **FIX**: getPublicList() reduce db calls by saving last event.
 - **FIX**: getPublicList add limit.
 - **FIX**: getPublicList only save latest event.
 - **FEAT**: add missing getPublicList.

## 0.7.1-dev.17

 - **FIX**(broadcast): return immediately when all relays have responded.

## 0.7.1-dev.16

 - **REFACTOR**: uploadBlob use dataStreamFactory.
 - **FIX**: web init.
 - **FIX**: use isolate manager for native hash calc.
 - **FIX**: get file hash for uploadBlobFromFile().
 - **FIX**: flanky blossom test depending on order.
 - **FEAT**: isolate manager with stream response.
 - **FEAT**: improved upload progress report.
 - **FEAT**: blossom mirrorToServers().
 - **FEAT**: files api uploadFromFile(), downloadToFile().
 - **FEAT**: blossom file stream.

## 0.7.1-dev.15

 - **FIX**(perf): lazy log.

## 0.7.1-dev.14

 - **REFACTOR**: extract URL normalization to separate file.
 - **FIX**: remove all event versions from cache on NIP-09 deletion.
 - **FIX**: flanky test.
 - **FEAT**(broadcast): add NIP-09 compliant deletion with e, k, and a tags.
 - **FEAT**: implement RFC 3986 compliant relay URL normalization.

## 0.7.1-dev.13

 - **REFACTOR**: make dispose() async.
 - **FEAT**: expose signer API on Account entity.
 - **FEAT**: add SignerRequestRejectedException for remote signer rejections.
 - **FEAT**: add nip46 pending requests integration test.
 - **FEAT**: add unified pending requests API.

## 0.7.1-dev.12

 - **FEAT**: change removeEvents to support flexible filtering.
 - **FEAT**(cache): add removeEvents method for bulk event deletion.
 - **DOCS**: add safety note to removeEvents documentation.

## 0.7.1-dev.11

 - **FIX**: close duplicate request when original completes.
 - **FEAT**(cache): add clearAll() method to CacheManager.
 - **DOCS**: add DANGER warning to clearAll() method.

## 0.7.1-dev.10

 - **REFACTOR**: remove unused requestRelays method".
 - **REFACTOR**: remove unused requestRelays method.
 - **FIX**: fail fast when all relays are offline.

## 0.7.1-dev.9

 - **FIX**: complete request when auth-required received without challenge.
 - **FIX**: complete request when relay requires auth but client cannot sign.

## 0.7.1-dev.8

 - **FIX**: distinguish CLOSED from EOSE in relay request state.

## 0.7.1-dev.7

 - **REFACTOR**: rename nip05.fetch() to nip05.resolve().
 - **REFACTOR**: nip05 usecase.
 - **FEAT**: add caching support for nip05.resolve() with identifier lookup.
 - **FEAT**: add caching support for nip05.resolve()  with identifier lookup.
 - **FEAT**: add caching support for nip05.resolve() with identifier lookup.
 - **FEAT**: add of() method to fetch NIP-05 data without pubkey.

## 0.7.1-dev.6

 - **FIX**: add destroy in tear down.
 - **FIX**: ensure NIP-46 subscription is ready before sending remote requests.
 - **FIX**: subscribe before broadcast in connectWithBunkerUrl to avoid missing NIP-46 responses.

## 0.7.1-dev.5

 - **FEAT**: add missing state field in lookup_invoice_response.dart.

## 0.7.1-dev.4

 - **FIX**: move authCallbackTimeout to NdkConfig.
 - **FIX**: add timeout for pending AUTH callbacks.
 - **FIX**: authenticate all accounts in authenticateAs for lazy auth mode.
 - **FIX**: handle NIP-42 auth-required by re-sending REQ/EVENT after AUTH.
 - **FEAT**: add eagerAuth in NDK config.

## 0.7.1-dev.3

 - **FIX**: rename stateChanges to authStateChanges.
 - **FEAT**: gift wrap add custom signer parameter.

## 0.7.1-dev.2

 - **FIX**: minIsolatePoolSize.

## 0.7.1-dev.1

 - **FEAT**: add saveToCache option for broadcast.

## 0.7.1-dev.0

 - **FIX**: use Accounts instead of pubkeys to authenticate.
 - **FEAT**: nip42 multi auth.

## 0.7.0

 - **FEAT**: isolate manager stub.
 - **FIX**: remove unused import.
 - **FIX**: sha256 convert in isolate.
 - **FIX**: fetched ranges integration test.
 - **FIX**: rename coverage usecase to fetchedRanges.
 - **FIX**: timerange until.
 - **FIX**: added ranges.
 - **FEAT**: cache managers support.
 - **FEAT**: mark as experimental.
 - **FEAT**: coverage disabled by default.
 - **FEAT**: unify cache events api.
 - **FEAT**: integration tests.
 - **FEAT**: unit tests.
 - **FEAT**: automatic coverage.
 - **FEAT**: coverage usecase.
 - **REFACTOR**: proof of work as instance.
 - **REFACTOR**(fix): encode zapRequest.
 - **REFACTOR**(fix): encode gift wrap.
 - **REFACTOR**(fix): use signed event in sets engine.
 - **REFACTOR**(fix): brodcast detect need for signing.
 - **REFACTOR**(fix): mock relay fix send encode.
 - **REFACTOR**: zap request calc id.
 - **REFACTOR**(fix): auth event id.
 - **REFACTOR**(fix): sign event in test.
 - **REFACTOR**: immutable event sources.
 - **REFACTOR**: ndk tests.
 - **REFACTOR**: valid sig.
 - **REFACTOR**: other packages.
 - **REFACTOR**: entities.
 - **REFACTOR**: signer, amber.
 - **REFACTOR**: event service.
 - **REFACTOR**: nip01 immutable.
 - **REFACTOR**: decode nip01 event in isolate.
 - **FIX**: remove meaningless comments.
 - **FIX**: mem cache methods (loadNip05s, loadMetadatas).
 - **FIX**: blossom signing.
 - **FIX**: add copy with to extended class.
 - **FIX**: websocket state check optimization.
 - **FEAT**: add test suite in actual cache tests.
 - **FEAT**: global test suite.
 - **FEAT**: preserve order decoding.
 - **FEAT**: eose extract request id.
 - **FEAT**: isolate pool.
 - **FEAT**: deligate tasks to isolates.
 - **FEAT**: add tests.
 - **FEAT**: deprecation message for filters.
 - **FIX**: bip340 event verifier.
 - **FEAT**: add test.
 - **FIX**: clean imports.
 - **FIX**: improve relay reconnection.
 - **FIX**: close relay.
 - **FIX**: Handle null error value in NWC response deserialization.
 - **FIX**: forcing a pre-release.
 - **FIX**: move test to an apropriate area.
 - **FIX**: clean relay url function + add tests.
 - **FEAT**: add test.
 - **FIX**: update the mock relay + test.
 - **FIX**: test pass.
 - **FEAT**: add a test.
 - **FIX**: use mock relay.
 - **FIX**: new test pass.
 - **FEAT**: test.

## 0.6.1-dev.9

 - **FEAT**: isolate manager stub.

## 0.6.1-dev.8

 - **FIX**: remove unused import.
 - **FIX**: sha256 convert in isolate.
 - **FIX**: fetched ranges integration test.
 - **FIX**: rename coverage usecase to fetchedRanges.
 - **FIX**: timerange until.
 - **FIX**: added ranges.
 - **FEAT**: cache managers support.
 - **FEAT**: mark as experimental.
 - **FEAT**: coverage disabled by default.
 - **FEAT**: unify cache events api.
 - **FEAT**: integration tests.
 - **FEAT**: unit tests.
 - **FEAT**: automatic coverage.
 - **FEAT**: coverage usecase.

## 0.6.1-dev.7

 - **REFACTOR**: proof of work as instance.
 - **REFACTOR**(fix): encode zapRequest.
 - **REFACTOR**(fix): encode gift wrap.
 - **REFACTOR**(fix): use signed event in sets engine.
 - **REFACTOR**(fix): brodcast detect need for signing.
 - **REFACTOR**(fix): mock relay fix send encode.
 - **REFACTOR**: zap request calc id.
 - **REFACTOR**(fix): auth event id.
 - **REFACTOR**(fix): sign event in test.
 - **REFACTOR**: immutable event sources.
 - **REFACTOR**: ndk tests.
 - **REFACTOR**: valid sig.
 - **REFACTOR**: other packages.
 - **REFACTOR**: entities.
 - **REFACTOR**: signer, amber.
 - **REFACTOR**: event service.
 - **REFACTOR**: nip01 immutable.
 - **REFACTOR**: decode nip01 event in isolate.
 - **FIX**: remove meaningless comments.
 - **FIX**: mem cache methods (loadNip05s, loadMetadatas).
 - **FIX**: blossom signing.
 - **FIX**: add copy with to extended class.
 - **FIX**: websocket state check optimization.
 - **FEAT**: add test suite in actual cache tests.
 - **FEAT**: global test suite.
 - **FEAT**: preserve order decoding.
 - **FEAT**: eose extract request id.
 - **FEAT**: isolate pool.
 - **FEAT**: deligate tasks to isolates.

## 0.6.1-dev.6

 - **FEAT**: add tests.
 - **FEAT**: deprecation message for filters.

## 0.6.1-dev.5

 - **FIX**: bip340 event verifier.
 - **FEAT**: add test.

## 0.6.1-dev.4

 - **FIX**: clean imports.
 - **FIX**: improve relay reconnection.

## 0.6.1-dev.3

 - **FIX**: close relay.

## 0.6.1-dev.2

 - **FIX**: Handle null error value in NWC response deserialization.
 - **FIX**: forcing a pre-release.
 - **FIX**: move test to an apropriate area.
 - **FIX**: clean relay url function + add tests.
 - **FEAT**: add test.

## 0.6.1-dev.1

 - **FIX**: update the mock relay + test.
 - **FIX**: test pass.
 - **FEAT**: add a test.

## 0.6.1-dev.0

 - **FIX**: use mock relay.
 - **FIX**: new test pass.
 - **FEAT**: test.

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
