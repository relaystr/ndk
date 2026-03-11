// Barrel file for wallet-related classes
// Contains both exports and the WalletFactory for storage deserialization

// First: all exports
export 'wallet.dart';
export 'wallet_type.dart';
export 'wallet_provider.dart';
export 'wallet_balance.dart';
export 'wallet_transaction.dart';

export 'providers/cashu/cashu_wallet.dart';
export 'providers/cashu/cashu_wallet_provider.dart';

export 'providers/nwc/nwc_wallet.dart';
export 'providers/nwc/nwc_wallet_provider.dart';

// Then: imports needed for WalletFactory
import 'providers/cashu/cashu_wallet.dart';
import 'providers/nwc/nwc_wallet.dart';
import 'wallet.dart';
import 'wallet_type.dart';

/// Factory for deserializing wallets from storage
/// Storage packages use this to convert stored data back to Wallet objects
/// Each wallet type implements a static fromStorage method that handles its specific deserialization
class WalletFactory {
  /// Creates a wallet instance from storage data
  /// Delegates to subclass static fromStorage methods based on wallet type
  static Wallet fromStorage({
    required String id,
    required String name,
    required WalletType type,
    required Set<String> supportedUnits,
    required Map<String, dynamic> metadata,
  }) {
    switch (type) {
      case WalletType.CASHU:
        return CashuWallet.fromStorage(
          id: id,
          name: name,
          supportedUnits: supportedUnits,
          metadata: metadata,
        );
      case WalletType.NWC:
        return NwcWallet.fromStorage(
          id: id,
          name: name,
          supportedUnits: supportedUnits,
          metadata: metadata,
        );
    }
  }
}
