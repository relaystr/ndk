---
icon: person
---

[!badge variant="primary" text="high level"]

## Example

:::code source="../../packages/ndk/example/account_test.dart" language="dart" range="16-34" title="" :::

### External Signer (web)

:::code source="../../packages/ndk_flutter/example/nip07_event_signer_example.dart" language="dart"  title="" :::

### External Signer (nip-46 bunker)

Pass the same `Nip46ClientMetadata` to both flows. A `bunker://` URL does not identify your app, so this metadata is the only way for the remote signer to label the connection.

```dart client metadata
const clientMetadata = Nip46ClientMetadata(
    name: "My app",
    url: "https://myapp.example",
    perms: ["sign_event:1", "nip44_encrypt"],
);
```

```dart login with bunker url
final bunkerConnection = await ndk.accounts.loginWithBunkerUrl(
    bunkerUrl: "bunker://xxx",
    bunkers: ndk.bunkers,
    clientMetadata: clientMetadata,
    authCallback: (challenge) {},
);
```

```dart login with nostr connect
final nostrConnect = NostrConnect(
    relays: ["wss://relay.example.com"],
    clientMetadata: clientMetadata,
);
final bunkerConnection = await ndk.accounts.loginWithNostrConnect(
    nostrConnect: nostrConnect,
    bunkers: ndk.bunkers,
    authCallback: (challenge) {},
);
```

```dart login with bunker connection
final bunkerConnection = BunkerConnection(
    privateKey: "privateKey",
    remotePubkey: "remotePubkey",
    relays: ["wss://relay.example.com"]
);
await ndk.accounts.loginWithBunkerConnection(
    connection: bunkerConnection,
    bunkers: ndk.bunkers,
    authCallback: (challenge) {},
);
```

!!!warning Important
Store the `BunkerConnection` details locally to re-establish the connection in future sessions. Use `bunkerConnection.toJson()` to serialize and `BunkerConnection.fromJson()` to restore. Without storing these, users will need to re-authenticate each time.
!!!

NIP-46 lets the remote signer pick the relays. Call `switchRelays()` right after connecting, before other requests, and store the connection again when it returns relays.

```dart switch relays
final signer = ndk.accounts.getLoggedAccount()!.signer as Nip46EventSigner;
final relays = await signer.switchRelays();
if (relays != null) {
  // store signer.connection again
}
```

### Passkeys

`ndk_flutter` provides `PlatformPasskeyProvider` for WebAuthn PRF. The key formats below follow the [passkey-held keys proposal](https://github.com/nostr-protocol/nips/pull/2519), which is a draft, not an adopted NIP. No Nostr WoT service or account is required.

:::code source="../../packages/ndk_flutter/example/passkey_account_example.dart" language="dart" title="" :::

| Use case | API / format |
|---|---|
| New identity | `createPasskey`, tagged derived parameter `01` by default |
| LaWallet derivation | `createPasskey(parameterSet: 2)`, tagged derived parameter `02` |
| Keep an existing identity | `createStoredPasskey`, encrypted type `01` key record |
| Recover a tagged credential | `loginWithPasskey`; stored keys also require `resolveRecords` |
| Existing untagged LaWallet account | Explicit `PasskeyAccount` with `mode: 'derived'`, `parameterSet: 2`, original RP, credential ID and expected public key |
| Existing Nosskey direct account | Explicit original metadata with `mode: 'legacyNosskeyDirect'`; never inferred from an unknown credential |

Store public metadata with `PasskeyAccount.toJson()` and restore it with `fromJson()`. Passing it as `account` enforces the original identity. Without metadata, login classifies the returned handle and accepts supported tagged formats only. Unknown credentials, unknown parameter sets and legacy stored handles are rejected without guessing another identity. Nosskey wrapped records, keytr legacy records and the optional vault companion are not decoded by this integration; use an explicit compatible reader and the existing `loginExternalSigner` API, or connect through a supported signer integration (NIP-46 where offered).

For stored keys, supply `existingCredentialIds` to collect valid signed kind `31778` records for the author and locally known credential IDs before registration, and `saveRecord` to persist the encrypted bytes. Creation requires `hasVerifiedRecoveryCopy: true`: the host must first verify independent recovery of every key and vault item it intends to preserve, because registration can replace a same-handle credential. Login's `resolveRecords` supplies user-selected files or validated relay records; the API documents the required signature, author, tag and encoding checks. Use `onRecordFailure` to report rejected candidates. Persistence must succeed before the account is installed. The adapters do not manage `largeBlob` or automatically publish records.

Passkeys require PRF support and user verification. Use HTTPS in browsers and configure the RP domain's [native app associations](https://pub.dev/packages/passkeys#setup). Native Apple PRF requires iOS 18+/macOS 15+; Android and browser support depends on the credential provider. A platform passkey or compatible security key may be selected. Related-origin authorization remains the host's responsibility; format compatibility does not grant access to another RP.

!!!warning Recovery
Use the original RP and credential. Synchronization belongs to the passkey provider and is not guaranteed; a stored account also needs its encrypted record. Cancellation or failed recovery never creates a replacement identity. Signing keys remain in the session and should not be persisted as private-key accounts.
!!!

### Reacting to changes

```dart watch the logged in account
ndk.accounts.authStateChanges.listen((account) {
    // account is null when logged out
});
```

```dart watch the list of accounts
ndk.accounts.accountsStream.listen((accounts) {
    // pubkey -> Account, emitted on every add and remove
});
```

`accountsStream` emits the current accounts on subscription, then an unmodifiable
snapshot each time an account is added or removed. `switchAccount` changes the
logged in account but not the list, so it only fires `authStateChanges`.

The `ndk.accounts.accounts` map is a read-only view of the same data, for when you
need a synchronous read instead of a stream.

## When to use

Use it to log in an account.
You can use several types of accounts:

- `loginPrivateKey`
- `loginPublicKey` (read-only)
- `loginExternalSigner` (capabilities will be managed by external signer)

An account logged in is needed in order to use [broadcast](/usecases/broadcast.md), and only if the signer used is able to sign.

You can switch between several logged in accounts with `switchAccount(pubkey:...)`
