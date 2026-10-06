This package helps you to easily produce Nostr apps by providing generics Widgets and functions.

## Features

- Nostr widgets
- Login persistence

## Getting started

### Add dependencies

```bash
flutter pub add ndk
flutter pub add ndk_flutter
```

### Add internationalization

Follow the [Official documentation](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization)

```dart
import 'package:ndk_flutter/l10n/app_localizations.dart' as ndk_flutter;

MaterialApp(
    localizationsDelegates: [
        ndk_flutter.AppLocalizations.delegate, // add this line
    ],
);
```

## Usage

```dart
import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

// wrap your Ndk instance
final ndkFlutter = NdkFlutter(ndk: ndk);

// reads saved accounts from secure storage and registers their signers in ndk
// typically called before runApp
await ndkFlutter.restoreAccountsState();

// call this every time the auth state changes
await ndkFlutter.saveAccountsState();

// available widgets (take ndkFlutter, not ndk)
NBanner(ndkFlutter: ndkFlutter);
NPicture(ndkFlutter: ndkFlutter);
NName(ndkFlutter: ndkFlutter);
NUserProfile(ndkFlutter: ndkFlutter);
NLogin(ndkFlutter: ndkFlutter);
NSwitchAccount(ndkFlutter: ndkFlutter);
```

By default, the logged-in user is used for user widgets; you can override it by passing a `pubkey` parameter.

### Android app updates

See the complete [software update guide](../../doc/usecases/software.md) for
NIP-82 publishing requirements, controller setup, widgets, and installer
validation.

Apps using `AndroidPackageInstaller` must opt into APK installation in their
application manifest:

```xml
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />
```

This restricted permission is not added automatically by `ndk_flutter`. Only
declare it when installing updates is a core app feature and applicable store
policies permit that use.

## TODO

- [ ] NUserProfile optionnal show nsec and copy
- [ ] NUserProfile show the letter in the Picture and make it as big as possible

## Need more Widgets

Open an Issue


## Shared wallet input UI

`NWallets` includes the wallet chooser, paste/manual input, Cashu discovery,
LNbits setup, connection status/retry screens, and Alby Cloud/Coinos connection
presets. The presets reuse `albyGoConnectConfig` for the host app name and
callback URL. Register that callback scheme in your app and forward incoming
URLs to `NWalletsState.onProtocolUrlReceived`; on mobile resume without a
callback, call `resumePendingWalletAuth`. Legacy untagged providers are
revalidated every five seconds while their connection screen remains open.

Only camera decoding is supplied by the host, so ndk_flutter does not depend on
a camera plugin, WebRTC, or a native QR decoder:

```dart
NWallets(
  ndkFlutter: ndkFlutter,
  albyGoConnectConfig: const AlbyGoConnectConfig(
    appName: 'My app',
    appIconUrl: 'https://example.com/icon.png',
    callback: 'myapp://nwc',
  ),
  walletQrScannerBuilder: (context, onScan, onError) =>
      MyQrCamera(onScan: onScan, onError: onError),
)
```

`MyQrCamera` is your camera widget. Report decoded text through `onScan`,
report failures through `onError`, and release camera resources on disposal.
The shared UI removes the camera during nested input dialogs and connection
status, then recreates it when scanning resumes. The same builder is used for
nested NWC and LNbits QR input. Pass null on platforms without camera support;
paste and wallet setup still work.

No provider list is needed. Set `nwcConnectionOptions` to replace the defaults,
or pass an empty list to disable web presets. `defaultNwcConnectionOptions`
is also available when extending the list. Existing `walletInputScanner`,
`nwcUriScanner` and `bolt12InputScanner` overrides remain supported.
`showWalletInputDialog` exposes the shared UI separately from `NWallets`.
