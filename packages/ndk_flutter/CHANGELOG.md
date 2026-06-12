## 0.8.4-dev.4

 - **FIX**: ecash wallet adding navigation bug.
 - **FEAT**: use StringColor for avatar and banner colors.
 - **FEAT**: add StringColor deterministic color utility.

## 0.8.4-dev.3

 - **FEAT**: add Portuguese and Brazilian Portuguese translations.
 - **FEAT**: add localization configuration for Flutter.
 - **FEAT**: add Finnish (fi) and Portuguese (pt) locales.

## 0.8.4-dev.2

 - Update a dependency to the latest release.

## 0.8.4-dev.1

 - **FIX**(ndk_flutter): prevent QR code overflow in nostr connect dialog.

## 0.8.4-dev.0

 - **REFACTOR**: rename ConcurrencyLimitedSignerMixin to ConcurrencyLimiterMixin.
 - **FIX**: skip remote call when a queued request is cancelled.
 - **FEAT**: implement ConcurrencyLimitedSignerMixin for managing concurrent requests in signers.

## 0.8.3

 - **FIX**: support WebEventSigner in saveAccountsState on web.
 - **REFACTOR**: remove unnecessary comments in saveAccountsState method.

## 0.8.2-dev.0+1

 - **REFACTOR**: remove unnecessary comments in saveAccountsState method.
 - **FIX**: support WebEventSigner in saveAccountsState on web.

## 0.8.2

 - Graduate package to a stable release. See pre-releases prior to this version for changelog entries.

## 0.8.2-dev.9

 - **REFACTOR**: merge ndk_event_signer_web and web_event_signer_web.
 - **REFACTOR**(signers,verifiers): rename to NdkEventSigner/Verifier and add factory.
 - **REFACTOR**(signers): rename platform stub to native and clarify conditional export.
 - **FIX**: use constant-time MAC comparison in NIP-44.
 - **FIX**(web): fix WebEventSigner stub and JS crypto, add tests.
 - **FIX**: update code doc, remove implementation.
 - **FIX**: delete transactions.
 - **FEAT**: add PlatformEventSigner for automatic platform selection.
 - **FEAT**: add web crypto benchmark.
 - **FEAT**: add WebEventSigner for fast web crypto.

## 0.8.2-dev.8

 - **REFACTOR**: PlatformEventVerifier via conditional imports.
 - **FIX**: use factory signer.
 - **FEAT**(ndk_flutter): add PlatformEventVerifier.
 - **FEAT**: implement NipAvatar utility to standardize initial generation and color selection for profiles and banners.

## 0.8.2-dev.7

 - **REFACTOR**: PlatformEventVerifier via conditional imports.
 - **FIX**: use factory signer.
 - **FEAT**(ndk_flutter): add PlatformEventVerifier.
 - **FEAT**: implement NipAvatar utility to standardize initial generation and color selection for profiles and banners.

## 0.8.2-dev.6

 - Update a dependency to the latest release.

## 0.8.2-dev.5

 - Update a dependency to the latest release.

## 0.8.2-dev.4

 - Update a dependency to the latest release.

## 0.8.2-dev.3

 - **FIX**: validate nsec/npub prefix before decoding. ([ac682700](https://github.com/relaystr/ndk/commit/ac682700b92023de6da0c5e15c248145b13a82db))

## 0.8.2-dev.2

 - **FIX**: validate nsec/npub prefix before decoding. ([ac682700](https://github.com/relaystr/ndk/commit/ac682700b92023de6da0c5e15c248145b13a82db))

## 0.8.2-dev.1

 - **FIX**: formaty intl balance and budget. ([eb394361](https://github.com/relaystr/ndk/commit/eb394361a398e944ea2ff14ec5f0c7ae6128bc1a))
 - **FIX**: withCachedPermissions copy rest of fields. ([4a083f6f](https://github.com/relaystr/ndk/commit/4a083f6f3a8cbaa636158c44658d5bb769224019))
 - **FIX**: not showing balance after alby go connect. ([7b2c37e5](https://github.com/relaystr/ndk/commit/7b2c37e5575e851cf8e53824d62e2081d8e73845))
 - **FIX**: not showing balance after alby go connect. ([74b7c456](https://github.com/relaystr/ndk/commit/74b7c456c198e5d5a8622cccc850c871ac10877c))
 - **FIX**: keep default walletAuth. ([db518547](https://github.com/relaystr/ndk/commit/db518547f7dbbae9359389f1aa4d7f798dc86416))
 - **FEAT**: alby go alternative connect method nostrnwc. ([0e21d30b](https://github.com/relaystr/ndk/commit/0e21d30b7bcb1617fb831816e4124fcb491b8a6e))

## 0.8.1-dev.0+1

 - Update a dependency to the latest release.

## 0.8.1

 - **FIX**: move amber into ndk_flutter. ([c70df0ec](https://github.com/relaystr/ndk/commit/c70df0ec27d4638697f478dcd1ed3048166145f2))

## 0.1.0-dev.2

 - **FIX**: better wallet type choosing dialog. ([75eefe1d](https://github.com/relaystr/ndk/commit/75eefe1da7d36263ed1988bd1a65c1a946a4c850))
 - **FIX**: separate wallets storage operations from cache manager. ([92bb9a22](https://github.com/relaystr/ndk/commit/92bb9a22d6a0f22169ced6741ddf9aaa77db00b5))
 - **FIX**: conditional web import to support wasm. ([33b3ccdd](https://github.com/relaystr/ndk/commit/33b3ccddd2e4bdd61bb45dee1741767b294f759d))
 - **FIX**: wasm compatible conditional import. ([f5810f31](https://github.com/relaystr/ndk/commit/f5810f3108b792cece307574c19914d2cac0753f))

## 0.0.2-dev.8

 - **FIX**: better wallet type choosing dialog.
 - **FIX**: separate wallets storage operations from cache manager.
 - **FIX**: conditional web import to support wasm.
 - **FIX**: wasm compatible conditional import.
 - **FIX**: include generated localization files for pub.dev publishing.
 - **FIX**: unify chips.
 - **FEAT**: missing translations.
 - **FEAT**: pending requests widget.

## 0.0.2-dev.7

 - **FIX**: better wallet type choosing dialog.
 - **FIX**: separate wallets storage operations from cache manager.
 - **FIX**: conditional web import to support wasm.
 - **FIX**: wasm compatible conditional import.
 - **FIX**: include generated localization files for pub.dev publishing.
 - **FIX**: unify chips.
 - **FEAT**: missing translations.
 - **FEAT**: pending requests widget.

## 0.0.2-dev.6

 - **FIX**: better wallet type choosing dialog.
 - **FIX**: separate wallets storage operations from cache manager.
 - **FIX**: conditional web import to support wasm.
 - **FIX**: wasm compatible conditional import.
 - **FIX**: include generated localization files for pub.dev publishing.
 - **FIX**: unify chips.
 - **FEAT**: missing translations.
 - **FEAT**: pending requests widget.

## 0.0.2-dev.5

 - **FIX**: conditional web import to support wasm.
 - **FIX**: wasm compatible conditional import.
 - **FIX**: include generated localization files for pub.dev publishing.
 - **FIX**: unify chips.
 - **FEAT**: missing translations.
 - **FEAT**: pending requests widget.

## 0.0.2-dev.4

 - **FIX**: conditional web import to support wasm.
 - **FIX**: wasm compatible conditional import.
 - **FIX**: include generated localization files for pub.dev publishing.
 - **FIX**: unify chips.
 - **FIX**(ndk_flutter): suppress experimental_member_use warning.
 - **FIX**(ndk_flutter): pass cachedPublicKey to signers during session restore.
 - **FEAT**: missing translations.
 - **FEAT**: pending requests widget.

## 0.0.2-dev.3

 - **FIX**: conditional web import to support wasm.
 - **FIX**: wasm compatible conditional import.
 - **FIX**: include generated localization files for pub.dev publishing.
 - **FIX**: unify chips.
 - **FIX**(ndk_flutter): suppress experimental_member_use warning.
 - **FIX**(ndk_flutter): pass cachedPublicKey to signers during session restore.
 - **FEAT**: missing translations.
 - **FEAT**: pending requests widget.

## 0.0.2-dev.2

 - **FIX**: conditional web import to support wasm.
 - **FIX**: wasm compatible conditional import.
 - **FIX**: include generated localization files for pub.dev publishing.
 - **FIX**: unify chips.
 - **FIX**(ndk_flutter): suppress experimental_member_use warning.
 - **FIX**(ndk_flutter): pass cachedPublicKey to signers during session restore.
 - **FEAT**: missing translations.
 - **FEAT**: pending requests widget.

## 0.0.2-dev.1

 - **FIX**: conditional web import to support wasm.

## 0.0.2-dev.0+1

 - Update a dependency to the latest release.

## 0.0.2

 - Graduate package to a stable release. See pre-releases prior to this version for changelog entries.

## 0.0.2-dev.16

 - Update a dependency to the latest release.

## 0.0.2-dev.15

 - **FIX**: wasm compatible conditional import.

## 0.0.2-dev.14

 - **FIX**: wasm compatible conditional import.

## 0.0.2-dev.13

 - Update a dependency to the latest release.

## 0.0.2-dev.12

 - Update a dependency to the latest release.

## 0.0.2-dev.11

 - Update a dependency to the latest release.

## 0.0.2-dev.10

 - Update a dependency to the latest release.

## 0.0.2-dev.9

 - Update a dependency to the latest release.

## 0.0.2-dev.8

 - **FIX**: include generated localization files for pub.dev publishing.
 - **FIX**: unify chips.
 - **FEAT**: missing translations.
 - **FEAT**: pending requests widget.

## 0.0.2-dev.7

 - Update a dependency to the latest release.

## 0.0.2-dev.6

 - Update a dependency to the latest release.

## 0.0.2-dev.5

 - Update a dependency to the latest release.

## 0.0.2-dev.4

 - **FIX**(ndk_flutter): suppress experimental_member_use warning.
 - **FIX**(ndk_flutter): pass cachedPublicKey to signers during session restore.

## 0.0.2-dev.3

 - Update a dependency to the latest release.

## 0.0.2-dev.2

 - Update a dependency to the latest release.

## 0.0.2-dev.1

 - Update a dependency to the latest release.

## 0.0.2-dev.0

 - **REFACTOR**: migrate widgets to use NdkFlutter instead of Ndk.
 - **REFACTOR**: centralize npub formatting in NdkFlutter.
 - **FIX**: add intl dependency.
 - **FIX**: remove defensive empty pubkey check in getColorFromPubkey.
 - **FIX**: remove nip19 package.
 - **FEAT**: add widgets demo page for ndk_flutter in sample-app.
 - **FEAT**: add web verifier.

## 0.0.1

- basic widgets and methods
