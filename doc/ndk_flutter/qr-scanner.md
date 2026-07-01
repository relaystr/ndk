---
label: QR scanner
icon: device-camera
order: 90
---

# QR scanner

Some `ndk_flutter` widgets can read a value from a QR code. For example, the wallet widgets
let the user scan an NWC connection URI (`nostr+walletconnect://...`) instead of typing it.

`ndk_flutter` does **not** bundle a camera/scanner dependency. Instead you provide your own
scanner, so you stay in control of the camera plugin, runtime permissions, and the UI. When you
don't provide one, the scan button is hidden and users can still paste a value manually.

## Provide a scanner

A scanner is a callback that opens your scanning UI and returns the scanned string, or `null`
if the user cancels:

```dart
typedef NwcUriScanner = Future<String?> Function(BuildContext context);
```

Pass it to the widget (or dialog) that needs it. For wallets, that's `NWallets`:

:::code source="../../packages/sample-app/lib/wallets.dart" language="dart" range="72-76" title="wire a scanner into NWallets" :::

The same `nwcUriScanner:` parameter is accepted by the standalone add-wallet dialogs:

```dart
showAddNwcWalletDialog(context, ndkFlutter, nwcUriScanner: scanNwcUri);
showNwcConnectionOptionsDialog(context, ndkFlutter, nwcUriScanner: scanNwcUri);
```

The widgets validate the scanned value (e.g. that an NWC URI starts with
`nostr+walletconnect://`) and show an error for anything else, so your callback only needs to
return the raw scanned string.

## Example: scanning with mobile_scanner

The sample app implements the callback with
[`mobile_scanner`](https://pub.dev/packages/mobile_scanner). Add it to **your** app (not to
`ndk_flutter`):

```bash
flutter pub add mobile_scanner
```

The callback just opens a dialog that wraps the camera view and pops the first decoded value:

:::code source="../../packages/sample-app/lib/nwc_qr_scanner.dart" language="dart" range="8-13" title="scanNwcUri callback" :::

The full dialog lives in
[`packages/sample-app/lib/nwc_qr_scanner.dart`](https://github.com/relaystr/ndk/blob/master/packages/sample-app/lib/nwc_qr_scanner.dart).
It adds a camera preview, a paste fallback, error handling, and a desktop/web-safe layout.
