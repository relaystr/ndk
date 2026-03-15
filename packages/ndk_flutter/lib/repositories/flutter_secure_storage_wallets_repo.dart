import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ndk/domain_layer/repositories/wallets_repo.dart';
import 'package:ndk/entities.dart' as ndk_entities;

const _walletsStateKey = kDebugMode
    ? 'dev_ndk_flutter_wallets_state'
    : 'ndk_flutter_wallets_state';

class FlutterSecureStorageWalletsRepo extends WalletsRepo {
  FlutterSecureStorageWalletsRepo({FlutterSecureStorage? storage})
    : _storage = storage ?? FlutterSecureStorage() {
    _initFuture = _loadState();
  }

  final FlutterSecureStorage _storage;
  late final Future<void> _initFuture;

  final Map<String, ndk_entities.Wallet> _walletsById = {};
  final Map<String, ndk_entities.WalletTransaction> _transactionsByKey = {};

  String? _defaultWalletIdForReceiving;
  String? _defaultWalletIdForSending;

  Future<void> _ensureInitialized() => _initFuture;

  @override
  Future<List<ndk_entities.Wallet>> getWallets({List<String>? ids}) async {
    await _ensureInitialized();

    if (ids == null || ids.isEmpty) {
      return _walletsById.values.toList();
    }

    return _walletsById.values
        .where((wallet) => ids.contains(wallet.id))
        .toList();
  }

  @override
  Future<void> storeWallet(ndk_entities.Wallet wallet) async {
    await _ensureInitialized();
    _walletsById[wallet.id] = wallet;
    await _persistState();
  }

  @override
  Future<void> removeWallet(String id) async {
    await _ensureInitialized();
    _walletsById.remove(id);
    _transactionsByKey.removeWhere(
      (_, transaction) => transaction.walletId == id,
    );

    if (_defaultWalletIdForReceiving == id) {
      _defaultWalletIdForReceiving = null;
    }
    if (_defaultWalletIdForSending == id) {
      _defaultWalletIdForSending = null;
    }

    await _persistState();
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
    unawaited(_persistStateAfterInit());
  }

  @override
  void setDefaultWalletForSending(String? walletId) {
    _defaultWalletIdForSending = walletId;
    unawaited(_persistStateAfterInit());
  }

  @override
  Future<List<ndk_entities.WalletTransaction>> getTransactions({
    int? limit,
    int? offset,
    String? walletId,
    String? unit,
    ndk_entities.WalletType? walletType,
  }) async {
    await _ensureInitialized();

    var transactions = _transactionsByKey.values.where((transaction) {
      if (walletId != null && walletId.isNotEmpty) {
        if (transaction.walletId != walletId) return false;
      }
      if (unit != null && unit.isNotEmpty) {
        if (transaction.unit != unit) return false;
      }
      if (walletType != null) {
        if (transaction.walletType != walletType) return false;
      }
      return true;
    }).toList();

    transactions.sort(
      (a, b) => (b.transactionDate ?? 0).compareTo(a.transactionDate ?? 0),
    );

    if (offset != null && offset > 0) {
      transactions = transactions.skip(offset).toList();
    }

    if (limit != null && limit > 0) {
      transactions = transactions.take(limit).toList();
    }

    return transactions;
  }

  @override
  Future<void> saveTransactions(
    List<ndk_entities.WalletTransaction> transactions,
  ) async {
    await _ensureInitialized();

    for (final transaction in transactions) {
      _transactionsByKey[_transactionKey(
            walletId: transaction.walletId,
            id: transaction.id,
          )] =
          transaction;
    }

    await _persistState();
  }

  Future<void> _persistStateAfterInit() async {
    await _ensureInitialized();
    await _persistState();
  }

  Future<void> _loadState() async {
    final rawState = await _storage.read(key: _walletsStateKey);
    if (rawState == null || rawState.isEmpty) {
      return;
    }

    final decoded = jsonDecode(rawState);
    if (decoded is! Map<String, dynamic>) {
      return;
    }

    _defaultWalletIdForReceiving =
        decoded['defaultWalletIdForReceiving'] as String?;
    _defaultWalletIdForSending =
        decoded['defaultWalletIdForSending'] as String?;

    final wallets = _jsonMapList(decoded['wallets']);
    for (final walletJson in wallets) {
      try {
        final wallet = _walletFromJson(walletJson);
        _walletsById[wallet.id] = wallet;
      } catch (_) {
        continue;
      }
    }

    final transactions = _jsonMapList(decoded['transactions']);
    for (final transactionJson in transactions) {
      try {
        final transaction = _transactionFromJson(transactionJson);
        _transactionsByKey[_transactionKey(
              walletId: transaction.walletId,
              id: transaction.id,
            )] =
            transaction;
      } catch (_) {
        continue;
      }
    }
  }

  Future<void> _persistState() async {
    await _storage.write(
      key: _walletsStateKey,
      value: jsonEncode({
        'wallets': _walletsById.values.map(_walletToJson).toList(),
        'transactions': _transactionsByKey.values
            .map(_transactionToJson)
            .toList(),
        'defaultWalletIdForReceiving': _defaultWalletIdForReceiving,
        'defaultWalletIdForSending': _defaultWalletIdForSending,
      }),
    );
  }

  String _transactionKey({required String walletId, required String id}) {
    return '$walletId::$id';
  }

  ndk_entities.Wallet _walletFromJson(Map<String, dynamic> json) {
    return ndk_entities.WalletFactory.fromStorage(
      id: json['id'] as String,
      name: json['name'] as String,
      type: ndk_entities.WalletType.fromValue(json['type'] as String),
      supportedUnits: (json['supportedUnits'] as List<dynamic>)
          .map((value) => value.toString())
          .toSet(),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map),
    );
  }

  Map<String, dynamic> _walletToJson(ndk_entities.Wallet wallet) {
    return {
      'id': wallet.id,
      'name': wallet.name,
      'type': wallet.type.toString(),
      'supportedUnits': wallet.supportedUnits.toList(),
      'metadata': wallet.metadata,
    };
  }

  ndk_entities.WalletTransaction _transactionFromJson(
    Map<String, dynamic> json,
  ) {
    return ndk_entities.WalletTransaction.toTransactionType(
      id: json['id'] as String,
      walletId: json['walletId'] as String,
      changeAmount: _toInt(json['changeAmount']) ?? 0,
      unit: json['unit'] as String,
      walletType: ndk_entities.WalletType.fromValue(
        json['walletType'] as String,
      ),
      state: ndk_entities.WalletTransactionState.fromValue(
        json['state'] as String,
      ),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map),
      completionMsg: json['completionMsg'] as String?,
      transactionDate: _toInt(json['transactionDate']),
      initiatedDate: _toInt(json['initiatedDate']),
    );
  }

  Map<String, dynamic> _transactionToJson(
    ndk_entities.WalletTransaction transaction,
  ) {
    return {
      'id': transaction.id,
      'walletId': transaction.walletId,
      'changeAmount': transaction.changeAmount,
      'unit': transaction.unit,
      'walletType': transaction.walletType.toString(),
      'state': transaction.state.toString(),
      'completionMsg': transaction.completionMsg,
      'transactionDate': transaction.transactionDate,
      'initiatedDate': transaction.initiatedDate,
      'metadata': transaction.metadata,
    };
  }

  List<Map<String, dynamic>> _jsonMapList(dynamic value) {
    if (value is! List) {
      return const [];
    }
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString());
  }
}
