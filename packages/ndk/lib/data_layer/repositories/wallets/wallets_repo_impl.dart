import '../../../domain_layer/entities/wallet/wallet.dart';
import '../../../domain_layer/entities/wallet/wallet_balance.dart';
import '../../../domain_layer/entities/wallet/wallet_transaction.dart';
import '../../../domain_layer/entities/wallet/wallet_type.dart';
import '../../../domain_layer/repositories/cache_manager.dart';
import '../../../domain_layer/repositories/wallets_repo.dart';
import '../../../domain_layer/usecases/cashu/cashu.dart';
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
    return _cacheManger.saveWallet(account);
  }

  @override
  Future<Wallet> getWallet(String id) async {
    final wallets = await _cacheManger.getWallets(ids: [id]);
    if (wallets == null || wallets.isEmpty) {
      throw Exception('Wallet with id $id not found');
    }
    return wallets.first;
  }

  @override
  Future<List<Wallet>> getWallets() async {
    final wallets = await _cacheManger.getWallets();
    if (wallets == null) {
      return [];
    }
    return wallets;
  }

  @override
  Future<void> removeWallet(String id) {
    return _cacheManger.removeWallet(id);
  }

  @override
  Stream<List<WalletBalance>> getBalancesStream(String accountId) async* {
    // delegate to appropriate use case based on account type
    final useCase = await _getWalletUseCase(accountId);
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

  /// get notified about possible new wallets \
  /// this is used to update the UI when new wallets are implicitly added \
  /// like when receiving something on a not yet existing wallet
  @override
  Stream<List<Wallet>> walletsUsecaseStream() {
    return _cashuUseCase.knownMints.map((mints) {
      return mints
          .map((mint) => CashuWallet(
                id: mint.urls.first,
                mintUrl: mint.urls.first,
                type: WalletType.CASHU,
                name: mint.name ?? mint.urls.first,
                supportedUnits: mint.supportedUnits,
              ))
          .toList();
    });
  }

  @override
  Stream<List<WalletTransaction>> getPendingTransactionsStream(
    String accountId,
  ) async* {
    final useCase = await _getWalletUseCase(accountId);
    if (useCase is Cashu) {
      /// filter transaction stream by id
      yield* useCase.pendingTransactions.map(
        (transactions) => transactions
            .where((transaction) => transaction.walletId == accountId)
            .toList(),
      );
    } else if (useCase is Nwc) {
      throw UnimplementedError(
          'NWC pending transactions stream not implemented yet');
    } else {
      throw UnimplementedError(
          'Unknown account type for pending transactions stream');
    }
  }

  @override
  Stream<List<WalletTransaction>> getRecentTransactionsStream(
    String accountId,
  ) async* {
    final useCase = await _getWalletUseCase(accountId);
    if (useCase is Cashu) {
      /// filter transaction stream by id
      yield* useCase.latestTransactions.map(
        (transactions) => transactions
            .where((transaction) => transaction.walletId == accountId)
            .toList(),
      );
    } else if (useCase is Nwc) {
      throw UnimplementedError(
          'NWC recent transactions stream not implemented yet');
    } else {
      throw UnimplementedError(
          'Unknown account type for recent transactions stream');
    }
  }

  Future<dynamic> _getWalletUseCase(String accountId) async {
    final account = await getWallet(accountId);
    switch (account.type) {
      case WalletType.CASHU:
        return _cashuUseCase;
      case WalletType.NWC:
        return _nwcUseCase;
    }
  }
}
