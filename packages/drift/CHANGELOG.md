## 0.1.1-dev.3

 - Update a dependency to the latest release.

## 0.1.1-dev.2

 - Update a dependency to the latest release.

## 0.1.1-dev.1

 - Update a dependency to the latest release.

## 0.1.1-dev.0+1

 - Update a dependency to the latest release.

## 0.1.1

 - **FIX**: add back wallets methods and make it extend WalletsRepo. ([8e997d35](https://github.com/relaystr/ndk/commit/8e997d35e1aff3c7d9d0faa6a387e34a2d2ae12e))

## 0.0.2-dev.7

 - **FIX**: rename drift_cache_manager to ndk_drift. ([484faef2](https://github.com/relaystr/ndk/commit/484faef2e15beac36c654a44547e21e9cd4f2d08))

## 0.1.0-dev.1

 - **FIX**: rename drift_cache_manager to ndk_drift. ([484faef2](https://github.com/relaystr/ndk/commit/484faef2e15beac36c654a44547e21e9cd4f2d08))

## 0.0.2-dev.6

 - **REFACTOR**: rename rawContent to content.
 - **FIX**: use setter for known properties + content never null.
 - **FIX**: override ndk dependency.
 - **FEAT**: cashu remove mint info.
 - **FEAT**: update cache managers to support metadata tags and rawContent fields.

## 0.0.2-dev.5

 - **REFACTOR**: rename rawContent to content.
 - **FIX**: use setter for known properties + content never null.
 - **FIX**: override ndk dependency.
 - **FEAT**: cashu remove mint info.
 - **FEAT**: update cache managers to support metadata tags and rawContent fields.

## 0.0.2-dev.4

 - **REFACTOR**: rename rawContent to content.
 - **FIX**: use setter for known properties + content never null.
 - **FIX**: override ndk dependency.
 - **FEAT**: cashu remove mint info.
 - **FEAT**: update cache managers to support metadata tags and rawContent fields.

## 0.0.2-dev.3

 - **REFACTOR**: rename rawContent to content.
 - **FIX**: use setter for known properties + content never null.
 - **FIX**: override ndk dependency.
 - **FEAT**: update cache managers to support metadata tags and rawContent fields.

## 0.0.2-dev.2

 - **REFACTOR**: rename rawContent to content.
 - **FIX**: use setter for known properties + content never null.
 - **FIX**: override ndk dependency.
 - **FEAT**: update cache managers to support metadata tags and rawContent fields.

## 0.0.2-dev.0+1

 - Update a dependency to the latest release.

## 0.0.2

 - Graduate package to a stable release. See pre-releases prior to this version for changelog entries.

## 0.0.2-dev.6

 - **REFACTOR**: rename rawContent to content.
 - **FIX**: use setter for known properties + content never null.
 - **FIX**: override ndk dependency.
 - **FEAT**: update cache managers to support metadata tags and rawContent fields.

## 0.0.2-dev.5

 - Update a dependency to the latest release.

## 0.0.2-dev.4

 - Update a dependency to the latest release.

## 0.0.2-dev.3

 - Update a dependency to the latest release.

## 0.0.2-dev.2

 - Update a dependency to the latest release.

## 0.0.2-dev.1

 - Update a dependency to the latest release.

## 0.0.2-dev.0

 - **FEAT**: implement removeEvents and clearAll methods.
 - **FEAT**: use separate database names for debug and release modes.
 - **FEAT**: drift cache manager.
 - **FEAT**: create package.
 - **DOCS**: prepare drift_cache_manager for pub.dev publication.

## 0.0.1

* Initial release
* Implements NDK's CacheManager interface with Drift (SQLite)
* Cross-platform support: Android, iOS, macOS, Windows, Linux, Web
* Automatic debug/release database separation via kDebugMode
* Full support for all NDK entities: Events, Metadata, ContactList, UserRelayList, RelaySet, Nip05, FilterFetchedRangeRecord
