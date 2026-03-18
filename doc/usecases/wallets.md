---
icon: credit-card
---

[!badge variant="primary" text="high level"]

!!!danger experimental
DO NOT USE IN PRODUCTION!
!!!

## When to use

`Wallets` usecase manages combines multiple wallets (e.g., Cashu, NWC) within your application. It provides functionalities for creating, managing, and transacting.
If you build a transaction history or other reporting, you are advised to use this use case. You can switch or use multiple wallets and still have a unified transaction history.

## Examples

### balances

```dart
/// balances of all wallets, split into walletId and unit
/// returns Stream<List<WalletBalance>>
final balances = await ndk.wallets.combinedBalances;

/// get combined balance of all wallets in a specific unit
/// returns int
final combinedSat = ndk.wallets.getCombinedBalance("sat");
```

### transactions

```dart
/// get all pending transactions, fires immediately and on every change
/// returns Stream<List<WalletTransaction>>
final pendingTransactions = await ndk.wallets.combinedPendingTransactions;


/// get all recent transactions, fires immediately and on every change
/// returns Stream<List<WalletTransaction>>
final recentTransactions = await ndk.wallets.combinedRecentTransactions;

/// get all transactions, with pagination and filtering options
/// returns Future<List<WalletTransaction>>
final transactions = await ndk.wallets.combinedTransactions(
  limit: 100, // optional
  offset: 0, // optional, pagination
   walletId: "mywalletId", // optional
   unit: "sat", // optional
   walletType: WalletType.cashu, // optional
);
```

### wallets

```dart

/// get all wallets
/// returns Stream<List<Wallet>>
final wallets = ndk.wallets.walletsStream;

/// get default wallet
/// returns Wallet?
final defaultWallet = ndk.wallets.defaultWallet;


await ndk.wallets.addWallet(myWallet);

setDefaultWallet("myWalletId");


await ndk.wallets.removeWalet("myWalletId");

/// get all wallets supporting a specific unit
/// returns List<Wallet>
final walletsSupportingSat = ndk.wallets.getWalletsForUnit("sat");

```

### actions

The wallets usecase provides unified actions that work across different wallet types. (WIP)

```dart

///! WIP none of the params are final
final zapResult = await ndk.wallets.zap(
    pubkey: "pubkeyToZap",
    amount: 10,
    comment: "Hello World",
  );

```
