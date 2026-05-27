# Account State Management

## Save / Restore

Persists accounts to `FlutterSecureStorage`. Call on auth state change and app start.

```dart
// Call before runApp — reads storage, adds signers to ndk
await ndkFlutter.restoreAccountsState();

// Call after every login/logout/account switch
await ndkFlutter.saveAccountsState();
```

## Supported account kinds

| Kind | `AccountKinds` value | Signer class | Notes |
| ---- | -------------------- | ------------ | ----- |
| Private key | `privkey` | internal factory | nsec stored encrypted |
| Public key (read-only) | `pubkey` | internal factory | no signing |
| NIP-07 browser ext | `nip07` | `Nip07EventSigner` | web only |
| Amber (Android) | `amber` | `AmberEventSigner` | Android only |
| NIP-46 bunker | `bunker` | `Nip46EventSigner` | remote signer |

## Available signers

```dart
import 'package:ndk_flutter/ndk_flutter.dart';

// NIP-07 (browser extension — web)
final signer = Nip07EventSigner(cachedPublicKey: pubkey);

// Amber (Android external signer)
final amber = Amberflutter();
final ds = AmberFlutterDS(amber);
final signer = AmberEventSigner(publicKey: pubkey, amberFlutterDS: ds);

// NIP-46 bunker
final signer = Nip46EventSigner(
  connection: BunkerConnection.fromJson(jsonDecode(connectionJson)),
  requests: ndk.requests,
  broadcast: ndk.broadcast,
  eventSignerFactory: ndk.config.eventSignerFactory,
  cachedPublicKey: pubkey,
);
```

## Add account manually

```dart
ndk.accounts.addAccount(
  pubkey: pubkey,
  type: AccountType.externalSigner, // or .privateKey / .publicKey
  signer: signer,
);

// Switch active account
ndk.accounts.switchAccount(pubkey: pubkey);
```

## Utility methods on NdkFlutter

```dart
// Format npub for display (truncated)
final display = ndkFlutter.formatNpub(pubkey);
// → "npub1abcde1234…5678"

// Deterministic color from pubkey (for avatars)
final color = NdkFlutter.getColorFromPubkey(pubkey);

// Resolve NIP-05 identifier
final result = await NdkFlutter.fetchNip05('user@domain.com');
if (result.pubkey != null) { /* verified */ }
```
