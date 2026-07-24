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

## TODO

- [ ] NUserProfile optionnal show nsec and copy
- [ ] NUserProfile show the letter in the Picture and make it as big as possible

## Need more Widgets

Open an Issue
