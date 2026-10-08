# Setup

## Install

```bash
flutter pub add ndk
flutter pub add ndk_flutter
```

## Internationalization (required)

Follow [Flutter i18n docs](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization), then:

```dart
import 'package:ndk_flutter/l10n/app_localizations.dart' as ndk_flutter;

MaterialApp(
  localizationsDelegates: [
    ndk_flutter.AppLocalizations.delegate, // add this
  ],
);
```

## NdkFlutter init

```dart
import 'package:ndk_flutter/ndk_flutter.dart';

final ndkFlutter = NdkFlutter(ndk: ndk);

// Constructor options (all optional except ndk):
// npubSeparator: '…'   — separator between prefix and suffix
// npubPrefixLength: 10 — chars shown at start of npub
// npubSuffixLength: 4  — chars shown at end of npub
```

## Typical app startup

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final ndk = Ndk(/* your config */);
  final ndkFlutter = NdkFlutter(ndk: ndk);

  // Restore saved accounts before UI renders
  await ndkFlutter.restoreAccountsState();

  runApp(MyApp(ndk: ndk, ndkFlutter: ndkFlutter));
}
```

## Package exports

```dart
// Main entry point — re-exports everything:
import 'package:ndk_flutter/ndk_flutter.dart';

// Includes:
// NdkFlutter class, widgets, signers, verifiers, utils, AmberFlutter
```
