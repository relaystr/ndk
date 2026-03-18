# Wallet Architecture

This document describes the wallet architecture using the **Strategy Pattern** with **Dependency Injection**.

## Overview

The wallet system uses a **Strategy Pattern** where each wallet type implements the `WalletProvider` interface. This provides a unified API for wallet operations while allowing each wallet type to have its own specific implementation.

## Architecture Components

### 1. Base Wallet Interface (`wallet.dart`)

```dart
abstract class Wallet {
  final String id;
  final WalletType type;
  final Set<String> supportedUnits;
  String name;
  final Map<String, dynamic> metadata;
  
  Map<String, dynamic> toMetadata();
}
```

All wallet types must extend this base class.

### 2. Wallet Provider Interface (`wallet_provider.dart`)

The provider combines factory and operations:

```dart
abstract class WalletProvider {
  WalletType get type;
  
  // Factory
  Wallet createWallet({...});
  
  // Operations
  Future<void> initialize(Wallet wallet);
  Future<void> dispose(Wallet wallet);
  Stream<List<WalletBalance>> getBalances(Wallet wallet);
  Stream<List<WalletTransaction>> getPendingTransactions(Wallet wallet);
  Stream<List<WalletTransaction>> getRecentTransactions(Wallet wallet);
  Future<PayInvoiceResponse> payInvoice(Wallet wallet, String invoice);
  Stream<List<Wallet>> get discoveredWallets;
}
```

### 3. Wallet Repository (`wallets_repo.dart`)

Thin abstraction over `CacheManager` for persistence:

```dart
abstract class WalletsRepo {
  Future<List<Wallet>> getWallets();
  Future<Wallet> getWallet(String id);
  Future<void> addWallet(Wallet wallet);
  Future<void> removeWallet(String id);
  Future<List<WalletTransaction>> getTransactions({...});
}
```

## Current Wallet Types

### Cashu Wallet
- Location: `providers/cashu/`
- Files:
  - `cashu_wallet.dart` - Wallet data class
  - `cashu_wallet_provider.dart` - Provider implementation

### NWC Wallet  
- Location: `providers/nwc/`
- Files:
  - `nwc_wallet.dart` - Wallet data class
  - `nwc_wallet_provider.dart` - Provider implementation

## Adding a New Wallet Type

To add a new wallet type (e.g., "LightningWallet"):

### 1. Add the Wallet Type to the Enum

Edit `wallet_type.dart`:

```dart
enum WalletType {
  NWC('nwc'),
  CASHU('cashu'),
  LIGHTNING('lightning');  // Add new type
  
  final String value;
  const WalletType(this.value);
}
```

### 2. Create the Wallet Data Class

Create `providers/lightning/lightning_wallet.dart`:

```dart
import 'package:ndk/domain_layer/entities/wallet/wallet.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet_type.dart';

class LightningWallet extends Wallet {
  final String nodeUrl;
  final String macaroon;

  LightningWallet({
    required super.id,
    required super.name,
    super.type = WalletType.LIGHTNING,
    required super.supportedUnits,
    required this.nodeUrl,
    required this.macaroon,
    Map<String, dynamic>? metadata,
  }) : super(
          metadata: Map.unmodifiable({
            ...(metadata ?? const {}),
            'nodeUrl': nodeUrl,
            'macaroon': macaroon,
          }),
        );

  @override
  Map<String, dynamic> toMetadata() => metadata;
}
```

### 3. Create the Wallet Provider

Create `providers/lightning/lightning_wallet_provider.dart`:

```dart
import 'package:ndk/domain_layer/entities/wallet/wallet.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet_provider.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet_type.dart';
import 'lightning_wallet.dart';

class LightningWalletProvider implements WalletProvider {
  final Lightning _lightningUseCase;
  
  LightningWalletProvider(this._lightningUseCase);

  @override
  WalletType get type => WalletType.LIGHTNING;

  @override
  Wallet createWallet({
    required String id,
    required String name,
    required Set<String> supportedUnits,
    required Map<String, dynamic> metadata,
  }) {
    final nodeUrl = metadata['nodeUrl'] as String?;
    final macaroon = metadata['macaroon'] as String?;
    
    if (nodeUrl == null || nodeUrl.isEmpty) {
      throw ArgumentError('LightningWallet requires metadata["nodeUrl"]');
    }
    if (macaroon == null || macaroon.isEmpty) {
      throw ArgumentError('LightningWallet requires metadata["macaroon"]');
    }

    return LightningWallet(
      id: id,
      name: name,
      supportedUnits: supportedUnits,
      nodeUrl: nodeUrl,
      macaroon: macaroon,
      metadata: metadata,
    );
  }

  @override
  Future<void> initialize(Wallet wallet) async {
    // Connect to Lightning node
  }

  @override
  Future<void> dispose(Wallet wallet) async {
    // Close connection
  }

  @override
  Stream<List<WalletBalance>> getBalances(Wallet wallet) async* {
    // Return balances from Lightning node
  }

  @override
  Stream<List<WalletTransaction>> getPendingTransactions(Wallet wallet) async* {
    // Return pending transactions
  }

  @override
  Stream<List<WalletTransaction>> getRecentTransactions(Wallet wallet) async* {
    // Return recent transactions
  }

  @override
  Future<PayInvoiceResponse> payInvoice(Wallet wallet, String invoice) async {
    // Pay the invoice
  }

  @override
  Stream<List<Wallet>> get discoveredWallets => Stream.value([]);
}
```

### 4. Export the New Wallet

Add to `wallets.dart` barrel file:

```dart
// Lightning wallet
export 'providers/lightning/lightning_wallet.dart';
export 'providers/lightning/lightning_wallet_provider.dart';
```

### 5. Inject Provider in Initialization

Update your dependency injection (e.g., `init.dart`):

```dart
// Create providers
final lightningUseCase = Lightning(...);
final lightningProvider = LightningWalletProvider(lightningUseCase);

// Create wallets usecase
final wallets = Wallets(
  providers: [cashuProvider, nwcProvider, lightningProvider],  // Add here
  repository: walletsRepo,
);
```

## Benefits

1. **No Global State**: No singletons or static registries
2. **Explicit Dependencies**: All providers injected via constructor
3. **Compile-Time Safety**: Type-safe, no runtime factory lookups
4. **Easy Testing**: Inject mock providers
5. **Open/Closed Principle**: Add new wallets without modifying existing code
6. **Single Responsibility**: Each provider handles one wallet type

## Usage Example

```dart
// Initialization
final wallets = Wallets(
  providers: [
    CashuWalletProvider(cashu),
    NwcWalletProvider(nwc),
  ],
  repository: walletsRepo,
);

// Create a wallet
final wallet = wallets.createWallet(
  id: 'my-wallet',
  name: 'My Cashu Wallet',
  type: WalletType.CASHU,
  supportedUnits: {'sat'},
  metadata: {
    'mintUrl': 'https://mint.example.com',
    'mintInfo': {...},
  },
);

await wallets.addWallet(wallet);

// Use the wallet
final balances = await wallets.getBalancesStream(wallet.id).first;
await wallets.payInvoice(wallet.id, 'lnbc...');
```

## Architecture Diagram

```
┌─────────────────────────────────────┐
│           Wallets (Usecase)         │
│  - Coordinates providers + storage  │
│  - High-level operations            │
└──────────────┬──────────────────────┘
               │
       ┌───────┴────────┐
       │                │
┌──────▼──────┐  ┌──────▼──────┐
│ WalletProvider│  │ WalletsRepo  │
│  (Strategy) │  │  (Storage)   │
└──────┬──────┘  └──────┬──────┘
       │                │
┌──────▼──────┐  ┌──────▼──────┐
│CashuProvider│  │CacheManager│
│ NwcProvider │  └─────────────┘
│  ... etc    │
└─────────────┘
```
