import 'dart:async';

import 'package:rxdart/rxdart.dart';

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
  Future<void> removeWallet(String id) async {
    Wallet wallet = await getWallet(id);
    if (wallet is NwcWallet) {
      NwcWallet nwcWallet = wallet;
      // close connection if exists
      if (wallet.connection != null) {
        await _nwcUseCase.disconnect(nwcWallet.connection!);
        if (nwcWallet.balanceSubject != null) {
          await nwcWallet.balanceSubject!.close();
        }
        if (nwcWallet.transactionsSubject != null) {
          await nwcWallet.transactionsSubject!.close();
        }
        if (nwcWallet.pendingTransactionsSubject != null) {
          await nwcWallet.pendingTransactionsSubject!.close();
        }
      }
    }
    return _cacheManger.removeWallet(id);
  }

  @override
  Stream<List<WalletBalance>> getBalancesStream(String id) async* {
    // delegate to appropriate use case based on account type
    final useCase = await _getWalletUseCase(id);
    if (useCase is Cashu) {
      // transform to WalletBalance
      yield* useCase.balances.map((balances) => balances.where((b) => b.mintUrl == id).expand((b) {
            return b.balances.entries.map((entry) => WalletBalance(
                  unit: entry.key,
                  amount: entry.value,
                  walletId: b.mintUrl,
                ));
          }).toList());
    } else if (useCase is Nwc) {
      NwcWallet wallet = (await getWallet(id)) as NwcWallet;
      if (!wallet.isConnected()) {
        await _initNwcWalletConnection(wallet);
      }
      wallet.balanceSubject ??= BehaviorSubject<List<WalletBalance>>();

      final balanceResponse = await useCase.getBalance(wallet.connection!);
      wallet.balanceSubject!.add([WalletBalance(walletId: id, unit: "sat", amount: balanceResponse.balanceSats)]);
      yield* wallet.balanceSubject!.stream;
    } else {
      throw UnimplementedError('Unknown account type for balances stream');
    }
  }

  Future<void> _initNwcWalletConnection(NwcWallet wallet) async {
    wallet.connection ??= await _nwcUseCase.connect(wallet.metadata["nwcUrl"],
        doGetInfoMethod: true // TODO getInfo or not should be ndk config somehow
        );

    wallet.connection!.notificationStream.stream.listen((notification) async {
      if (!notification.isPaymentReceived && !notification.isPaymentSent) {
        return; // only incoming and outgoing payments are handled here
      }
      if (wallet.balanceSubject != null && notification.state == "settled") {
        final balanceResponse = await _nwcUseCase.getBalance(wallet.connection!);
        wallet.balanceSubject!
            .add([WalletBalance(walletId: wallet.id, unit: "sat", amount: balanceResponse.balanceSats)]);
      }
      if (wallet.transactionsSubject != null || wallet.pendingTransactionsSubject != null) {
        final transaction = NwcWalletTransaction(
          id: notification.paymentHash,
          walletId: wallet.id,
          changeAmount: (notification.isIncoming ? notification.amount /1000 : -notification.amount /1000) as int,
          unit: "sats",
          walletType: WalletType.NWC,
          state: notification.isSettled
              ? WalletTransactionState.completed
              : (notification.isPending?WalletTransactionState.pending: WalletTransactionState.failed),
          metadata: notification.metadata ?? {},
          transactionDate: notification.settledAt ?? notification.createdAt,
          initiatedDate: notification.createdAt,
        );
        if (notification.isSettled) {
          wallet.transactionsSubject!.add([transaction]);
        } else if (notification.isPending) {
          wallet.pendingTransactionsSubject!.add([transaction]);
        }
      }
    });
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
                mintInfo: mint,
              ))
          .toList();
    });
  }

  @override
  Stream<List<WalletTransaction>> getPendingTransactionsStream(
    String id,
  ) async* {
    final useCase = await _getWalletUseCase(id);
    if (useCase is Cashu) {
      /// filter transaction stream by id
      yield* useCase.pendingTransactions.map(
        (transactions) => transactions.where((transaction) => transaction.walletId == id).toList(),
      );
    } else if (useCase is Nwc) {
      NwcWallet wallet = (await getWallet(id)) as NwcWallet;
      if (!wallet.isConnected()) {
        await _initNwcWalletConnection(wallet);
      }
      wallet.pendingTransactionsSubject ??= BehaviorSubject<List<WalletTransaction>>();
      final transactions = await _nwcUseCase.listTransactions(wallet.connection!, unpaid: true);
      wallet.pendingTransactionsSubject!.add(transactions.transactions.reversed
          .where((e) => e.state != null && e.state == "pending")
          .map((e) => NwcWalletTransaction(
        id: e.paymentHash,
        walletId: wallet.id,
        changeAmount: e.isIncoming ? e.amountSat : -e.amountSat,
        unit: "sats",
        walletType: WalletType.NWC,
        state: e.state != null && e.state == "settled"
            ? WalletTransactionState.completed
            : WalletTransactionState.pending,
        metadata: e.metadata ?? {},
        transactionDate: e.settledAt ?? e.createdAt,
        initiatedDate: e.createdAt,
      ))
          .toList());
      yield* wallet.pendingTransactionsSubject!.stream;
    } else {
      throw UnimplementedError('Unknown account type for pending transactions stream');
    }
  }

  @override
  Stream<List<WalletTransaction>> getRecentTransactionsStream(
    String id,
  ) async* {
    final useCase = await _getWalletUseCase(id);
    if (useCase is Cashu) {
      /// filter transaction stream by id
      yield* useCase.latestTransactions.map(
        (transactions) => transactions.where((transaction) => transaction.walletId == id).toList(),
      );
    } else if (useCase is Nwc) {
      NwcWallet wallet = (await getWallet(id)) as NwcWallet;
      if (!wallet.isConnected()) {
        await _initNwcWalletConnection(wallet);
      }
      wallet.transactionsSubject ??= BehaviorSubject<List<WalletTransaction>>();
      final transactions = await _nwcUseCase.listTransactions(wallet.connection!, unpaid: false);
      wallet.transactionsSubject!.add(transactions.transactions.reversed
          .where((e) => e.state != null && e.state == "settled")
          .map((e) => NwcWalletTransaction(
                id: e.paymentHash,
                walletId: wallet.id,
                changeAmount: e.isIncoming ? e.amountSat : -e.amountSat,
                unit: "sats",
                walletType: WalletType.NWC,
                state: e.state != null && e.state == "settled"
                    ? WalletTransactionState.completed
                    : WalletTransactionState.pending,
                metadata: e.metadata ?? {},
                transactionDate: e.settledAt ?? e.createdAt,
                initiatedDate: e.createdAt,
              ))
          .toList());
      yield* wallet.transactionsSubject!.stream;
    } else {
      throw UnimplementedError('Unknown account type for recent transactions stream');
    }
  }

  @override
  Future<List<WalletTransaction>> getTransactions({
    int? limit,
    int? offset,
    String? walletId,
    String? unit,
    WalletType? walletType,
  }) {
    return _cacheManger.getTransactions(
      limit: limit,
      offset: offset,
      walletId: walletId,
      unit: unit,
      walletType: walletType,
    );
  }

  Future<dynamic> _getWalletUseCase(String id) async {
    final account = await getWallet(id);
    switch (account.type) {
      case WalletType.CASHU:
        return _cashuUseCase;
      case WalletType.NWC:
        return _nwcUseCase;
    }
  }
}
