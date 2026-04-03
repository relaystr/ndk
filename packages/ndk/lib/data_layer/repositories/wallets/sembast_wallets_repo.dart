import 'dart:async';

import 'package:ndk/data_layer/repositories/wallets/wallet_extensions.dart';
import 'package:ndk/domain_layer/repositories/wallets_repo.dart';
import 'package:ndk/entities.dart';
import 'package:sembast/sembast.dart' as sembast;
import 'package:sembast/sembast_io.dart';

class SembastWalletsRepo extends WalletsRepo {
  static const String defaultWalletForReceivingKey =
      'default_wallet_for_receiving';
  static const String defaultWalletForSendingKey = 'default_wallet_for_sending';

  final sembast.Database _database;

  late final sembast.StoreRef<String, Map<String, Object?>> _transactionStore;
  late final sembast.StoreRef<String, Map<String, Object?>> _walletStore;
  late final sembast.StoreRef<String, Map<String, Object?>> _keyValueStore;

  String? _defaultWalletIdForReceiving;
  String? _defaultWalletIdForSending;

  static Future<SembastWalletsRepo> create({
    required String filename,
    String databaseName = "sembast_cache_manager",
  }) async {
    final database = await databaseFactoryIo.openDatabase(filename);
    final repo = SembastWalletsRepo(database);
    await repo.initializeWalletDefaults();
    return repo;
  }

  SembastWalletsRepo(this._database) {
    _transactionStore = sembast.stringMapStoreFactory.store('transactions');
    _walletStore = sembast.stringMapStoreFactory.store('wallets');
    _keyValueStore = sembast.stringMapStoreFactory.store('key_values');
  }

  Future<void> initializeWalletDefaults() async {
    final receiving = await _keyValueStore
        .record(defaultWalletForReceivingKey)
        .get(_database);
    final sending =
        await _keyValueStore.record(defaultWalletForSendingKey).get(_database);

    _defaultWalletIdForReceiving = receiving?['value'] as String?;
    _defaultWalletIdForSending = sending?['value'] as String?;
  }

  Future<void> clearWalletRepoData() async {
    await Future.wait([
      _transactionStore.delete(_database),
      _walletStore.delete(_database),
      _keyValueStore.delete(_database),
    ]);
    _defaultWalletIdForReceiving = null;
    _defaultWalletIdForSending = null;
  }

  Future<void> _storeDefaultWallet({
    required String key,
    required String? walletId,
  }) async {
    await _keyValueStore.record(key).put(_database, {'value': walletId});
  }

  @override
  Future<List<WalletTransaction>> getTransactions({
    int? limit,
    int? offset,
    String? walletId,
    String? unit,
    WalletType? walletType,
  }) async {
    final filters = <sembast.Filter>[];

    if (walletId != null && walletId.isNotEmpty) {
      filters.add(sembast.Filter.equals('walletId', walletId));
    }

    if (unit != null && unit.isNotEmpty) {
      filters.add(sembast.Filter.equals('unit', unit));
    }

    if (walletType != null) {
      filters.add(sembast.Filter.equals('walletType', walletType.toString()));
    }

    final finder = sembast.Finder(
      filter: filters.isNotEmpty ? sembast.Filter.and(filters) : null,
      sortOrders: [sembast.SortOrder('transactionDate', false)],
      limit: limit,
      offset: offset,
    );

    final records = await _transactionStore.find(_database, finder: finder);
    return records
        .map((record) =>
            WalletTransactionExtension.fromJsonStorage(record.value))
        .toList();
  }

  @override
  Future<void> saveTransactions(
    List<WalletTransaction> transactions,
  ) async {
    await _database.transaction((txn) async {
      final idsToCheck = transactions.map((t) => t.id).toList();
      final finder = sembast.Finder(
        filter: sembast.Filter.inList('id', idsToCheck),
      );
      await _transactionStore.delete(txn, finder: finder);

      for (final transaction in transactions) {
        await _transactionStore
            .record(transaction.id)
            .put(txn, transaction.toJsonForStorage());
      }
    });
  }

  @override
  Future<List<Wallet>> getWallets({List<String>? ids}) async {
    if (ids == null || ids.isEmpty) {
      final records = await _walletStore.find(_database);
      return records
          .map((record) => WalletExtension.fromJsonStorage(record.value))
          .toList();
    }

    final finder = sembast.Finder(
      filter: sembast.Filter.inList('id', ids),
    );

    final records = await _walletStore.find(_database, finder: finder);
    return records
        .map((record) => WalletExtension.fromJsonStorage(record.value))
        .toList();
  }

  @override
  Future<void> removeWallet(String walletId) async {
    await _walletStore.record(walletId).delete(_database);
  }

  @override
  Future<void> storeWallet(Wallet wallet) async {
    await _walletStore
        .record(wallet.id)
        .put(_database, wallet.toJsonForStorage());
  }

  @override
  String? getDefaultWalletIdForReceiving() {
    return _defaultWalletIdForReceiving;
  }

  @override
  String? getDefaultWalletIdForSending() {
    return _defaultWalletIdForSending;
  }

  @override
  void setDefaultWalletForReceiving(String? walletId) {
    _defaultWalletIdForReceiving = walletId;
    unawaited(_storeDefaultWallet(
      key: defaultWalletForReceivingKey,
      walletId: walletId,
    ));
  }

  @override
  void setDefaultWalletForSending(String? walletId) {
    _defaultWalletIdForSending = walletId;
    unawaited(_storeDefaultWallet(
      key: defaultWalletForSendingKey,
      walletId: walletId,
    ));
  }
}
