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
