import '../../../domain_layer/entities/wallet/wallet.dart';
import '../../../domain_layer/entities/wallet/wallet_balance.dart';
import '../../../domain_layer/entities/wallet/wallet_transaction.dart';
import '../../../domain_layer/entities/wallet/wallet_type.dart';
import '../../../domain_layer/repositories/cache_manager.dart';
import '../../../domain_layer/repositories/wallets_repo.dart';
import '../../../domain_layer/usecases/cashu_wallet/cashu.dart';
import '../../../domain_layer/usecases/nwc/nwc.dart';

/// this class manages the wallets (storage) and
/// glues the specific wallet implementation to the generic wallets usecase  \
/// the glue code is readonly for actions look at [WalletsOperationsRepo]
class WalletsRepoImpl implements WalletsRepo {
  final Cashu _cashuUseCase;
  final Nwc _nwcUseCase;
  final CacheManager _cacheManger;

  WalletsRepoImpl({
    required Cashu cashuUseCase,
    required Nwc nwcUseCase,
    required CacheManager cacheManager,
  })  : _cashuUseCase = cashuUseCase,
        _nwcUseCase = nwcUseCase,
        _cacheManger = cacheManager;

  @override
  Future<void> addWallet(Wallet account) {
    // TODO: implement addWallet
    throw UnimplementedError();
  }

  @override
  Future<Wallet> getWallet(String id) {
    /// load from db
    // TODO: implement getWallet
    throw UnimplementedError();
  }

  @override
  Future<List<Wallet>> getWallets() {
    // TODO: implement getWallets
    throw UnimplementedError();
  }

  @override
  Future<void> removeWallet(String id) {
    // TODO: implement removeWallet
    throw UnimplementedError();
  }

  @override
  Stream<List<WalletBalance>> getBalancesStream(String accountId) async* {
    // delegate to appropriate use case based on account type
    final useCase = await _getAccountUseCase(accountId);
    if (useCase is Cashu) {
      // transform to WalletBalance
      yield* useCase.balances.map((balances) => balances.expand((b) {
            return b.balances.entries.map((entry) => WalletBalance(
                  unit: entry.key,
                  amount: entry.value,
                  walletId: b.mintUrl,
                ));
          }).toList());
    } else if (useCase is Nwc) {
      throw UnimplementedError('NWC balances stream not implemented yet');
    } else {
      throw UnimplementedError('Unknown account type for balances stream');
    }
  }

  @override
  Stream<List<WalletTransaction>> getPendingTransactionsStream(
      String accountId) {
    // TODO: implement getPendingTransactionsStream
    throw UnimplementedError();
  }

  @override
  Stream<List<WalletTransaction>> getRecentTransactionsStream(
      String accountId) {
    // TODO: implement getRecentTransactionsStream
    throw UnimplementedError();
  }

  Future<dynamic> _getAccountUseCase(String accountId) async {
    final account = await getWallet(accountId);
    switch (account.type) {
      case WalletType.CASHU:
        return _cashuUseCase;
      case WalletType.NWC:
        return _nwcUseCase;
    }
  }
}
