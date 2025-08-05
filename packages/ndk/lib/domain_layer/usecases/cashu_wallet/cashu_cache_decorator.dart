import 'dart:async';

import '../../../shared/helpers/mutex_simple.dart';
import '../../entities/cashu/wallet_cashu_proof.dart';
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
    required List<WalletCashuProof> tokens,
    required String mintUrl,
  }) async {
    await _mutex.synchronized(() async {
      await _delegate.saveProofs(tokens: tokens, mintUrl: mintUrl);
    });
  }

  @override
  Future<void> removeProofs({
    required List<WalletCashuProof> proofs,
    required String mintUrl,
  }) async {
    await _mutex.synchronized(() async {
      await _delegate.removeProofs(proofs: proofs, mintUrl: mintUrl);
    });
  }

  @override
  Future<List<WalletCashuProof>> getProofs({
    String? mintUrl,
    String? keysetId,
  }) async {
    return await _mutex.synchronized(() async {
      return await _delegate.getProofs(mintUrl: mintUrl, keysetId: keysetId);
    });
  }

  // delegate other methods
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return Function.apply(
      (_delegate as dynamic)[invocation.memberName],
      invocation.positionalArguments,
      invocation.namedArguments,
    );
  }

  Future<T> runInTransaction<T>(Future<T> Function() action) async {
    return await _mutex.synchronized(() async {
      return await action();
    });
  }

  Future<void> atomicSaveAndRemove({
    required List<WalletCashuProof> proofsToRemove,
    required List<WalletCashuProof> tokensToSave,
    required String mintUrl,
  }) async {
    await runInTransaction(() async {
      await _delegate.removeProofs(proofs: proofsToRemove, mintUrl: mintUrl);
      await _delegate.saveProofs(tokens: tokensToSave, mintUrl: mintUrl);
    });
  }
}
