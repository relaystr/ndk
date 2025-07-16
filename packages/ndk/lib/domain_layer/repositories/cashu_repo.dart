import '../entities/cashu/wallet_cashu_blinded_message.dart';
import '../entities/cashu/wallet_cashu_proof.dart';

abstract class CashuRepo {
  Future swap({
    required String mintURL,
    required List<WalletCashuProof> proofs,
    required List<WalletCashuBlindedMessage> outputs,
  });
}
