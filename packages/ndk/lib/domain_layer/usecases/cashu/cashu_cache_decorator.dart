import 'dart:async';

import '../../../shared/helpers/mutex_simple.dart';
import '../../entities/cashu/cashu_keyset.dart';
import '../../entities/cashu/cashu_mint_info.dart';
import '../../entities/cashu/cashu_proof.dart';
import '../../entities/cache_eviction.dart';
import '../../entities/event_cache_records.dart';
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
  Future<List<CashuMintInfo>?> getMintInfos({
    List<String>? mintUrls,
  }) async {
    return await _mutex.synchronized(() async {
      return await _delegate.getMintInfos(mintUrls: mintUrls);
    });
  }

  @override
  Future<void> saveProofs({
    required List<CashuProof> proofs,
    required String mintUrl,
  }) async {
    await _mutex.synchronized(() async {
      await _delegate.saveProofs(proofs: proofs, mintUrl: mintUrl);
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
    CashuProofState state = CashuProofState.unspend,
  }) async {
    return await _mutex.synchronized(() async {
      return await _delegate.getProofs(
        mintUrl: mintUrl,
        keysetId: keysetId,
        state: state,
      );
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
  Future<void> saveMintInfo({
    required CashuMintInfo mintInfo,
  }) async {
    await _mutex.synchronized(() async {
      await _delegate.saveMintInfo(mintInfo: mintInfo);
    });
  }

  @override
  Future<void> removeMintInfo({
    required String mintUrl,
  }) async {
    await _mutex.synchronized(() async {
      await _delegate.removeMintInfo(mintUrl: mintUrl);
    });
  }

  @override
  Future<int> getCashuSecretCounter({
    required String mintUrl,
    required String keysetId,
  }) async {
    return await _mutex.synchronized(() async {
      return await _delegate.getCashuSecretCounter(
        mintUrl: mintUrl,
        keysetId: keysetId,
      );
    });
  }

  @override
  Future<void> setCashuSecretCounter({
    required String mintUrl,
    required String keysetId,
    required int counter,
  }) async {
    await _mutex.synchronized(() async {
      await _delegate.setCashuSecretCounter(
        mintUrl: mintUrl,
        keysetId: keysetId,
        counter: counter,
      );
    });
  }

  @override
  Future<void> saveDecryptedEventPayloadRecord(
    DecryptedEventPayloadRecord record,
  ) async {
    await _mutex.synchronized(() async {
      await _delegate.saveDecryptedEventPayloadRecord(record);
    });
  }

  @override
  Future<void> saveDecryptedEventPayloadRecords(
    List<DecryptedEventPayloadRecord> records,
  ) async {
    await _mutex.synchronized(() async {
      await _delegate.saveDecryptedEventPayloadRecords(records);
    });
  }

  @override
  Future<DecryptedEventPayloadRecord?> loadDecryptedEventPayloadRecord({
    required String eventId,
    required String viewerPubKey,
  }) async {
    return _mutex.synchronized(() async {
      return _delegate.loadDecryptedEventPayloadRecord(
        eventId: eventId,
        viewerPubKey: viewerPubKey,
      );
    });
  }

  @override
  Future<List<DecryptedEventPayloadRecord>> loadDecryptedEventPayloadRecords({
    String? eventId,
    String? viewerPubKey,
    DecryptedPayloadStatus? status,
    int? limit,
  }) async {
    return _mutex.synchronized(() async {
      return _delegate.loadDecryptedEventPayloadRecords(
        eventId: eventId,
        viewerPubKey: viewerPubKey,
        status: status,
        limit: limit,
      );
    });
  }

  @override
  Future<void> removeDecryptedEventPayloadRecord({
    required String eventId,
    required String viewerPubKey,
  }) async {
    await _mutex.synchronized(() async {
      await _delegate.removeDecryptedEventPayloadRecord(
        eventId: eventId,
        viewerPubKey: viewerPubKey,
      );
    });
  }

  @override
  Future<void> removeDecryptedEventPayloadRecords(String eventId) async {
    await _mutex.synchronized(() async {
      await _delegate.removeDecryptedEventPayloadRecords(eventId);
    });
  }

  @override
  Future<void> removeAllDecryptedEventPayloadRecords() async {
    await _mutex.synchronized(() async {
      await _delegate.removeAllDecryptedEventPayloadRecords();
    });
  }

  @override
  Future<EvictionResult> evict(EvictionPolicy policy) async {
    return _mutex.synchronized(() async {
      return _delegate.evict(policy);
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
      await _delegate.saveProofs(proofs: tokensToSave, mintUrl: mintUrl);
    });
  }

  Future<int> getAndIncrementDerivationCounter({
    required String keysetId,
    required String mintUrl,
  }) async {
    return await runInTransaction(() async {
      final currentValue = await _delegate.getCashuSecretCounter(
        mintUrl: mintUrl,
        keysetId: keysetId,
      );
      final newValue = currentValue + 1;
      await _delegate.setCashuSecretCounter(
        mintUrl: mintUrl,
        keysetId: keysetId,
        counter: newValue,
      );

      return currentValue;
    });
  }

  Future<void> setDerivationCounter({
    required String keysetId,
    required String mintUrl,
    required int counter,
  }) async {
    await _delegate.setCashuSecretCounter(
      mintUrl: mintUrl,
      keysetId: keysetId,
      counter: counter,
    );
  }
}
