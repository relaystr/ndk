import 'dart:async';

import '../../../shared/helpers/mutex_simple.dart';
import '../../entities/cashu/cashu_keyset.dart';
import '../../entities/cashu/cashu_proof.dart';
import '../../entities/wallet/wallet_transaction.dart';
import '../../entities/wallet/wallet_type.dart';
import '../../repositories/cache_manager.dart';

class CashuCacheDecorator implements CacheManager {
  final MutexSimple _mutex;
  final CacheManager _delegate;

  CashuCacheDecorator({
    required CacheManager cacheManager,
    MutexSimple? mutex,
  })  : _delegate = cacheManager,
        _mutex = mutex ?? MutexSimple();

  @override
  Future<void> saveProofs({
    required List<CashuProof> tokens,
    required String mintUrl,
  }) async {
    await _mutex.synchronized(() async {
      await _delegate.saveProofs(tokens: tokens, mintUrl: mintUrl);
    });
  }

  @override
  Future<void> removeProofs({
    required List<CashuProof> proofs,
    required String mintUrl,
  }) async {
    await _mutex.synchronized(() async {
      await _delegate.removeProofs(proofs: proofs, mintUrl: mintUrl);
    });
  }

  @override
  Future<List<CashuProof>> getProofs({
    String? mintUrl,
    String? keysetId,
  }) async {
    return await _mutex.synchronized(() async {
      return await _delegate.getProofs(mintUrl: mintUrl, keysetId: keysetId);
    });
  }

  @override
  Future<List<CahsuKeyset>> getKeysets({
    String? mintUrl,
  }) {
    return _mutex.synchronized(() async {
      return await _delegate.getKeysets(mintUrl: mintUrl);
    });
  }

  @override
  Future<void> saveKeyset(CahsuKeyset keyset) async {
    await _mutex.synchronized(() async {
      await _delegate.saveKeyset(keyset);
    });
  }

  @override
  Future<List<WalletTransaction>> getTransactions({
    int? limit,
    String? walletId,
    String? unit,
    WalletType? walletType,
  }) {
    return _mutex.synchronized(() async {
      return await _delegate.getTransactions(
        limit: limit,
        walletId: walletId,
        unit: unit,
        walletType: walletType,
      );
    });
  }

  @override
  Future<void> saveTransactions({
    required List<WalletTransaction> transactions,
  }) {
    return _mutex.synchronized(() async {
      await _delegate.saveTransactions(transactions: transactions);
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
        'CashuCacheDecorator does not implement ${invocation.memberName}. Add an explicit delegate method.');
  }

  Future<T> runInTransaction<T>(Future<T> Function() action) async {
    return await _mutex.synchronized(() async {
      return await action();
    });
  }

  Future<void> atomicSaveAndRemove({
    required List<CashuProof> proofsToRemove,
    required List<CashuProof> tokensToSave,
    required String mintUrl,
  }) async {
    await runInTransaction(() async {
      await _delegate.removeProofs(proofs: proofsToRemove, mintUrl: mintUrl);
      await _delegate.saveProofs(tokens: tokensToSave, mintUrl: mintUrl);
    });
  }
}
