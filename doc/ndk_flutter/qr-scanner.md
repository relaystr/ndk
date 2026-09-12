---
label: QR scanner
icon: device-camera
order: 90
---

# QR scanner

The add-wallet flow accepts NWC connection URIs, Lightning and BIP353 addresses, BOLT12
offers, BIP321 URIs, and HTTPS Cashu mint URLs from one QR scanner.

`ndk_flutter` does **not** bundle a camera/scanner dependency. Instead you provide your own
scanner, so you stay in control of the camera plugin, runtime permissions, and the UI. When you
don't provide one, the scan button is hidden and users can still paste a value manually.
On Android and iOS the scanner opens when the user enters the add-wallet flow. Set
`openScannerOnAdd: false` to start on the unified choices screen instead. Your scanner remains
responsible for camera-permission rationale and denial handling.

## Provide a scanner

A scanner is a callback that opens your scanning UI and returns a scanned value, a launched
wallet connection, or `null` if the user cancels:

```dart
typedef WalletInputScanner = Future<WalletInputScanResult?> Function(
  BuildContext context,
  WalletInputScannerConfiguration configuration,
);
```

Pass it to the widget (or dialog) that needs it. For wallets, that's `NWallets`:

:::code source="../../packages/sample-app/lib/wallets.dart" language="dart" range="72-76" title="wire a scanner into NWallets" :::

Pass the scanner to the unified dialog directly when you do not use `NWallets`:

```dart
showAddWalletTypeDialog(
  context,
  ndkFlutter,
  walletInputScanner: scanWalletInput,
);
```

Show `configuration.supportedInputDescription` in the scanner so users know which QR codes
work. Render `configuration.connectionOptions` beside camera and paste controls to expose the
standard installed-wallet chooser, Alby Go, custom providers, and web-wallet integrations
directly from the scanner. Listen to `configuration.connectionState` while an external flow is
active. Keep the scanner open through `awaitingReturn`, `connecting`, and `failed`; use
`retryPendingConnection` and `cancelPendingConnection` for retry and back actions. Return
`WalletInputScanResult.connectionStarted()` after the state reaches `connected`.

The widget classifies and validates scanned values. Your callback returns
Return scanned values as `WalletInputScanResult.value(rawText)`. For pasted or
typed values, pass `manuallyEntered: true` so confirmation allows editing.
Legacy `nwcUriScanner` and `bolt12InputScanner` callbacks remain available on their
type-specific dialogs.

## Wallet-assisted NWC connections

On Android and iOS, the unified flow includes the standard NWC wallet chooser and Alby Go.
Add installed or web wallet integrations with `nwcConnectionOptions`:

```dart
NWallets(
  ndkFlutter: ndkFlutter,
  walletInputScanner: scanWalletInput,
  nwcConnectionOptions: [
    NwcConnectionOption(
      label: 'My web wallet',
      subtitle: 'Approve the connection in your browser',
      connect: (context, ndkFlutter, coordinator) {
        const callback = 'myapp://nwc';
        return coordinator.connectWithUri(
          context,
          launchUri: Uri.parse(
            'https://wallet.example/connect?callback=myapp%3A%2F%2Fnwc',
          ),
          callback: callback,
          walletName: 'My web wallet',
        );
      },
    ),
  ],
)
```

Client-key web wallets can receive configurable app metadata and a freshly generated public
key. Complete pending authorization when the host app resumes:

```dart
NwcConnectionOption(
  id: 'coinos',
  label: 'Coinos',
  connect: (context, ndkFlutter, coordinator) {
    return coordinator.connectWebWalletAuth(
      context,
      authorizationEndpoint: Uri.parse('https://coinos.io/apps/new'),
      appName: 'My app',
      discoveryRelay: 'wss://relay.coinos.io',
      callback: 'myapp://nwc',
      walletName: 'Coinos',
      walletServicePubkey:
          'ba80990666ef0b6f4ba5059347beb13242921e54669e680064ca755256a1e3a6',
    );
  },
)
```

Call `NWalletsState.resumePendingWalletAuth()` from the app's resumed lifecycle callback.

Use the standard installed-wallet flow for any app that handles `nostr+walletauth://`:

```dart
return coordinator.connectWalletAuth(
  context,
  config: const AlbyGoConnectConfig(
    appName: 'My app',
    appIconUrl: 'https://example.com/icon.png',
    callback: 'myapp://nwc',
  ),
  walletName: 'NWC',
);
```

Forward callback URLs to `NWalletsState.onProtocolUrlReceived`. Provider authorization URLs
must return a `nostr+walletconnect://` value in a callback query parameter.

## Example: scanning with mobile_scanner

The sample app implements the callback with
[`mobile_scanner`](https://pub.dev/packages/mobile_scanner). Add it to **your** app (not to
`ndk_flutter`):

```bash
flutter pub add mobile_scanner
```

The callback just opens a dialog that wraps the camera view and pops the first decoded value:

:::code source="../../packages/sample-app/lib/nwc_qr_scanner.dart" language="dart" range="7-12" title="scanWalletInput callback" :::

The full dialog lives in
[`packages/sample-app/lib/nwc_qr_scanner.dart`](https://github.com/relaystr/ndk/blob/master/packages/sample-app/lib/nwc_qr_scanner.dart).
It adds a camera preview, paste and manual-entry fallbacks, wallet connection choices, error
handling, and a desktop/web-safe layout.
