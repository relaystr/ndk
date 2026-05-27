# Wallets (NWC + Cashu)

> Both are `@experimental`. API may change.

## Nostr Wallet Connect (NWC)

Access via `ndk.nwc`.

```dart
// Connect wallet
final connection = await ndk.nwc.connect(
  uri: NostrWalletConnectUri.parse('nostr+walletconnect://...'),
);

// Balance
final balance = await ndk.nwc.getBalance(connection);
print(balance.balanceSat);

// Pay invoice
final result = await ndk.nwc.payInvoice(
  connection,
  invoice: 'lnbc...',
);

// Get invoice
final invoice = await ndk.nwc.makeInvoice(
  connection,
  amountSat: 1000,
  description: 'test',
);

// List transactions
final txs = await ndk.nwc.listTransactions(connection);

// Disconnect all
await ndk.nwc.disconnectAll();
```

### NWC connection

```dart
// Parse from URI string
final uri = NostrWalletConnectUri.parse('nostr+walletconnect://...');

// Connection object
final conn = NwcConnection(uri: uri);
```

## Cashu (e-cash)

Access via `ndk.cashu`. Requires `cashuUserSeedphrase` in `NdkConfig`.

```dart
// Config with Cashu
final ndk = Ndk(NdkConfig(
  eventVerifier: Bip340EventVerifier(),
  cache: MemCacheManager(),
  cashuUserSeedphrase: CashuUserSeedphrase(seedphrase: 'word1 word2 ...'),
));

// Generate new seed phrase (store securely!)
final seed = CashuSeed.generateSeedPhrase();

// Access cashu usecase
ndk.cashu  // Cashu
```

## Combined Wallets usecase

`ndk.wallets` aggregates NWC and Cashu wallets.

```dart
// List all wallet accounts (NWC + Cashu combined)
ndk.wallets.walletAccounts  // Stream or list of WalletAccount

// Dispose when done
ndk.wallets.dispose();
```
