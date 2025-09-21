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

By default, the logged user is used for user widgets, you can overwrite it by providing a pubkey as parameter.

```dart
import 'package:nostr_widgets/nostr_widgets.dart';

// available widgets
NBanner(ndk);
NPicture(ndk);
NName(ndk);
NUserProfile(ndk);
NLogin(ndk);
NSwitchAccount(ndk);

final ndkFlutter = NdkFlutter(ndk: ndk)

// call this to connect user from local storage
ndkFlutter.restoreAccountsState();

// call this every time the auth state change
ndkFlutter.saveAccountsState();
```

## TODO

- [ ] NUserProfile optionnal show nsec and copy
- [ ] NUserProfile show the letter in the Picture and make it as big as possible

## Need more Widgets

Open an Issue
