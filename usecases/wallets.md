[!badge variant="primary" text="high level"]

!!!danger experimental
DO NOT USE IN PRODUCTION!
!!!

## When to use

`Wallets` manages multiple wallet types in one place and gives you a unified API for balances, transaction history, sending, and receiving.

Use it if your app:

- supports more than one wallet type
- needs a single transaction history across wallets
- wants separate defaults for sending and receiving
- wants one high-level API instead of calling `cashu`, `nwc`, or `lnurl` directly

## What is supported

| Wallet type | Add manually | Auto-discovery | Send | Receive | Balance/history |
| --- | --- | --- | --- | --- | --- |
| Cashu | yes | yes, from known mints | yes | yes | yes |
| NWC | yes | no | yes | yes, if the wallet allows `make_invoice` | yes |
| LNURL | yes | no | no | yes | no |

## Basic usage

### initialize

Provide a concrete `WalletsRepo` implementation in your `NdkConfig`.

- if you use only core `ndk`, use a core implementation such as `SembastWalletsRepo`
- if possible, prefer the optional `ndk_flutter` package and `FlutterSecureStorageWalletsRepo` for more secure wallet storage

```dart
final ndk = Ndk(
  NdkConfig(
    cache: cacheManager,
    walletsRepo: SembastWalletsRepo.create(
      databasePath: databasePath,
    ),
  ),
);
```

`ndk.wallets` is created automatically during `Ndk` initialization.

### add wallets

Create wallets through `ndk.wallets.createWallet(...)` so the correct provider validates the required metadata.

```dart
final wallets = ndk.wallets;

final nwcWallet = wallets.createWallet(
  id: 'alby',
  name: 'Alby',
  type: WalletType.NWC,
  supportedUnits: {'sat'},
  metadata: {
    'nwcUrl': 'nostr+walletconnect://...',
  },
);

await wallets.addWallet(nwcWallet);

final lnurlWallet = wallets.createWallet(
  id: 'tips',
  name: 'Tips',
  type: WalletType.LNURL,
  supportedUnits: {'sat'},
  metadata: {
    'identifier': 'name@example.com',
  },
);

await wallets.addWallet(lnurlWallet);
```

### wallet-specific metadata

- `WalletType.CASHU`
  requires `mintUrl` and `mintInfo`
- `WalletType.NWC`
  requires `nwcUrl`
- `WalletType.LNURL`
  requires `identifier` in `user@domain.com` format

Example for Cashu:

```dart
final mintInfo = await ndk.cashu.getMintInfoNetwork(
  mintUrl: 'https://example.mint',
);

final cashuWallet = ndk.wallets.createWallet(
  id: 'example-mint',
  name: 'Example Mint',
  type: WalletType.CASHU,
  supportedUnits: mintInfo.supportedUnits,
  metadata: {
    'mintUrl': 'https://example.mint',
    'mintInfo': mintInfo.toJson(),
  },
);

await ndk.wallets.addWallet(cashuWallet);
```

## Examples

### balances

```dart
/// all balances from all wallets
final balancesStream = ndk.wallets.combinedBalances;

balancesStream.listen((balances) {
  for (final balance in balances) {
    print('${balance.walletId}: ${balance.amount} ${balance.unit}');
  }
});

/// balance of one wallet/unit
final cashuSat = ndk.wallets.getBalance('example-mint', 'sat');

/// combined balance across all wallets for one unit
final combinedSat = ndk.wallets.getCombinedBalance('sat');
```

### transactions

```dart
/// pending transactions from all wallets
final pendingTransactions = ndk.wallets.combinedPendingTransactions;

/// completed / recent transactions from all wallets
final recentTransactions = ndk.wallets.combinedRecentTransactions;

/// transactions from storage with optional filters
final transactions = await ndk.wallets.combinedTransactions(
  limit: 100,
  offset: 0,
  walletId: 'mywalletId',
  unit: 'sat',
  walletType: WalletType.CASHU,
);

/// streams for one wallet only
ndk.wallets.getPendingTransactionsStream('mywalletId').listen(print);
ndk.wallets.getRecentTransactionsStream('mywalletId').listen(print);
```

### wallets

```dart
/// stream of all wallets
final walletsStream = ndk.wallets.walletsStream;

/// defaults are separate for send and receive
final defaultSendingWallet = ndk.wallets.defaultWalletForSending;
final defaultReceivingWallet = ndk.wallets.defaultWalletForReceiving;

await ndk.wallets.addWallet(myWallet);

ndk.wallets.setDefaultWallet('myWalletId');
ndk.wallets.setDefaultWalletForSending('myWalletId');
ndk.wallets.setDefaultWalletForReceiving('myWalletId');

await ndk.wallets.removeWallet('myWalletId');

/// wallets that support a given unit
final walletsSupportingSat = ndk.wallets.getWalletsForUnit('sat');
```

### default sending / receiving wallets

The wallet used by generic actions is controlled by two separate defaults:

- `defaultWalletForSending`
  used by `ndk.wallets.send(...)`
- `defaultWalletForReceiving`
  used by `ndk.wallets.receive(...)`

This is useful if, for example, you want to receive through LNURL but send through NWC or Cashu.

When you add a wallet, NDK tries to set defaults automatically:

- the first wallet that can send becomes the default sending wallet
- the first wallet that can receive becomes the default receiving wallet

You can override that explicitly at any time:

```dart
ndk.wallets.setDefaultWalletForSending('alby');
ndk.wallets.setDefaultWalletForReceiving('tips');
```

If you want both defaults to point to the same wallet, use:

```dart
ndk.wallets.setDefaultWallet('myWalletId');
```

If you call `send()` or `receive()` without passing `walletId`, the corresponding default wallet is used.

```dart
final invoice = await ndk.wallets.receive(amountSats: 1000);
final result = await ndk.wallets.send(invoice: 'lnbc1...');
```

If no suitable default wallet is set, those generic methods will fail. In that case, either set a default first or pass `walletId` directly.

### actions

Use these if you want a generic wallet API without caring which provider is behind it.

```dart
/// create an invoice using the default receiving wallet
final invoice = await ndk.wallets.receive(amountSats: 1000);

/// or choose a specific wallet
final invoice2 = await ndk.wallets.receive(
  walletId: 'tips',
  amountSats: 1000,
);

/// pay an invoice using the default sending wallet
final result = await ndk.wallets.send(
  invoice: 'lnbc1...',
);

/// or choose a specific wallet
final result2 = await ndk.wallets.send(
  walletId: 'alby',
  invoice: 'lnbc1...',
);
```

## Notes

- `zap()` is not implemented yet.
- NWC send/receive support depends on the permissions granted by the connected wallet.
- LNURL wallets are receive-only and do not expose balances or transaction history.
- Cashu wallets can also be discovered automatically from known mints.
- If you need provider-specific features, use `ndk.cashu`, `ndk.nwc`, or `ndk.lnurl` directly.
