---
icon: person
---

[!badge variant="primary" text="high level"]

## Example

:::code source="../../packages/ndk/example/account_test.dart" language="dart" range="16-34" title="" :::

### External Signer (web)

:::code source="../../packages/nip07_event_signer/example/nip07_event_signer_example.dart" language="dart"  title="" :::

### External Signer (nip-46 bunker)

```dart login with bunker url
final bunkerConnection = await ndk.accounts.loginWithBunkerUrl(
    bunkerUrl: "bunker://xxx",
    bunkers: ndk.bunkers,
    authCallback: (challenge) {},
);
```

```dart login with nostr connect
final nostrConnect = NostrConnect(relays: ["wss://relay.example.com"]);
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

### Authentication state

```dart
ndk.accounts.authStateChanges.listen((account) {
if (account == null) {
    print('No active user');
} else {
    print('Active user: ${account.pubkey}');
}
});
```

Events are fired when the following occurs:
- On login
- On logout
- On switch account

## When to use

Use it to log in an account.
You can use several types of accounts:

- `loginPrivateKey`
- `loginPublicKey` (read-only)
- `loginExternalSigner` (capabilities will be managed by external signer)

An account logged in is needed in order to use [broadcast](/usecases/broadcast.md), and only if the signer used is able to sign.

You can switch between several logged in accounts with `switchAccount(pubkey:...)`
