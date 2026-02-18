# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](https://conventionalcommits.org) for commit guidelines.

## 2026-02-18

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.7.1-dev.14`](#ndk---v071-dev14)
 - [`ndk_objectbox` - `v0.2.8-dev.14`](#ndk_objectbox---v028-dev14)
 - [`nip07_event_signer` - `v1.0.6-dev.14`](#nip07_event_signer---v106-dev14)
 - [`ndk_amber` - `v0.4.0-dev.14`](#ndk_amber---v040-dev14)
 - [`ndk_rust_verifier` - `v0.5.0-dev.14`](#ndk_rust_verifier---v050-dev14)
 - [`sembast_cache_manager` - `v1.0.7-dev.14`](#sembast_cache_manager---v107-dev14)
 - [`ndk_flutter` - `v0.0.2-dev.6`](#ndk_flutter---v002-dev6)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.4.0-dev.14`
 - `ndk_rust_verifier` - `v0.5.0-dev.14`
 - `sembast_cache_manager` - `v1.0.7-dev.14`
 - `ndk_flutter` - `v0.0.2-dev.6`

---

#### `ndk` - `v0.7.1-dev.14`

 - **FIX**: remove all event versions from cache on NIP-09 deletion.
 - **FIX**: flanky test.
 - **FEAT**(broadcast): add NIP-09 compliant deletion with e, k, and a tags.

#### `ndk_objectbox` - `v0.2.8-dev.14`

 - **FIX**: objectbox nullable sig.

#### `nip07_event_signer` - `v1.0.6-dev.14`

 - **FIX**(nip07): use nostr-tools for proper NIP-04/NIP-44 test mock.


## 2026-02-17

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.7.1-dev.13`](#ndk---v071-dev13)
 - [`ndk_amber` - `v0.4.0-dev.13`](#ndk_amber---v040-dev13)
 - [`nip07_event_signer` - `v1.0.6-dev.13`](#nip07_event_signer---v106-dev13)
 - [`ndk_objectbox` - `v0.2.8-dev.13`](#ndk_objectbox---v028-dev13)
 - [`ndk_rust_verifier` - `v0.5.0-dev.13`](#ndk_rust_verifier---v050-dev13)
 - [`sembast_cache_manager` - `v1.0.7-dev.13`](#sembast_cache_manager---v107-dev13)
 - [`ndk_flutter` - `v0.0.2-dev.5`](#ndk_flutter---v002-dev5)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_objectbox` - `v0.2.8-dev.13`
 - `ndk_rust_verifier` - `v0.5.0-dev.13`
 - `sembast_cache_manager` - `v1.0.7-dev.13`
 - `ndk_flutter` - `v0.0.2-dev.5`

---

#### `ndk` - `v0.7.1-dev.13`

 - **REFACTOR**: make dispose() async.
 - **FEAT**: expose signer API on Account entity.
 - **FEAT**: add SignerRequestRejectedException for remote signer rejections.
 - **FEAT**: add nip46 pending requests integration test.
 - **FEAT**: add unified pending requests API.

#### `ndk_amber` - `v0.4.0-dev.13`

 - **REFACTOR**: make dispose() async.
 - **FEAT**: add SignerRequestRejectedException for remote signer rejections.
 - **FEAT**: add unified pending requests API.

#### `nip07_event_signer` - `v1.0.6-dev.13`

 - **REFACTOR**: make dispose() async.
 - **FEAT**: add SignerRequestRejectedException for remote signer rejections.
 - **FEAT**: add unified pending requests API.


## 2026-02-15

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk_flutter` - `v0.0.2-dev.4`](#ndk_flutter---v002-dev4)

---

#### `ndk_flutter` - `v0.0.2-dev.4`

 - **FIX**(ndk_flutter): suppress experimental_member_use warning.
 - **FIX**(ndk_flutter): pass cachedPublicKey to signers during session restore.


## 2026-02-10

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.7.1-dev.12`](#ndk---v071-dev12)
 - [`ndk_cache_manager_test_suite` - `v1.0.1-dev.12`](#ndk_cache_manager_test_suite---v101-dev12)
 - [`ndk_objectbox` - `v0.2.8-dev.12`](#ndk_objectbox---v028-dev12)
 - [`sembast_cache_manager` - `v1.0.7-dev.12`](#sembast_cache_manager---v107-dev12)
 - [`ndk_amber` - `v0.4.0-dev.12`](#ndk_amber---v040-dev12)
 - [`ndk_rust_verifier` - `v0.5.0-dev.12`](#ndk_rust_verifier---v050-dev12)
 - [`nip07_event_signer` - `v1.0.6-dev.12`](#nip07_event_signer---v106-dev12)
 - [`ndk_flutter` - `v0.0.2-dev.3`](#ndk_flutter---v002-dev3)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.4.0-dev.12`
 - `ndk_rust_verifier` - `v0.5.0-dev.12`
 - `nip07_event_signer` - `v1.0.6-dev.12`
 - `ndk_flutter` - `v0.0.2-dev.3`

---

#### `ndk` - `v0.7.1-dev.12`

 - **FEAT**: change removeEvents to support flexible filtering.
 - **FEAT**(cache): add removeEvents method for bulk event deletion.
 - **DOCS**: add safety note to removeEvents documentation.

#### `ndk_cache_manager_test_suite` - `v1.0.1-dev.12`

 - **FEAT**: change removeEvents to support flexible filtering.

#### `ndk_objectbox` - `v0.2.8-dev.12`

 - **FEAT**: change removeEvents to support flexible filtering.
 - **FEAT**(cache): add removeEvents method for bulk event deletion.

#### `sembast_cache_manager` - `v1.0.7-dev.12`

 - **FEAT**: change removeEvents to support flexible filtering.
 - **FEAT**(cache): add removeEvents method for bulk event deletion.


## 2026-02-07

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.7.1-dev.11`](#ndk---v071-dev11)
 - [`ndk_objectbox` - `v0.2.8-dev.11`](#ndk_objectbox---v028-dev11)
 - [`sembast_cache_manager` - `v1.0.7-dev.11`](#sembast_cache_manager---v107-dev11)
 - [`ndk_amber` - `v0.4.0-dev.11`](#ndk_amber---v040-dev11)
 - [`ndk_rust_verifier` - `v0.5.0-dev.11`](#ndk_rust_verifier---v050-dev11)
 - [`nip07_event_signer` - `v1.0.6-dev.11`](#nip07_event_signer---v106-dev11)
 - [`ndk_cache_manager_test_suite` - `v1.0.1-dev.11`](#ndk_cache_manager_test_suite---v101-dev11)
 - [`ndk_flutter` - `v0.0.2-dev.2`](#ndk_flutter---v002-dev2)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.4.0-dev.11`
 - `ndk_rust_verifier` - `v0.5.0-dev.11`
 - `nip07_event_signer` - `v1.0.6-dev.11`
 - `ndk_cache_manager_test_suite` - `v1.0.1-dev.11`
 - `ndk_flutter` - `v0.0.2-dev.2`

---

#### `ndk` - `v0.7.1-dev.11`

 - **FIX**: close duplicate request when original completes.
 - **FEAT**(cache): add clearAll() method to CacheManager.
 - **DOCS**: add DANGER warning to clearAll() method.

#### `ndk_objectbox` - `v0.2.8-dev.11`

 - **FEAT**(cache): add clearAll() method to CacheManager.

#### `sembast_cache_manager` - `v1.0.7-dev.11`

 - **FIX**(sembast): clearAll only deletes cache manager stores.
 - **FEAT**(cache): add clearAll() method to CacheManager.


## 2026-02-06

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.7.1-dev.10`](#ndk---v071-dev10)
 - [`ndk_amber` - `v0.4.0-dev.10`](#ndk_amber---v040-dev10)
 - [`ndk_objectbox` - `v0.2.8-dev.10`](#ndk_objectbox---v028-dev10)
 - [`ndk_rust_verifier` - `v0.5.0-dev.10`](#ndk_rust_verifier---v050-dev10)
 - [`nip07_event_signer` - `v1.0.6-dev.10`](#nip07_event_signer---v106-dev10)
 - [`sembast_cache_manager` - `v1.0.7-dev.10`](#sembast_cache_manager---v107-dev10)
 - [`ndk_cache_manager_test_suite` - `v1.0.1-dev.10`](#ndk_cache_manager_test_suite---v101-dev10)
 - [`ndk_flutter` - `v0.0.2-dev.1`](#ndk_flutter---v002-dev1)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.4.0-dev.10`
 - `ndk_objectbox` - `v0.2.8-dev.10`
 - `ndk_rust_verifier` - `v0.5.0-dev.10`
 - `nip07_event_signer` - `v1.0.6-dev.10`
 - `sembast_cache_manager` - `v1.0.7-dev.10`
 - `ndk_cache_manager_test_suite` - `v1.0.1-dev.10`
 - `ndk_flutter` - `v0.0.2-dev.1`

---

#### `ndk` - `v0.7.1-dev.10`

 - **REFACTOR**: remove unused requestRelays method".
 - **REFACTOR**: remove unused requestRelays method.
 - **FIX**: fail fast when all relays are offline.


## 2026-02-05

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk_flutter` - `v0.0.2-dev.0`](#ndk_flutter---v002-dev0)

---

#### `ndk_flutter` - `v0.0.2-dev.0`

 - **REFACTOR**: migrate widgets to use NdkFlutter instead of Ndk.
 - **REFACTOR**: centralize npub formatting in NdkFlutter.
 - **FIX**: add intl dependency.
 - **FIX**: remove defensive empty pubkey check in getColorFromPubkey.
 - **FIX**: remove nip19 package.
 - **FEAT**: add widgets demo page for ndk_flutter in sample-app.
 - **FEAT**: add web verifier.


## 2026-02-04

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.7.1-dev.9`](#ndk---v071-dev9)
 - [`ndk_amber` - `v0.4.0-dev.9`](#ndk_amber---v040-dev9)
 - [`ndk_objectbox` - `v0.2.8-dev.9`](#ndk_objectbox---v028-dev9)
 - [`ndk_rust_verifier` - `v0.5.0-dev.9`](#ndk_rust_verifier---v050-dev9)
 - [`nip07_event_signer` - `v1.0.6-dev.9`](#nip07_event_signer---v106-dev9)
 - [`sembast_cache_manager` - `v1.0.7-dev.9`](#sembast_cache_manager---v107-dev9)
 - [`ndk_cache_manager_test_suite` - `v1.0.1-dev.9`](#ndk_cache_manager_test_suite---v101-dev9)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.4.0-dev.9`
 - `ndk_objectbox` - `v0.2.8-dev.9`
 - `ndk_rust_verifier` - `v0.5.0-dev.9`
 - `nip07_event_signer` - `v1.0.6-dev.9`
 - `sembast_cache_manager` - `v1.0.7-dev.9`
 - `ndk_cache_manager_test_suite` - `v1.0.1-dev.9`

---

#### `ndk` - `v0.7.1-dev.9`

 - **FIX**: complete request when auth-required received without challenge.
 - **FIX**: complete request when relay requires auth but client cannot sign.


## 2026-02-04

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.7.1-dev.8`](#ndk---v071-dev8)
 - [`ndk_amber` - `v0.4.0-dev.8`](#ndk_amber---v040-dev8)
 - [`ndk_objectbox` - `v0.2.8-dev.8`](#ndk_objectbox---v028-dev8)
 - [`ndk_rust_verifier` - `v0.5.0-dev.8`](#ndk_rust_verifier---v050-dev8)
 - [`nip07_event_signer` - `v1.0.6-dev.8`](#nip07_event_signer---v106-dev8)
 - [`sembast_cache_manager` - `v1.0.7-dev.8`](#sembast_cache_manager---v107-dev8)
 - [`ndk_cache_manager_test_suite` - `v1.0.1-dev.8`](#ndk_cache_manager_test_suite---v101-dev8)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.4.0-dev.8`
 - `ndk_objectbox` - `v0.2.8-dev.8`
 - `ndk_rust_verifier` - `v0.5.0-dev.8`
 - `nip07_event_signer` - `v1.0.6-dev.8`
 - `sembast_cache_manager` - `v1.0.7-dev.8`
 - `ndk_cache_manager_test_suite` - `v1.0.1-dev.8`

---

#### `ndk` - `v0.7.1-dev.8`

 - **FIX**: distinguish CLOSED from EOSE in relay request state.


## 2026-02-04

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.7.1-dev.7`](#ndk---v071-dev7)
 - [`ndk_cache_manager_test_suite` - `v1.0.1-dev.7`](#ndk_cache_manager_test_suite---v101-dev7)
 - [`ndk_objectbox` - `v0.2.8-dev.7`](#ndk_objectbox---v028-dev7)
 - [`sembast_cache_manager` - `v1.0.7-dev.7`](#sembast_cache_manager---v107-dev7)
 - [`ndk_amber` - `v0.4.0-dev.7`](#ndk_amber---v040-dev7)
 - [`ndk_rust_verifier` - `v0.5.0-dev.7`](#ndk_rust_verifier---v050-dev7)
 - [`nip07_event_signer` - `v1.0.6-dev.7`](#nip07_event_signer---v106-dev7)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.4.0-dev.7`
 - `ndk_rust_verifier` - `v0.5.0-dev.7`
 - `nip07_event_signer` - `v1.0.6-dev.7`

---

#### `ndk` - `v0.7.1-dev.7`

 - **REFACTOR**: rename nip05.fetch() to nip05.resolve().
 - **REFACTOR**: nip05 usecase.
 - **FEAT**: add caching support for nip05.resolve() with identifier lookup.
 - **FEAT**: add caching support for nip05.resolve()  with identifier lookup.
 - **FEAT**: add caching support for nip05.resolve() with identifier lookup.
 - **FEAT**: add of() method to fetch NIP-05 data without pubkey.

#### `ndk_cache_manager_test_suite` - `v1.0.1-dev.7`

 - **FEAT**: add caching support for nip05.resolve() with identifier lookup.

#### `ndk_objectbox` - `v0.2.8-dev.7`

 - **FEAT**: add caching support for nip05.resolve() with identifier lookup.

#### `sembast_cache_manager` - `v1.0.7-dev.7`

 - **FEAT**: add caching support for nip05.resolve() with identifier lookup.
 - **FEAT**: add caching support for nip05.resolve() with identifier lookup.


## 2026-02-04

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.7.1-dev.6`](#ndk---v071-dev6)
 - [`ndk_amber` - `v0.4.0-dev.6`](#ndk_amber---v040-dev6)
 - [`ndk_objectbox` - `v0.2.8-dev.6`](#ndk_objectbox---v028-dev6)
 - [`ndk_rust_verifier` - `v0.5.0-dev.6`](#ndk_rust_verifier---v050-dev6)
 - [`nip07_event_signer` - `v1.0.6-dev.6`](#nip07_event_signer---v106-dev6)
 - [`sembast_cache_manager` - `v1.0.7-dev.6`](#sembast_cache_manager---v107-dev6)
 - [`ndk_cache_manager_test_suite` - `v1.0.1-dev.6`](#ndk_cache_manager_test_suite---v101-dev6)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.4.0-dev.6`
 - `ndk_objectbox` - `v0.2.8-dev.6`
 - `ndk_rust_verifier` - `v0.5.0-dev.6`
 - `nip07_event_signer` - `v1.0.6-dev.6`
 - `sembast_cache_manager` - `v1.0.7-dev.6`
 - `ndk_cache_manager_test_suite` - `v1.0.1-dev.6`

---

#### `ndk` - `v0.7.1-dev.6`

 - **FIX**: add destroy in tear down.
 - **FIX**: ensure NIP-46 subscription is ready before sending remote requests.
 - **FIX**: subscribe before broadcast in connectWithBunkerUrl to avoid missing NIP-46 responses.


## 2026-02-03

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.7.1-dev.5`](#ndk---v071-dev5)
 - [`ndk_amber` - `v0.4.0-dev.5`](#ndk_amber---v040-dev5)
 - [`ndk_objectbox` - `v0.2.8-dev.5`](#ndk_objectbox---v028-dev5)
 - [`ndk_rust_verifier` - `v0.5.0-dev.5`](#ndk_rust_verifier---v050-dev5)
 - [`nip07_event_signer` - `v1.0.6-dev.5`](#nip07_event_signer---v106-dev5)
 - [`sembast_cache_manager` - `v1.0.7-dev.5`](#sembast_cache_manager---v107-dev5)
 - [`ndk_cache_manager_test_suite` - `v1.0.1-dev.5`](#ndk_cache_manager_test_suite---v101-dev5)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.4.0-dev.5`
 - `ndk_objectbox` - `v0.2.8-dev.5`
 - `ndk_rust_verifier` - `v0.5.0-dev.5`
 - `nip07_event_signer` - `v1.0.6-dev.5`
 - `sembast_cache_manager` - `v1.0.7-dev.5`
 - `ndk_cache_manager_test_suite` - `v1.0.1-dev.5`

---

#### `ndk` - `v0.7.1-dev.5`

 - **FEAT**: add missing state field in lookup_invoice_response.dart.


## 2026-02-03

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.7.1-dev.4`](#ndk---v071-dev4)
 - [`ndk_amber` - `v0.4.0-dev.4`](#ndk_amber---v040-dev4)
 - [`ndk_objectbox` - `v0.2.8-dev.4`](#ndk_objectbox---v028-dev4)
 - [`ndk_rust_verifier` - `v0.5.0-dev.4`](#ndk_rust_verifier---v050-dev4)
 - [`nip07_event_signer` - `v1.0.6-dev.4`](#nip07_event_signer---v106-dev4)
 - [`sembast_cache_manager` - `v1.0.7-dev.4`](#sembast_cache_manager---v107-dev4)
 - [`ndk_cache_manager_test_suite` - `v1.0.1-dev.4`](#ndk_cache_manager_test_suite---v101-dev4)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.4.0-dev.4`
 - `ndk_objectbox` - `v0.2.8-dev.4`
 - `ndk_rust_verifier` - `v0.5.0-dev.4`
 - `nip07_event_signer` - `v1.0.6-dev.4`
 - `sembast_cache_manager` - `v1.0.7-dev.4`
 - `ndk_cache_manager_test_suite` - `v1.0.1-dev.4`

---

#### `ndk` - `v0.7.1-dev.4`

 - **FIX**: move authCallbackTimeout to NdkConfig.
 - **FIX**: add timeout for pending AUTH callbacks.
 - **FIX**: authenticate all accounts in authenticateAs for lazy auth mode.
 - **FIX**: handle NIP-42 auth-required by re-sending REQ/EVENT after AUTH.
 - **FEAT**: add eagerAuth in NDK config.


## 2026-01-31

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.7.1-dev.3`](#ndk---v071-dev3)
 - [`ndk_amber` - `v0.4.0-dev.3`](#ndk_amber---v040-dev3)
 - [`ndk_objectbox` - `v0.2.8-dev.3`](#ndk_objectbox---v028-dev3)
 - [`ndk_rust_verifier` - `v0.5.0-dev.3`](#ndk_rust_verifier---v050-dev3)
 - [`nip07_event_signer` - `v1.0.6-dev.3`](#nip07_event_signer---v106-dev3)
 - [`sembast_cache_manager` - `v1.0.7-dev.3`](#sembast_cache_manager---v107-dev3)
 - [`ndk_cache_manager_test_suite` - `v1.0.1-dev.3`](#ndk_cache_manager_test_suite---v101-dev3)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.4.0-dev.3`
 - `ndk_objectbox` - `v0.2.8-dev.3`
 - `ndk_rust_verifier` - `v0.5.0-dev.3`
 - `nip07_event_signer` - `v1.0.6-dev.3`
 - `sembast_cache_manager` - `v1.0.7-dev.3`
 - `ndk_cache_manager_test_suite` - `v1.0.1-dev.3`

---

#### `ndk` - `v0.7.1-dev.3`

 - **FIX**: rename stateChanges to authStateChanges.
 - **FEAT**: gift wrap add custom signer parameter.


## 2026-01-27

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.7.1-dev.2`](#ndk---v071-dev2)
 - [`ndk_amber` - `v0.4.0-dev.2`](#ndk_amber---v040-dev2)
 - [`ndk_objectbox` - `v0.2.8-dev.2`](#ndk_objectbox---v028-dev2)
 - [`ndk_rust_verifier` - `v0.5.0-dev.2`](#ndk_rust_verifier---v050-dev2)
 - [`nip07_event_signer` - `v1.0.6-dev.2`](#nip07_event_signer---v106-dev2)
 - [`sembast_cache_manager` - `v1.0.7-dev.2`](#sembast_cache_manager---v107-dev2)
 - [`ndk_cache_manager_test_suite` - `v1.0.1-dev.2`](#ndk_cache_manager_test_suite---v101-dev2)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.4.0-dev.2`
 - `ndk_objectbox` - `v0.2.8-dev.2`
 - `ndk_rust_verifier` - `v0.5.0-dev.2`
 - `nip07_event_signer` - `v1.0.6-dev.2`
 - `sembast_cache_manager` - `v1.0.7-dev.2`
 - `ndk_cache_manager_test_suite` - `v1.0.1-dev.2`

---

#### `ndk` - `v0.7.1-dev.2`

 - **FIX**: minIsolatePoolSize.


## 2026-01-24

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.7.1-dev.1`](#ndk---v071-dev1)
 - [`ndk_amber` - `v0.4.0-dev.1`](#ndk_amber---v040-dev1)
 - [`ndk_objectbox` - `v0.2.8-dev.1`](#ndk_objectbox---v028-dev1)
 - [`ndk_rust_verifier` - `v0.5.0-dev.1`](#ndk_rust_verifier---v050-dev1)
 - [`nip07_event_signer` - `v1.0.6-dev.1`](#nip07_event_signer---v106-dev1)
 - [`sembast_cache_manager` - `v1.0.7-dev.1`](#sembast_cache_manager---v107-dev1)
 - [`ndk_cache_manager_test_suite` - `v1.0.1-dev.1`](#ndk_cache_manager_test_suite---v101-dev1)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.4.0-dev.1`
 - `ndk_objectbox` - `v0.2.8-dev.1`
 - `ndk_rust_verifier` - `v0.5.0-dev.1`
 - `nip07_event_signer` - `v1.0.6-dev.1`
 - `sembast_cache_manager` - `v1.0.7-dev.1`
 - `ndk_cache_manager_test_suite` - `v1.0.1-dev.1`

---

#### `ndk` - `v0.7.1-dev.1`

 - **FEAT**: add saveToCache option for broadcast.


## 2026-01-22

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.7.1-dev.0`](#ndk---v071-dev0)
 - [`ndk_objectbox` - `v0.2.8-dev.0`](#ndk_objectbox---v028-dev0)
 - [`ndk_amber` - `v0.4.0-dev.0+1`](#ndk_amber---v040-dev01)
 - [`ndk_rust_verifier` - `v0.5.0-dev.0+1`](#ndk_rust_verifier---v050-dev01)
 - [`nip07_event_signer` - `v1.0.6-dev.0`](#nip07_event_signer---v106-dev0)
 - [`sembast_cache_manager` - `v1.0.7-dev.0`](#sembast_cache_manager---v107-dev0)
 - [`ndk_cache_manager_test_suite` - `v1.0.1-dev.0`](#ndk_cache_manager_test_suite---v101-dev0)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.4.0-dev.0+1`
 - `ndk_rust_verifier` - `v0.5.0-dev.0+1`
 - `nip07_event_signer` - `v1.0.6-dev.0`
 - `sembast_cache_manager` - `v1.0.7-dev.0`
 - `ndk_cache_manager_test_suite` - `v1.0.1-dev.0`

---

#### `ndk` - `v0.7.1-dev.0`

 - **FIX**: use Accounts instead of pubkeys to authenticate.
 - **FEAT**: nip42 multi auth.

#### `ndk_objectbox` - `v0.2.8-dev.0`

 - **REFACTOR**: other packages.
 - **FIX**: clean imports.
 - **FEAT**: cache managers support.
 - **FEAT**: objectbox test.
 - **FEAT**: unify cache events api.


## 2026-01-21

### Changes

---

Packages with breaking changes:

 - [`ndk` - `v0.6.1`](#ndk---v061)
 - [`ndk_amber` - `v0.3.3`](#ndk_amber---v033)
 - [`ndk_cache_manager_test_suite` - `v1.0.0`](#ndk_cache_manager_test_suite---v100)
 - [`ndk_objectbox` - `v0.2.7`](#ndk_objectbox---v027)
 - [`ndk_rust_verifier` - `v0.4.2`](#ndk_rust_verifier---v042)
 - [`rust_lib_ndk` - `v0.1.7+1`](#rust_lib_ndk---v0171)

Packages with other changes:

 - [`nip07_event_signer` - `v1.0.5`](#nip07_event_signer---v105)
 - [`sembast_cache_manager` - `v1.0.6`](#sembast_cache_manager---v106)

Packages graduated to a stable release (see pre-releases prior to the stable version for changelog entries):

 - `ndk` - `v0.6.1`
 - `ndk_amber` - `v0.3.3`
 - `ndk_cache_manager_test_suite` - `v1.0.0`
 - `ndk_objectbox` - `v0.2.7`
 - `ndk_rust_verifier` - `v0.4.2`
 - `nip07_event_signer` - `v1.0.5`
 - `rust_lib_ndk` - `v0.1.7+1`
 - `sembast_cache_manager` - `v1.0.6`

---

#### `ndk` - `v0.6.1`

#### `ndk_amber` - `v0.3.3`

#### `ndk_cache_manager_test_suite` - `v1.0.0`

#### `ndk_objectbox` - `v0.2.7`

#### `ndk_rust_verifier` - `v0.4.2`

#### `rust_lib_ndk` - `v0.1.7+1`

#### `nip07_event_signer` - `v1.0.5`

#### `sembast_cache_manager` - `v1.0.6`


## 2026-01-21

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk_objectbox` - `v0.2.7-dev.10`](#ndk_objectbox---v027-dev10)

---

#### `ndk_objectbox` - `v0.2.7-dev.10`

 - **REFACTOR**: other packages.
 - **FIX**: clean imports.
 - **FEAT**: cache managers support.
 - **FEAT**: objectbox test.
 - **FEAT**: unify cache events api.


## 2026-01-21

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.6.1-dev.9`](#ndk---v061-dev9)
 - [`ndk_amber` - `v0.3.3-dev.10`](#ndk_amber---v033-dev10)
 - [`ndk_rust_verifier` - `v0.4.2-dev.10`](#ndk_rust_verifier---v042-dev10)
 - [`ndk_objectbox` - `v0.2.7-dev.9`](#ndk_objectbox---v027-dev9)
 - [`nip07_event_signer` - `v1.0.5-dev.9`](#nip07_event_signer---v105-dev9)
 - [`sembast_cache_manager` - `v1.0.6-dev.10`](#sembast_cache_manager---v106-dev10)
 - [`ndk_cache_manager_test_suite` - `v1.0.0-dev.4`](#ndk_cache_manager_test_suite---v100-dev4)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_objectbox` - `v0.2.7-dev.9`
 - `nip07_event_signer` - `v1.0.5-dev.9`
 - `sembast_cache_manager` - `v1.0.6-dev.10`
 - `ndk_cache_manager_test_suite` - `v1.0.0-dev.4`

---

#### `ndk` - `v0.6.1-dev.9`

 - **FEAT**: isolate manager stub.

#### `ndk_amber` - `v0.3.3-dev.10`

 - **REFACTOR**: signer, amber.
 - **FIX**: clean imports.
 - **FIX**: missing convert  dependency.
 - **FIX**: remove hex package depandance.

#### `ndk_rust_verifier` - `v0.4.2-dev.10`

 - **REFACTOR**: other packages.
 - **FIX**: clean imports.
 - **FIX**: remove hex package depandance.
 - **FEAT**: add doc.


## 2026-01-20

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.6.1-dev.8`](#ndk---v061-dev8)
 - [`ndk_cache_manager_test_suite` - `v1.0.0-dev.3`](#ndk_cache_manager_test_suite---v100-dev3)
 - [`ndk_objectbox` - `v0.2.7-dev.8`](#ndk_objectbox---v027-dev8)
 - [`sembast_cache_manager` - `v1.0.6-dev.9`](#sembast_cache_manager---v106-dev9)
 - [`ndk_amber` - `v0.3.3-dev.9`](#ndk_amber---v033-dev9)
 - [`ndk_rust_verifier` - `v0.4.2-dev.9`](#ndk_rust_verifier---v042-dev9)
 - [`nip07_event_signer` - `v1.0.5-dev.8`](#nip07_event_signer---v105-dev8)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.3.3-dev.9`
 - `ndk_rust_verifier` - `v0.4.2-dev.9`
 - `nip07_event_signer` - `v1.0.5-dev.8`

---

#### `ndk` - `v0.6.1-dev.8`

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

#### `ndk_cache_manager_test_suite` - `v1.0.0-dev.3`

 - **FIX**: mem cache test.

#### `ndk_objectbox` - `v0.2.7-dev.8`

 - **REFACTOR**: other packages.
 - **FIX**: clean imports.
 - **FEAT**: cache managers support.
 - **FEAT**: objectbox test.
 - **FEAT**: unify cache events api.

#### `sembast_cache_manager` - `v1.0.6-dev.9`

 - **FEAT**: cache managers support.
 - **FEAT**: unify cache events api.


## 2026-01-15

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.6.1-dev.7`](#ndk---v061-dev7)
 - [`ndk_amber` - `v0.3.3-dev.8`](#ndk_amber---v033-dev8)
 - [`ndk_isar` - `v0.2.3-dev.8`](#ndk_isar---v023-dev8)
 - [`ndk_objectbox` - `v0.2.7-dev.7`](#ndk_objectbox---v027-dev7)
 - [`ndk_rust_verifier` - `v0.4.2-dev.8`](#ndk_rust_verifier---v042-dev8)
 - [`nip07_event_signer` - `v1.0.5-dev.7`](#nip07_event_signer---v105-dev7)
 - [`sembast_cache_manager` - `v1.0.6-dev.8`](#sembast_cache_manager---v106-dev8)
 - [`ndk_cache_manager_test_suite` - `v1.0.0-dev.2`](#ndk_cache_manager_test_suite---v100-dev2)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_cache_manager_test_suite` - `v1.0.0-dev.2`

---

#### `ndk` - `v0.6.1-dev.7`

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

#### `ndk_amber` - `v0.3.3-dev.8`

 - **REFACTOR**: signer, amber.
 - **FIX**: clean imports.
 - **FIX**: missing convert  dependency.
 - **FIX**: remove hex package depandance.

#### `ndk_isar` - `v0.2.3-dev.8`

 - **FIX**: clean imports.
 - **FIX**: blossom signing.
 - **FIX**: websocket state check optimization.
 - **FEAT**: add test suite in actual cache tests.

#### `ndk_objectbox` - `v0.2.7-dev.7`

 - **REFACTOR**: other packages.
 - **FEAT**: objectbox test.

#### `ndk_rust_verifier` - `v0.4.2-dev.8`

 - **REFACTOR**: other packages.
 - **FIX**: clean imports.
 - **FIX**: remove hex package depandance.
 - **FEAT**: add doc.

#### `nip07_event_signer` - `v1.0.5-dev.7`

 - **REFACTOR**: nip07, amber, sembast.
 - **REFACTOR**: other packages.

#### `sembast_cache_manager` - `v1.0.6-dev.8`

 - **REFACTOR**: nip07, amber, sembast.
 - **REFACTOR**: other packages.
 - **FEAT**: add test suite in actual cache tests.


## 2026-01-07

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.6.1-dev.6`](#ndk---v061-dev6)
 - [`ndk_objectbox` - `v0.2.7-dev.6`](#ndk_objectbox---v027-dev6)
 - [`ndk_amber` - `v0.3.3-dev.7`](#ndk_amber---v033-dev7)
 - [`ndk_isar` - `v0.2.3-dev.7`](#ndk_isar---v023-dev7)
 - [`ndk_rust_verifier` - `v0.4.2-dev.7`](#ndk_rust_verifier---v042-dev7)
 - [`nip07_event_signer` - `v1.0.5-dev.6`](#nip07_event_signer---v105-dev6)
 - [`sembast_cache_manager` - `v1.0.6-dev.7`](#sembast_cache_manager---v106-dev7)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.3.3-dev.7`
 - `ndk_isar` - `v0.2.3-dev.7`
 - `ndk_rust_verifier` - `v0.4.2-dev.7`
 - `nip07_event_signer` - `v1.0.5-dev.6`
 - `sembast_cache_manager` - `v1.0.6-dev.7`

---

#### `ndk` - `v0.6.1-dev.6`

 - **FEAT**: add tests.
 - **FEAT**: deprecation message for filters.

#### `ndk_objectbox` - `v0.2.7-dev.6`

 - **FIX**: clean imports.


## 2026-01-07

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.6.1-dev.5`](#ndk---v061-dev5)
 - [`ndk_amber` - `v0.3.3-dev.6`](#ndk_amber---v033-dev6)
 - [`ndk_isar` - `v0.2.3-dev.6`](#ndk_isar---v023-dev6)
 - [`ndk_objectbox` - `v0.2.7-dev.5`](#ndk_objectbox---v027-dev5)
 - [`ndk_rust_verifier` - `v0.4.2-dev.6`](#ndk_rust_verifier---v042-dev6)
 - [`nip07_event_signer` - `v1.0.5-dev.5`](#nip07_event_signer---v105-dev5)
 - [`sembast_cache_manager` - `v1.0.6-dev.6`](#sembast_cache_manager---v106-dev6)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `nip07_event_signer` - `v1.0.5-dev.5`
 - `sembast_cache_manager` - `v1.0.6-dev.6`

---

#### `ndk` - `v0.6.1-dev.5`

 - **FIX**: bip340 event verifier.
 - **FEAT**: add test.

#### `ndk_amber` - `v0.3.3-dev.6`

 - **FIX**: clean imports.
 - **FIX**: missing convert  dependency.
 - **FIX**: remove hex package depandance.

#### `ndk_isar` - `v0.2.3-dev.6`

 - **FIX**: clean imports.
 - **FEAT**: log color, params.

#### `ndk_objectbox` - `v0.2.7-dev.5`

 - **FIX**: clean imports.

#### `ndk_rust_verifier` - `v0.4.2-dev.6`

 - **FIX**: clean imports.
 - **FIX**: remove hex package depandance.


## 2025-12-15

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.6.1-dev.4`](#ndk---v061-dev4)
 - [`ndk_amber` - `v0.3.3-dev.5`](#ndk_amber---v033-dev5)
 - [`ndk_isar` - `v0.2.3-dev.5`](#ndk_isar---v023-dev5)
 - [`ndk_objectbox` - `v0.2.7-dev.4`](#ndk_objectbox---v027-dev4)
 - [`ndk_rust_verifier` - `v0.4.2-dev.5`](#ndk_rust_verifier---v042-dev5)
 - [`nip07_event_signer` - `v1.0.5-dev.4`](#nip07_event_signer---v105-dev4)
 - [`sembast_cache_manager` - `v1.0.6-dev.5`](#sembast_cache_manager---v106-dev5)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `nip07_event_signer` - `v1.0.5-dev.4`
 - `sembast_cache_manager` - `v1.0.6-dev.5`

---

#### `ndk` - `v0.6.1-dev.4`

 - **FIX**: clean imports.
 - **FIX**: improve relay reconnection.

#### `ndk_amber` - `v0.3.3-dev.5`

 - **FIX**: clean imports.

#### `ndk_isar` - `v0.2.3-dev.5`

 - **FIX**: clean imports.

#### `ndk_objectbox` - `v0.2.7-dev.4`

 - **FIX**: clean imports.

#### `ndk_rust_verifier` - `v0.4.2-dev.5`

 - **FIX**: clean imports.
 - **FIX**: remove hex package depandance.


## 2025-12-10

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.6.1-dev.3`](#ndk---v061-dev3)
 - [`ndk_amber` - `v0.3.3-dev.4`](#ndk_amber---v033-dev4)
 - [`ndk_isar` - `v0.2.3-dev.4`](#ndk_isar---v023-dev4)
 - [`ndk_objectbox` - `v0.2.7-dev.3`](#ndk_objectbox---v027-dev3)
 - [`ndk_rust_verifier` - `v0.4.2-dev.4`](#ndk_rust_verifier---v042-dev4)
 - [`nip07_event_signer` - `v1.0.5-dev.3`](#nip07_event_signer---v105-dev3)
 - [`sembast_cache_manager` - `v1.0.6-dev.4`](#sembast_cache_manager---v106-dev4)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_objectbox` - `v0.2.7-dev.3`
 - `ndk_rust_verifier` - `v0.4.2-dev.4`
 - `nip07_event_signer` - `v1.0.5-dev.3`
 - `sembast_cache_manager` - `v1.0.6-dev.4`

---

#### `ndk` - `v0.6.1-dev.3`

 - **FIX**: close relay.

#### `ndk_amber` - `v0.3.3-dev.4`

 - **FIX**: missing convert  dependency.
 - **FIX**: remove hex package depandance.

#### `ndk_isar` - `v0.2.3-dev.4`

 - **FEAT**: log color, params.


## 2025-12-10

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk_amber` - `v0.3.3-dev.3`](#ndk_amber---v033-dev3)
 - [`ndk_isar` - `v0.2.3-dev.3`](#ndk_isar---v023-dev3)
 - [`ndk_rust_verifier` - `v0.4.2-dev.3`](#ndk_rust_verifier---v042-dev3)
 - [`sembast_cache_manager` - `v1.0.6-dev.3`](#sembast_cache_manager---v106-dev3)

---

#### `ndk_amber` - `v0.3.3-dev.3`

 - **FIX**: missing convert  dependency.
 - **FIX**: remove hex package depandance.

#### `ndk_isar` - `v0.2.3-dev.3`

 - **FEAT**: log color, params.

#### `ndk_rust_verifier` - `v0.4.2-dev.3`

 - **FIX**: remove hex package depandance.

#### `sembast_cache_manager` - `v1.0.6-dev.3`

 - **FEAT**: wildcard tag search.


## 2025-12-09

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.6.1-dev.2`](#ndk---v061-dev2)
 - [`ndk_amber` - `v0.3.3-dev.2`](#ndk_amber---v033-dev2)
 - [`ndk_isar` - `v0.2.3-dev.2`](#ndk_isar---v023-dev2)
 - [`ndk_objectbox` - `v0.2.7-dev.2`](#ndk_objectbox---v027-dev2)
 - [`ndk_rust_verifier` - `v0.4.2-dev.2`](#ndk_rust_verifier---v042-dev2)
 - [`nip07_event_signer` - `v1.0.5-dev.2`](#nip07_event_signer---v105-dev2)
 - [`sembast_cache_manager` - `v1.0.6-dev.2`](#sembast_cache_manager---v106-dev2)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.3.3-dev.2`
 - `ndk_isar` - `v0.2.3-dev.2`
 - `ndk_objectbox` - `v0.2.7-dev.2`
 - `ndk_rust_verifier` - `v0.4.2-dev.2`
 - `nip07_event_signer` - `v1.0.5-dev.2`
 - `sembast_cache_manager` - `v1.0.6-dev.2`

---

#### `ndk` - `v0.6.1-dev.2`

 - **FIX**: Handle null error value in NWC response deserialization.
 - **FIX**: forcing a pre-release.
 - **FIX**: move test to an apropriate area.
 - **FIX**: clean relay url function + add tests.
 - **FEAT**: add test.


## 2025-11-30

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.6.1-dev.1`](#ndk---v061-dev1)
 - [`ndk_amber` - `v0.3.3-dev.1`](#ndk_amber---v033-dev1)
 - [`ndk_isar` - `v0.2.3-dev.1`](#ndk_isar---v023-dev1)
 - [`ndk_objectbox` - `v0.2.7-dev.1`](#ndk_objectbox---v027-dev1)
 - [`ndk_rust_verifier` - `v0.4.2-dev.1`](#ndk_rust_verifier---v042-dev1)
 - [`nip07_event_signer` - `v1.0.5-dev.1`](#nip07_event_signer---v105-dev1)
 - [`sembast_cache_manager` - `v1.0.6-dev.1`](#sembast_cache_manager---v106-dev1)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `nip07_event_signer` - `v1.0.5-dev.1`
 - `sembast_cache_manager` - `v1.0.6-dev.1`

---

#### `ndk` - `v0.6.1-dev.1`

 - **FIX**: update the mock relay + test.
 - **FIX**: test pass.
 - **FEAT**: add a test.

#### `ndk_amber` - `v0.3.3-dev.1`

 - **FIX**: missing convert  dependency.
 - **FIX**: remove hex package depandance.

#### `ndk_isar` - `v0.2.3-dev.1`

 - **FEAT**: log color, params.

#### `ndk_objectbox` - `v0.2.7-dev.1`

 - **FIX**: import cosmetics.

#### `ndk_rust_verifier` - `v0.4.2-dev.1`

 - **REFACTOR**: secp256k1 to rust native dep.
 - **FIX**: remove hex package depandance.
 - **FEAT**: rust verifier web assets.


## 2025-11-29

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.6.1-dev.0`](#ndk---v061-dev0)
 - [`rust_lib_ndk` - `v0.1.7-dev.0+1`](#rust_lib_ndk---v017-dev01)
 - [`ndk_amber` - `v0.3.3-dev.0+1`](#ndk_amber---v033-dev01)
 - [`ndk_isar` - `v0.2.3-dev.0+1`](#ndk_isar---v023-dev01)
 - [`ndk_objectbox` - `v0.2.7-dev.0+1`](#ndk_objectbox---v027-dev01)
 - [`ndk_rust_verifier` - `v0.4.2-dev.0+1`](#ndk_rust_verifier---v042-dev01)
 - [`nip07_event_signer` - `v1.0.5-dev.0`](#nip07_event_signer---v105-dev0)
 - [`sembast_cache_manager` - `v1.0.6-dev.0`](#sembast_cache_manager---v106-dev0)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.3.3-dev.0+1`
 - `ndk_isar` - `v0.2.3-dev.0+1`
 - `ndk_objectbox` - `v0.2.7-dev.0+1`
 - `ndk_rust_verifier` - `v0.4.2-dev.0+1`
 - `nip07_event_signer` - `v1.0.5-dev.0`
 - `sembast_cache_manager` - `v1.0.6-dev.0`

---

#### `ndk` - `v0.6.1-dev.0`

 - **FIX**: use mock relay.
 - **FIX**: new test pass.
 - **FEAT**: test.

#### `rust_lib_ndk` - `v0.1.7-dev.0+1`

 - **REFACTOR**: secp256k1 to rust native dep.
 - **FIX**: remove hex package depandance.


## 2025-11-20

### Changes

---

Packages with breaking changes:

 - [`ndk_amber` - `v0.3.3`](#ndk_amber---v033)
 - [`ndk_objectbox` - `v0.2.7`](#ndk_objectbox---v027)
 - [`ndk_rust_verifier` - `v0.4.2`](#ndk_rust_verifier---v042)
 - [`rust_lib_ndk` - `v0.1.7`](#rust_lib_ndk---v017)

Packages with other changes:

 - [`ndk` - `v0.6.0`](#ndk---v060)
 - [`nip07_event_signer` - `v1.0.4`](#nip07_event_signer---v104)
 - [`sembast_cache_manager` - `v1.0.5`](#sembast_cache_manager---v105)

Packages graduated to a stable release (see pre-releases prior to the stable version for changelog entries):

 - `ndk` - `v0.6.0`
 - `ndk_amber` - `v0.3.3`
 - `ndk_objectbox` - `v0.2.7`
 - `ndk_rust_verifier` - `v0.4.2`
 - `nip07_event_signer` - `v1.0.4`
 - `rust_lib_ndk` - `v0.1.7`
 - `sembast_cache_manager` - `v1.0.5`

---

#### `ndk_amber` - `v0.3.3`

#### `ndk_objectbox` - `v0.2.7`

#### `ndk_rust_verifier` - `v0.4.2`

#### `rust_lib_ndk` - `v0.1.7`

#### `ndk` - `v0.6.0`

#### `nip07_event_signer` - `v1.0.4`

#### `sembast_cache_manager` - `v1.0.5`


## 2025-11-20

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.6.0-dev.20`](#ndk---v060-dev20)
 - [`ndk_amber` - `v0.3.3-dev.23`](#ndk_amber---v033-dev23)
 - [`ndk_isar` - `v0.2.3-dev.23`](#ndk_isar---v023-dev23)
 - [`ndk_objectbox` - `v0.2.7-dev.25`](#ndk_objectbox---v027-dev25)
 - [`ndk_rust_verifier` - `v0.4.2-dev.25`](#ndk_rust_verifier---v042-dev25)
 - [`nip07_event_signer` - `v1.0.4-dev.23`](#nip07_event_signer---v104-dev23)
 - [`sembast_cache_manager` - `v1.0.5-dev.23`](#sembast_cache_manager---v105-dev23)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.3.3-dev.23`
 - `ndk_isar` - `v0.2.3-dev.23`
 - `ndk_objectbox` - `v0.2.7-dev.25`
 - `ndk_rust_verifier` - `v0.4.2-dev.25`
 - `nip07_event_signer` - `v1.0.4-dev.23`
 - `sembast_cache_manager` - `v1.0.5-dev.23`

---

#### `ndk` - `v0.6.0-dev.20`

 - **REFACTOR**: remove param signer from lists api.
 - **REFACTOR**: use immutable event in toEvent().
 - **REFACTOR**: reoder, naming, description.
 - **FIX**: upgrade to nip44.
 - **FIX**: mock relay delete from memory.
 - **FIX**: calculate id in nip51set.
 - **FEAT**: lists nip04 backwards compatibility with nip04.
 - **FEAT**: delete set.


## 2025-11-20

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.6.0-dev.19`](#ndk---v060-dev19)
 - [`ndk_amber` - `v0.3.3-dev.22`](#ndk_amber---v033-dev22)
 - [`ndk_isar` - `v0.2.3-dev.22`](#ndk_isar---v023-dev22)
 - [`ndk_objectbox` - `v0.2.7-dev.24`](#ndk_objectbox---v027-dev24)
 - [`ndk_rust_verifier` - `v0.4.2-dev.24`](#ndk_rust_verifier---v042-dev24)
 - [`nip07_event_signer` - `v1.0.4-dev.22`](#nip07_event_signer---v104-dev22)
 - [`sembast_cache_manager` - `v1.0.5-dev.22`](#sembast_cache_manager---v105-dev22)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.3.3-dev.22`
 - `ndk_isar` - `v0.2.3-dev.22`
 - `ndk_objectbox` - `v0.2.7-dev.24`
 - `ndk_rust_verifier` - `v0.4.2-dev.24`
 - `nip07_event_signer` - `v1.0.4-dev.22`
 - `sembast_cache_manager` - `v1.0.5-dev.22`

---

#### `ndk` - `v0.6.0-dev.19`

 - **REFACTOR**: remove param signer from lists api.
 - **REFACTOR**: use immutable event in toEvent().
 - **REFACTOR**: reoder, naming, description.
 - **FIX**: upgrade to nip44.
 - **FIX**: mock relay delete from memory.
 - **FIX**: calculate id in nip51set.
 - **FEAT**: lists nip04 backwards compatibility with nip04.
 - **FEAT**: delete set.


## 2025-11-19

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.6.0-dev.18`](#ndk---v060-dev18)
 - [`ndk_amber` - `v0.3.3-dev.21`](#ndk_amber---v033-dev21)
 - [`ndk_rust_verifier` - `v0.4.2-dev.23`](#ndk_rust_verifier---v042-dev23)
 - [`rust_lib_ndk` - `v0.1.7-dev.2`](#rust_lib_ndk---v017-dev2)
 - [`ndk_isar` - `v0.2.3-dev.21`](#ndk_isar---v023-dev21)
 - [`ndk_objectbox` - `v0.2.7-dev.23`](#ndk_objectbox---v027-dev23)
 - [`nip07_event_signer` - `v1.0.4-dev.21`](#nip07_event_signer---v104-dev21)
 - [`sembast_cache_manager` - `v1.0.5-dev.21`](#sembast_cache_manager---v105-dev21)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_isar` - `v0.2.3-dev.21`
 - `ndk_objectbox` - `v0.2.7-dev.23`
 - `nip07_event_signer` - `v1.0.4-dev.21`
 - `sembast_cache_manager` - `v1.0.5-dev.21`

---

#### `ndk` - `v0.6.0-dev.18`

 - **FIX**: missing convert  dependency.
 - **FIX**: remove hex package depandance.

#### `ndk_amber` - `v0.3.3-dev.21`

 - **FIX**: missing convert  dependency.
 - **FIX**: remove hex package depandance.

#### `ndk_rust_verifier` - `v0.4.2-dev.23`

 - **FIX**: remove hex package depandance.

#### `rust_lib_ndk` - `v0.1.7-dev.2`

 - **FIX**: remove hex package depandance.


## 2025-11-19

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.6.0-dev.17`](#ndk---v060-dev17)
 - [`ndk_amber` - `v0.3.3-dev.20`](#ndk_amber---v033-dev20)
 - [`ndk_rust_verifier` - `v0.4.2-dev.22`](#ndk_rust_verifier---v042-dev22)
 - [`rust_lib_ndk` - `v0.1.7-dev.1`](#rust_lib_ndk---v017-dev1)
 - [`ndk_isar` - `v0.2.3-dev.20`](#ndk_isar---v023-dev20)
 - [`ndk_objectbox` - `v0.2.7-dev.22`](#ndk_objectbox---v027-dev22)
 - [`nip07_event_signer` - `v1.0.4-dev.20`](#nip07_event_signer---v104-dev20)
 - [`sembast_cache_manager` - `v1.0.5-dev.20`](#sembast_cache_manager---v105-dev20)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_isar` - `v0.2.3-dev.20`
 - `ndk_objectbox` - `v0.2.7-dev.22`
 - `nip07_event_signer` - `v1.0.4-dev.20`
 - `sembast_cache_manager` - `v1.0.5-dev.20`

---

#### `ndk` - `v0.6.0-dev.17`

 - **FIX**: missing convert  dependency.
 - **FIX**: remove hex package depandance.

#### `ndk_amber` - `v0.3.3-dev.20`

 - **FIX**: missing convert  dependency.
 - **FIX**: remove hex package depandance.

#### `ndk_rust_verifier` - `v0.4.2-dev.22`

 - **FIX**: remove hex package depandance.

#### `rust_lib_ndk` - `v0.1.7-dev.1`

 - **FIX**: remove hex package depandance.


## 2025-11-19

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.6.0-dev.16`](#ndk---v060-dev16)
 - [`ndk_amber` - `v0.3.3-dev.19`](#ndk_amber---v033-dev19)
 - [`ndk_isar` - `v0.2.3-dev.19`](#ndk_isar---v023-dev19)
 - [`ndk_objectbox` - `v0.2.7-dev.21`](#ndk_objectbox---v027-dev21)
 - [`ndk_rust_verifier` - `v0.4.2-dev.21`](#ndk_rust_verifier---v042-dev21)
 - [`nip07_event_signer` - `v1.0.4-dev.19`](#nip07_event_signer---v104-dev19)
 - [`sembast_cache_manager` - `v1.0.5-dev.19`](#sembast_cache_manager---v105-dev19)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.3.3-dev.19`
 - `ndk_isar` - `v0.2.3-dev.19`
 - `ndk_objectbox` - `v0.2.7-dev.21`
 - `ndk_rust_verifier` - `v0.4.2-dev.21`
 - `nip07_event_signer` - `v1.0.4-dev.19`
 - `sembast_cache_manager` - `v1.0.5-dev.19`

---

#### `ndk` - `v0.6.0-dev.16`

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


## 2025-11-19

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.6.0-dev.15`](#ndk---v060-dev15)
 - [`ndk_amber` - `v0.3.3-dev.18`](#ndk_amber---v033-dev18)
 - [`ndk_isar` - `v0.2.3-dev.18`](#ndk_isar---v023-dev18)
 - [`ndk_objectbox` - `v0.2.7-dev.20`](#ndk_objectbox---v027-dev20)
 - [`ndk_rust_verifier` - `v0.4.2-dev.20`](#ndk_rust_verifier---v042-dev20)
 - [`nip07_event_signer` - `v1.0.4-dev.18`](#nip07_event_signer---v104-dev18)
 - [`sembast_cache_manager` - `v1.0.5-dev.18`](#sembast_cache_manager---v105-dev18)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.3.3-dev.18`
 - `ndk_isar` - `v0.2.3-dev.18`
 - `ndk_objectbox` - `v0.2.7-dev.20`
 - `ndk_rust_verifier` - `v0.4.2-dev.20`
 - `nip07_event_signer` - `v1.0.4-dev.18`
 - `sembast_cache_manager` - `v1.0.5-dev.18`

---

#### `ndk` - `v0.6.0-dev.15`

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


## 2025-11-17

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.6.0-dev.14`](#ndk---v060-dev14)
 - [`ndk_amber` - `v0.3.3-dev.17`](#ndk_amber---v033-dev17)
 - [`ndk_isar` - `v0.2.3-dev.17`](#ndk_isar---v023-dev17)
 - [`ndk_objectbox` - `v0.2.7-dev.19`](#ndk_objectbox---v027-dev19)
 - [`ndk_rust_verifier` - `v0.4.2-dev.19`](#ndk_rust_verifier---v042-dev19)
 - [`nip07_event_signer` - `v1.0.4-dev.17`](#nip07_event_signer---v104-dev17)
 - [`sembast_cache_manager` - `v1.0.5-dev.17`](#sembast_cache_manager---v105-dev17)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.3.3-dev.17`
 - `ndk_isar` - `v0.2.3-dev.17`
 - `ndk_objectbox` - `v0.2.7-dev.19`
 - `ndk_rust_verifier` - `v0.4.2-dev.19`
 - `nip07_event_signer` - `v1.0.4-dev.17`
 - `sembast_cache_manager` - `v1.0.5-dev.17`

---

#### `ndk` - `v0.6.0-dev.14`

 - **FIX**: waiting for connection broadcast jit.


## 2025-11-17

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.6.0-dev.13`](#ndk---v060-dev13)
 - [`ndk_amber` - `v0.3.3-dev.16`](#ndk_amber---v033-dev16)
 - [`ndk_isar` - `v0.2.3-dev.16`](#ndk_isar---v023-dev16)
 - [`ndk_objectbox` - `v0.2.7-dev.18`](#ndk_objectbox---v027-dev18)
 - [`ndk_rust_verifier` - `v0.4.2-dev.18`](#ndk_rust_verifier---v042-dev18)
 - [`nip07_event_signer` - `v1.0.4-dev.16`](#nip07_event_signer---v104-dev16)
 - [`sembast_cache_manager` - `v1.0.5-dev.16`](#sembast_cache_manager---v105-dev16)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.3.3-dev.16`
 - `ndk_isar` - `v0.2.3-dev.16`
 - `ndk_objectbox` - `v0.2.7-dev.18`
 - `ndk_rust_verifier` - `v0.4.2-dev.18`
 - `nip07_event_signer` - `v1.0.4-dev.16`
 - `sembast_cache_manager` - `v1.0.5-dev.16`

---

#### `ndk` - `v0.6.0-dev.13`

 - **FIX**: waiting for connection broadcast jit.


## 2025-11-14

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.6.0-dev.12`](#ndk---v060-dev12)
 - [`ndk_amber` - `v0.3.3-dev.15`](#ndk_amber---v033-dev15)
 - [`ndk_isar` - `v0.2.3-dev.15`](#ndk_isar---v023-dev15)
 - [`ndk_objectbox` - `v0.2.7-dev.17`](#ndk_objectbox---v027-dev17)
 - [`ndk_rust_verifier` - `v0.4.2-dev.17`](#ndk_rust_verifier---v042-dev17)
 - [`nip07_event_signer` - `v1.0.4-dev.15`](#nip07_event_signer---v104-dev15)
 - [`sembast_cache_manager` - `v1.0.5-dev.15`](#sembast_cache_manager---v105-dev15)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.3.3-dev.15`
 - `ndk_isar` - `v0.2.3-dev.15`
 - `ndk_objectbox` - `v0.2.7-dev.17`
 - `ndk_rust_verifier` - `v0.4.2-dev.17`
 - `nip07_event_signer` - `v1.0.4-dev.15`
 - `sembast_cache_manager` - `v1.0.5-dev.15`

---

#### `ndk` - `v0.6.0-dev.12`

 - **FIX**: Use 0x100000000 instead of 1 << 32 for web compatibility.


## 2025-11-14

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.6.0-dev.11`](#ndk---v060-dev11)
 - [`ndk_amber` - `v0.3.3-dev.14`](#ndk_amber---v033-dev14)
 - [`ndk_isar` - `v0.2.3-dev.14`](#ndk_isar---v023-dev14)
 - [`ndk_objectbox` - `v0.2.7-dev.16`](#ndk_objectbox---v027-dev16)
 - [`ndk_rust_verifier` - `v0.4.2-dev.16`](#ndk_rust_verifier---v042-dev16)
 - [`nip07_event_signer` - `v1.0.4-dev.14`](#nip07_event_signer---v104-dev14)
 - [`sembast_cache_manager` - `v1.0.5-dev.14`](#sembast_cache_manager---v105-dev14)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.3.3-dev.14`
 - `ndk_isar` - `v0.2.3-dev.14`
 - `ndk_objectbox` - `v0.2.7-dev.16`
 - `ndk_rust_verifier` - `v0.4.2-dev.16`
 - `nip07_event_signer` - `v1.0.4-dev.14`
 - `sembast_cache_manager` - `v1.0.5-dev.14`

---

#### `ndk` - `v0.6.0-dev.11`

 - **FIX**: Use 0x100000000 instead of 1 << 32 for web compatibility.


## 2025-11-12

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.6.0-dev.10`](#ndk---v060-dev10)
 - [`ndk_amber` - `v0.3.3-dev.13`](#ndk_amber---v033-dev13)
 - [`ndk_isar` - `v0.2.3-dev.13`](#ndk_isar---v023-dev13)
 - [`ndk_objectbox` - `v0.2.7-dev.15`](#ndk_objectbox---v027-dev15)
 - [`ndk_rust_verifier` - `v0.4.2-dev.15`](#ndk_rust_verifier---v042-dev15)
 - [`nip07_event_signer` - `v1.0.4-dev.13`](#nip07_event_signer---v104-dev13)
 - [`sembast_cache_manager` - `v1.0.5-dev.13`](#sembast_cache_manager---v105-dev13)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.3.3-dev.13`
 - `ndk_isar` - `v0.2.3-dev.13`
 - `ndk_objectbox` - `v0.2.7-dev.15`
 - `ndk_rust_verifier` - `v0.4.2-dev.15`
 - `nip07_event_signer` - `v1.0.4-dev.13`
 - `sembast_cache_manager` - `v1.0.5-dev.13`

---

#### `ndk` - `v0.6.0-dev.10`

 - **FIX**: add id recalculation in Nip01Event.copyWith.
 - **FIX**: make the test "validate event: greater POW" predictable.
 - **FIX**: wrap json.decode with a try catch block.


## 2025-11-12

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.6.0-dev.9`](#ndk---v060-dev9)
 - [`ndk_amber` - `v0.3.3-dev.12`](#ndk_amber---v033-dev12)
 - [`ndk_isar` - `v0.2.3-dev.12`](#ndk_isar---v023-dev12)
 - [`ndk_objectbox` - `v0.2.7-dev.14`](#ndk_objectbox---v027-dev14)
 - [`ndk_rust_verifier` - `v0.4.2-dev.14`](#ndk_rust_verifier---v042-dev14)
 - [`nip07_event_signer` - `v1.0.4-dev.12`](#nip07_event_signer---v104-dev12)
 - [`sembast_cache_manager` - `v1.0.5-dev.12`](#sembast_cache_manager---v105-dev12)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.3.3-dev.12`
 - `ndk_isar` - `v0.2.3-dev.12`
 - `ndk_objectbox` - `v0.2.7-dev.14`
 - `ndk_rust_verifier` - `v0.4.2-dev.14`
 - `nip07_event_signer` - `v1.0.4-dev.12`
 - `sembast_cache_manager` - `v1.0.5-dev.12`

---

#### `ndk` - `v0.6.0-dev.9`

 - **FIX**: add id recalculation in Nip01Event.copyWith.
 - **FIX**: make the test "validate event: greater POW" predictable.
 - **FIX**: wrap json.decode with a try catch block.


## 2025-11-05

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.6.0-dev.8`](#ndk---v060-dev8)
 - [`ndk_amber` - `v0.3.3-dev.11`](#ndk_amber---v033-dev11)
 - [`ndk_isar` - `v0.2.3-dev.11`](#ndk_isar---v023-dev11)
 - [`ndk_objectbox` - `v0.2.7-dev.13`](#ndk_objectbox---v027-dev13)
 - [`ndk_rust_verifier` - `v0.4.2-dev.13`](#ndk_rust_verifier---v042-dev13)
 - [`nip07_event_signer` - `v1.0.4-dev.11`](#nip07_event_signer---v104-dev11)
 - [`sembast_cache_manager` - `v1.0.5-dev.11`](#sembast_cache_manager---v105-dev11)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.3.3-dev.11`
 - `ndk_isar` - `v0.2.3-dev.11`
 - `ndk_objectbox` - `v0.2.7-dev.13`
 - `ndk_rust_verifier` - `v0.4.2-dev.13`
 - `nip07_event_signer` - `v1.0.4-dev.11`
 - `sembast_cache_manager` - `v1.0.5-dev.11`

---

#### `ndk` - `v0.6.0-dev.8`

 - **FIX**: add test and call clean url during broadcast.


## 2025-11-05

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.6.0-dev.7`](#ndk---v060-dev7)
 - [`ndk_amber` - `v0.3.3-dev.10`](#ndk_amber---v033-dev10)
 - [`ndk_isar` - `v0.2.3-dev.10`](#ndk_isar---v023-dev10)
 - [`ndk_objectbox` - `v0.2.7-dev.12`](#ndk_objectbox---v027-dev12)
 - [`ndk_rust_verifier` - `v0.4.2-dev.12`](#ndk_rust_verifier---v042-dev12)
 - [`nip07_event_signer` - `v1.0.4-dev.10`](#nip07_event_signer---v104-dev10)
 - [`sembast_cache_manager` - `v1.0.5-dev.10`](#sembast_cache_manager---v105-dev10)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.3.3-dev.10`
 - `ndk_isar` - `v0.2.3-dev.10`
 - `ndk_objectbox` - `v0.2.7-dev.12`
 - `ndk_rust_verifier` - `v0.4.2-dev.12`
 - `nip07_event_signer` - `v1.0.4-dev.10`
 - `sembast_cache_manager` - `v1.0.5-dev.10`

---

#### `ndk` - `v0.6.0-dev.7`

 - **FIX**: add test and call clean url during broadcast.


## 2025-11-03

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.6.0-dev.6`](#ndk---v060-dev6)
 - [`ndk_amber` - `v0.3.3-dev.9`](#ndk_amber---v033-dev9)
 - [`ndk_isar` - `v0.2.3-dev.9`](#ndk_isar---v023-dev9)
 - [`ndk_objectbox` - `v0.2.7-dev.11`](#ndk_objectbox---v027-dev11)
 - [`ndk_rust_verifier` - `v0.4.2-dev.11`](#ndk_rust_verifier---v042-dev11)
 - [`nip07_event_signer` - `v1.0.4-dev.9`](#nip07_event_signer---v104-dev9)
 - [`sembast_cache_manager` - `v1.0.5-dev.9`](#sembast_cache_manager---v105-dev9)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.3.3-dev.9`
 - `ndk_isar` - `v0.2.3-dev.9`
 - `ndk_objectbox` - `v0.2.7-dev.11`
 - `ndk_rust_verifier` - `v0.4.2-dev.11`
 - `nip07_event_signer` - `v1.0.4-dev.9`
 - `sembast_cache_manager` - `v1.0.5-dev.9`

---

#### `ndk` - `v0.6.0-dev.6`

 - **FIX**: static analysis issues.


## 2025-11-03

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.6.0-dev.5`](#ndk---v060-dev5)
 - [`ndk_amber` - `v0.3.3-dev.8`](#ndk_amber---v033-dev8)
 - [`ndk_isar` - `v0.2.3-dev.8`](#ndk_isar---v023-dev8)
 - [`ndk_objectbox` - `v0.2.7-dev.10`](#ndk_objectbox---v027-dev10)
 - [`ndk_rust_verifier` - `v0.4.2-dev.10`](#ndk_rust_verifier---v042-dev10)
 - [`nip07_event_signer` - `v1.0.4-dev.8`](#nip07_event_signer---v104-dev8)
 - [`sembast_cache_manager` - `v1.0.5-dev.8`](#sembast_cache_manager---v105-dev8)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.3.3-dev.8`
 - `ndk_isar` - `v0.2.3-dev.8`
 - `ndk_objectbox` - `v0.2.7-dev.10`
 - `ndk_rust_verifier` - `v0.4.2-dev.10`
 - `nip07_event_signer` - `v1.0.4-dev.8`
 - `sembast_cache_manager` - `v1.0.5-dev.8`

---

#### `ndk` - `v0.6.0-dev.5`

 - **FIX**: static analysis issues.


## 2025-10-29

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.6.0-dev.4`](#ndk---v060-dev4)
 - [`ndk_isar` - `v0.2.3-dev.7`](#ndk_isar---v023-dev7)
 - [`ndk_amber` - `v0.3.3-dev.7`](#ndk_amber---v033-dev7)
 - [`ndk_objectbox` - `v0.2.7-dev.9`](#ndk_objectbox---v027-dev9)
 - [`ndk_rust_verifier` - `v0.4.2-dev.9`](#ndk_rust_verifier---v042-dev9)
 - [`nip07_event_signer` - `v1.0.4-dev.7`](#nip07_event_signer---v104-dev7)
 - [`sembast_cache_manager` - `v1.0.5-dev.7`](#sembast_cache_manager---v105-dev7)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.3.3-dev.7`
 - `ndk_objectbox` - `v0.2.7-dev.9`
 - `ndk_rust_verifier` - `v0.4.2-dev.9`
 - `nip07_event_signer` - `v1.0.4-dev.7`
 - `sembast_cache_manager` - `v1.0.5-dev.7`

---

#### `ndk` - `v0.6.0-dev.4`

 - **FEAT**: log color, params.

#### `ndk_isar` - `v0.2.3-dev.7`

 - **FEAT**: log color, params.


## 2025-10-29

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.6.0-dev.3`](#ndk---v060-dev3)
 - [`ndk_isar` - `v0.2.3-dev.6`](#ndk_isar---v023-dev6)
 - [`ndk_amber` - `v0.3.3-dev.6`](#ndk_amber---v033-dev6)
 - [`ndk_objectbox` - `v0.2.7-dev.8`](#ndk_objectbox---v027-dev8)
 - [`ndk_rust_verifier` - `v0.4.2-dev.8`](#ndk_rust_verifier---v042-dev8)
 - [`nip07_event_signer` - `v1.0.4-dev.6`](#nip07_event_signer---v104-dev6)
 - [`sembast_cache_manager` - `v1.0.5-dev.6`](#sembast_cache_manager---v105-dev6)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.3.3-dev.6`
 - `ndk_objectbox` - `v0.2.7-dev.8`
 - `ndk_rust_verifier` - `v0.4.2-dev.8`
 - `nip07_event_signer` - `v1.0.4-dev.6`
 - `sembast_cache_manager` - `v1.0.5-dev.6`

---

#### `ndk` - `v0.6.0-dev.3`

 - **FEAT**: log color, params.

#### `ndk_isar` - `v0.2.3-dev.6`

 - **FEAT**: log color, params.


## 2025-10-28

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.6.0-dev.2`](#ndk---v060-dev2)
 - [`ndk_amber` - `v0.3.3-dev.5`](#ndk_amber---v033-dev5)
 - [`ndk_isar` - `v0.2.3-dev.5`](#ndk_isar---v023-dev5)
 - [`ndk_objectbox` - `v0.2.7-dev.7`](#ndk_objectbox---v027-dev7)
 - [`ndk_rust_verifier` - `v0.4.2-dev.7`](#ndk_rust_verifier---v042-dev7)
 - [`nip07_event_signer` - `v1.0.4-dev.5`](#nip07_event_signer---v104-dev5)
 - [`sembast_cache_manager` - `v1.0.5-dev.5`](#sembast_cache_manager---v105-dev5)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.3.3-dev.5`
 - `ndk_isar` - `v0.2.3-dev.5`
 - `ndk_objectbox` - `v0.2.7-dev.7`
 - `ndk_rust_verifier` - `v0.4.2-dev.7`
 - `nip07_event_signer` - `v1.0.4-dev.5`
 - `sembast_cache_manager` - `v1.0.5-dev.5`

---

#### `ndk` - `v0.6.0-dev.2`

 - **REFACTOR**: concurrent streams with rxdart.
 - **FIX**: improved null filter.
 - **FIX**: drop invalid events.


## 2025-10-28

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.6.0-dev.1`](#ndk---v060-dev1)
 - [`ndk_amber` - `v0.3.3-dev.4`](#ndk_amber---v033-dev4)
 - [`ndk_isar` - `v0.2.3-dev.4`](#ndk_isar---v023-dev4)
 - [`ndk_objectbox` - `v0.2.7-dev.6`](#ndk_objectbox---v027-dev6)
 - [`ndk_rust_verifier` - `v0.4.2-dev.6`](#ndk_rust_verifier---v042-dev6)
 - [`nip07_event_signer` - `v1.0.4-dev.4`](#nip07_event_signer---v104-dev4)
 - [`sembast_cache_manager` - `v1.0.5-dev.4`](#sembast_cache_manager---v105-dev4)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.3.3-dev.4`
 - `ndk_isar` - `v0.2.3-dev.4`
 - `ndk_objectbox` - `v0.2.7-dev.6`
 - `ndk_rust_verifier` - `v0.4.2-dev.6`
 - `nip07_event_signer` - `v1.0.4-dev.4`
 - `sembast_cache_manager` - `v1.0.5-dev.4`

---

#### `ndk` - `v0.6.0-dev.1`

 - **REFACTOR**: concurrent streams with rxdart.
 - **FIX**: improved null filter.
 - **FIX**: drop invalid events.


## 2025-10-22

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.6.0-dev.0`](#ndk---v060-dev0)
 - [`ndk_amber` - `v0.3.3-dev.3`](#ndk_amber---v033-dev3)
 - [`ndk_isar` - `v0.2.3-dev.3`](#ndk_isar---v023-dev3)
 - [`ndk_objectbox` - `v0.2.7-dev.5`](#ndk_objectbox---v027-dev5)
 - [`ndk_rust_verifier` - `v0.4.2-dev.5`](#ndk_rust_verifier---v042-dev5)
 - [`nip07_event_signer` - `v1.0.4-dev.3`](#nip07_event_signer---v104-dev3)
 - [`sembast_cache_manager` - `v1.0.5-dev.3`](#sembast_cache_manager---v105-dev3)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.3.3-dev.3`
 - `ndk_isar` - `v0.2.3-dev.3`
 - `ndk_objectbox` - `v0.2.7-dev.5`
 - `ndk_rust_verifier` - `v0.4.2-dev.5`
 - `nip07_event_signer` - `v1.0.4-dev.3`
 - `sembast_cache_manager` - `v1.0.5-dev.3`

---

#### `ndk` - `v0.6.0-dev.0`

 - Bump "ndk" to `0.6.0-dev.0`.

# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](https://conventionalcommits.org) for commit guidelines.

## 2025-10-22

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.5.2-dev.2`](#ndk---v052-dev2)
 - [`ndk_amber` - `v0.3.3-dev.2`](#ndk_amber---v033-dev2)
 - [`ndk_isar` - `v0.2.3-dev.2`](#ndk_isar---v023-dev2)
 - [`ndk_objectbox` - `v0.2.7-dev.4`](#ndk_objectbox---v027-dev4)
 - [`ndk_rust_verifier` - `v0.4.2-dev.4`](#ndk_rust_verifier---v042-dev4)
 - [`nip07_event_signer` - `v1.0.4-dev.2`](#nip07_event_signer---v104-dev2)
 - [`sembast_cache_manager` - `v1.0.5-dev.2`](#sembast_cache_manager---v105-dev2)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.3.3-dev.2`
 - `ndk_isar` - `v0.2.3-dev.2`
 - `ndk_objectbox` - `v0.2.7-dev.4`
 - `ndk_rust_verifier` - `v0.4.2-dev.4`
 - `nip07_event_signer` - `v1.0.4-dev.2`
 - `sembast_cache_manager` - `v1.0.5-dev.2`

---

#### `ndk` - `v0.5.2-dev.2`

 - **FIX**: buffer not clearing.
 - **FEAT**: concurrent event stream.


## 2025-10-22

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.5.2-dev.1`](#ndk---v052-dev1)
 - [`ndk_amber` - `v0.3.3-dev.1`](#ndk_amber---v033-dev1)
 - [`ndk_isar` - `v0.2.3-dev.1`](#ndk_isar---v023-dev1)
 - [`ndk_objectbox` - `v0.2.7-dev.3`](#ndk_objectbox---v027-dev3)
 - [`ndk_rust_verifier` - `v0.4.2-dev.3`](#ndk_rust_verifier---v042-dev3)
 - [`nip07_event_signer` - `v1.0.4-dev.1`](#nip07_event_signer---v104-dev1)
 - [`sembast_cache_manager` - `v1.0.5-dev.1`](#sembast_cache_manager---v105-dev1)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.3.3-dev.1`
 - `ndk_isar` - `v0.2.3-dev.1`
 - `ndk_objectbox` - `v0.2.7-dev.3`
 - `ndk_rust_verifier` - `v0.4.2-dev.3`
 - `nip07_event_signer` - `v1.0.4-dev.1`
 - `sembast_cache_manager` - `v1.0.5-dev.1`

---

#### `ndk` - `v0.5.2-dev.1`

 - **FIX**: buffer not clearing.
 - **FEAT**: concurrent event stream.


## 2025-10-22

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk_rust_verifier` - `v0.4.2-dev.2`](#ndk_rust_verifier---v042-dev2)
 - [`rust_lib_ndk` - `v0.1.7-dev.0+2`](#rust_lib_ndk---v017-dev02)

---

#### `ndk_rust_verifier` - `v0.4.2-dev.2`

 - **REFACTOR**: secp256k1 to rust native dep.
 - **FEAT**: rust verifier web assets.

#### `rust_lib_ndk` - `v0.1.7-dev.0+2`

 - **REFACTOR**: secp256k1 to rust native dep.


## 2025-10-22

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk_rust_verifier` - `v0.4.2-dev.1`](#ndk_rust_verifier---v042-dev1)
 - [`rust_lib_ndk` - `v0.1.7+1`](#rust_lib_ndk---v0171)

---

#### `ndk_rust_verifier` - `v0.4.2-dev.1`

 - **REFACTOR**: secp256k1 to rust native dep.
 - **FEAT**: rust verifier web assets.

#### `rust_lib_ndk` - `v0.1.7+1`

 - **REFACTOR**: secp256k1 to rust native dep.


## 2025-10-20

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk_objectbox` - `v0.2.7-dev.2`](#ndk_objectbox---v027-dev2)

---

#### `ndk_objectbox` - `v0.2.7-dev.2`

 - **FIX**: import cosmetics.


## 2025-10-20

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk_objectbox` - `v0.2.7-dev.1`](#ndk_objectbox---v027-dev1)

---

#### `ndk_objectbox` - `v0.2.7-dev.1`

 - **FIX**: import cosmetics.


## 2025-10-20

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`ndk` - `v0.5.2-dev.0+1`](#ndk---v052-dev01)
 - [`ndk_rust_verifier` - `v0.4.2-dev.0+1`](#ndk_rust_verifier---v042-dev01)
 - [`nip07_event_signer` - `v1.0.4-dev.0`](#nip07_event_signer---v104-dev0)
 - [`ndk_amber` - `v0.3.3-dev.0+1`](#ndk_amber---v033-dev01)
 - [`ndk_isar` - `v0.2.3-dev.0+1`](#ndk_isar---v023-dev01)
 - [`ndk_objectbox` - `v0.2.7-dev.0+1`](#ndk_objectbox---v027-dev01)
 - [`sembast_cache_manager` - `v1.0.5-dev.0`](#sembast_cache_manager---v105-dev0)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `ndk_amber` - `v0.3.3-dev.0+1`
 - `ndk_isar` - `v0.2.3-dev.0+1`
 - `ndk_objectbox` - `v0.2.7-dev.0+1`
 - `sembast_cache_manager` - `v1.0.5-dev.0`

---

#### `ndk` - `v0.5.2-dev.0+1`

 - **FIX**: call dispose on destroy.
 - **FIX**: BehaviorSubject for immediate values.
 - **FIX**: copy value to fix modification.

#### `ndk_rust_verifier` - `v0.4.2-dev.0+1`

 - **FIX**: flutter_rust_bridge no strict version.

#### `nip07_event_signer` - `v1.0.4-dev.0`

 - **DOCS**: mention web signer.

# Change Log

## 2025-07-02

### Changes

---

Packages with breaking changes:

- There are no breaking changes in this release.

Packages with other changes:

#### `ndk` - `v0.5.0`

- **FEAT**: NIP07 web signer support.
- **FEAT**: sembast cache manager (+web support).

#### `ndk` - `v0.4.2`

- **REFACTOR**: remove RELAY_SET kind from constructor.
- **FIX**: on done for replay subject.
- **FIX**: register before connect, unregister.
- **FIX**: missing default case.
- **FIX**: missing await.
- **FIX**: tests port collision.
- **FIX**: force reconnect.
- **FIX**: loadMetadatas cached.
- **FIX**: use ephemeralSigner.
- **FIX**: blossom nip94 parsing List<String>?
- **FIX**: dimensions.
- **FIX**: handle null notifications list in GetInfoResponse.
- **FIX**: jit use bootstrapRelays if no data.
- **FIX**: const for reports.
- **FIX**: pass mediaOptimisation param.
- **FIX**: dont expose signer.
- **FIX**: throw Exception.
- **FIX**: json parsing.
- **FIX**: blossom spec put.
- **FIX**: mirror uploads.
- **FIX**: flanky test to overused ports.
- **FIX**: cache stream not closing.
- **FEAT**: explicit relay requests.
- **FEAT**: tlv decode nip19.
- **FEAT**: stream relayConnectivityChanges.
- **FEAT**: add a tag to zaps.
- **FEAT**: files checkUrl.
- **FEAT**: publishUserServerList.
- **DOCS**: blossom entities inline.
- **DOCS**: better relay manager description.


## 2024-11-29

### Changes

---

Packages with breaking changes:

- There are no breaking changes in this release.

Packages with other changes:

- [`ndk` - `v0.2.0-dev001`](#ndk---v020-dev001)
- [`ndk_amber` - `v0.2.0-dev001`](#ndk_amber---v020-dev001)
- [`ndk_objectbox` - `v0.2.0-dev001`](#ndk_objectbox---v020-dev001)
- [`ndk_rust_verifier` - `v0.2.0-dev001`](#ndk_rust_verifier---v020-dev001)

---

#### `ndk` - `v0.2.0-dev001`

- Bump "ndk" to `0.2.0-dev001`.

#### `ndk_amber` - `v0.2.0-dev001`

- Bump "ndk_amber" to `0.2.0-dev001`.

#### `ndk_objectbox` - `v0.2.0-dev001`

- Bump "ndk_objectbox" to `0.2.0-dev001`.

#### `ndk_rust_verifier` - `v0.2.0-dev001`

- Bump "ndk_rust_verifier" to `0.2.0-dev001`.

## 2024-11-29

### Changes

---

Packages with breaking changes:

- There are no breaking changes in this release.

Packages with other changes:

- [`ndk` - `v0.2.0-dev001`](#ndk---v020-dev001)
- [`ndk_amber` - `v0.2.0-dev001`](#ndk_amber---v020-dev001)
- [`ndk_objectbox` - `v0.2.0-dev001`](#ndk_objectbox---v020-dev001)
- [`ndk_rust_verifier` - `v0.2.0-dev001`](#ndk_rust_verifier---v020-dev001)

---

#### `ndk` - `v0.2.0-dev001`

- Bump "ndk" to `0.2.0-dev001`.

#### `ndk_amber` - `v0.2.0-dev001`

- Bump "ndk_amber" to `0.2.0-dev001`.

#### `ndk_objectbox` - `v0.2.0-dev001`

- Bump "ndk_objectbox" to `0.2.0-dev001`.

#### `ndk_rust_verifier` - `v0.2.0-dev001`

- Bump "ndk_rust_verifier" to `0.2.0-dev001`.

## 2024-11-29

### Changes

---

Packages with breaking changes:

- There are no breaking changes in this release.

Packages with other changes:

- [`ndk` - `v0.2.0-dev001`](#ndk---v020-dev001)
- [`ndk_amber` - `v0.2.0-dev001`](#ndk_amber---v020-dev001)
- [`ndk_objectbox` - `v0.2.0-dev001`](#ndk_objectbox---v020-dev001)
- [`ndk_rust_verifier` - `v0.2.0-dev001`](#ndk_rust_verifier---v020-dev001)

---

#### `ndk` - `v0.2.0-dev001`

- Bump "ndk" to `0.2.0-dev001`.

#### `ndk_amber` - `v0.2.0-dev001`

- Bump "ndk_amber" to `0.2.0-dev001`.

#### `ndk_objectbox` - `v0.2.0-dev001`

- Bump "ndk_objectbox" to `0.2.0-dev001`.

#### `ndk_rust_verifier` - `v0.2.0-dev001`

- Bump "ndk_rust_verifier" to `0.2.0-dev001`.
