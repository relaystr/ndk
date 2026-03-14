import 'dart:core';

import '../../../domain_layer/entities/cashu/cashu_keyset.dart';
import '../../../domain_layer/entities/cashu/cashu_mint_info.dart';
import '../../../domain_layer/entities/cashu/cashu_proof.dart';
import '../../../domain_layer/entities/contact_list.dart';
import '../../../domain_layer/entities/filter_fetched_ranges.dart';
import '../../../domain_layer/entities/nip_01_event.dart';
import '../../../domain_layer/entities/nip_05.dart';
import '../../../domain_layer/entities/relay_set.dart';
import '../../../domain_layer/entities/user_relay_list.dart';
import '../../../domain_layer/entities/metadata.dart';
import '../../../domain_layer/entities/wallet/wallet.dart';
import '../../../domain_layer/entities/wallet/wallet_transaction.dart';
import '../../../domain_layer/entities/wallet/wallet_type.dart';
import '../../../domain_layer/repositories/cache_manager.dart';
import '../../../domain_layer/repositories/wallets_repo.dart';

/// In memory database implementation
/// benefits: very fast
/// drawbacks: does not persist
class MemWalletsRepo extends WalletsRepo {
  List<WalletTransaction> transactions = [];
  Set<Wallet> wallets = {};
  String? _defaultWalletIdForReceiving;
  String? _defaultWalletIdForSending;

  @override
  Future<List<WalletTransaction>> getTransactions({
    int? limit,
    int? offset,
    String? walletId,
    String? unit,
    WalletType? walletType,
  }) {
    List<WalletTransaction> result = transactions.where((transaction) {
      if (walletId != null && transaction.walletId != walletId) {
        return false;
      }
      if (unit != null && transaction.unit != unit) {
        return false;
      }
      if (walletType != null && transaction.walletType != walletType) {
        return false;
      }
      return true;
    }).toList();

    if (offset != null && offset > 0) {
      result = result.skip(offset).toList();
    }

    if (limit != null && limit > 0) {
      result = result.take(limit).toList();
    }

    return Future.value(result);
  }

  @override
  Future<void> saveTransactions(List<WalletTransaction> transactions) {
    /// Check if transactions are already present
    /// if so update them

    for (final transaction in transactions) {
      final existingIndex = this.transactions.indexWhere(
          (t) => t.id == transaction.id && t.walletId == transaction.walletId);
      if (existingIndex != -1) {
        this.transactions[existingIndex] = transaction;
      } else {
        this.transactions.add(transaction);
      }
    }
    return Future.value();
  }

  @override
  Future<List<Wallet>> getWallets({List<String>? ids}) {
    if (ids == null || ids.isEmpty) {
      return Future.value(wallets.toList());
    } else {
      final result =
          wallets.where((wallet) => ids.contains(wallet.id)).toList();
      return Future.value(result.isNotEmpty ? result : List.empty());
    }
  }

  @override
  Future<void> removeWallet(String id) {
    wallets.removeWhere((wallet) => wallet.id == id);
    return Future.value();
  }

  @override
  Future<void> storeWallet(Wallet wallet) {
    // Remove existing wallet with same ID to prevent duplicates
    wallets.removeWhere((w) => w.id == wallet.id);
    wallets.add(wallet);
    return Future.value();
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
  }

  @override
  void setDefaultWalletForSending(String? walletId) {
    _defaultWalletIdForSending = walletId;
  }
}
