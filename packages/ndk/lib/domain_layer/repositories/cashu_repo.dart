import '../entities/cashu/wallet_cashu_blinded_message.dart';
import '../entities/cashu/wallet_cashu_blinded_signature.dart';
import '../entities/cashu/wallet_cashu_proof.dart';

abstract class CashuRepo {
  Future<List<WalletCashuBlindedSignature>> swap({
    required String mintURL,
    required List<WalletCashuProof> proofs,
    required List<WalletCashuBlindedMessage> outputs,
  });
}
