import '../../entities/cashu/cashu_keyset.dart';
import '../../entities/cashu/cashu_mint_info.dart';
import '../../entities/cashu/cashu_proof.dart';

abstract interface class CashuStore {
  Future<void> saveKeyset(CahsuKeyset keyset);

  /// get all keysets if no mintUrl is provided \
  Future<List<CahsuKeyset>> getKeysets({String? mintUrl});

  Future<void> saveProofs({
    required List<CashuProof> proofs,
    required String mintUrl,
  });

  Future<List<CashuProof>> getProofs({
    String? mintUrl,
    String? keysetId,
    CashuProofState state = CashuProofState.unspend,
  });

  Future<void> removeProofs({
    required List<CashuProof> proofs,
    required String mintUrl,
  });

  Future<void> saveMintInfo({required CashuMintInfo mintInfo});

  Future<void> removeMintInfo({required String mintUrl});

  /// return all if no mintUrls are provided
  Future<List<CashuMintInfo>?> getMintInfos({List<String>? mintUrls});

  Future<int> getCashuSecretCounter({
    required String mintUrl,
    required String keysetId,
  });

  Future<void> setCashuSecretCounter({
    required String mintUrl,
    required String keysetId,
    required int counter,
  });
}
