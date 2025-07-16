import '../../../domain_layer/entities/cashu/wallet_cashu_blinded_message.dart';
import '../../../domain_layer/entities/cashu/wallet_cashu_proof.dart';
import '../../../domain_layer/repositories/cashu_repo.dart';
import '../../data_sources/http_request.dart';

class CashuRepoImpl implements CashuRepo {
  final HttpRequestDS client;

  CashuRepoImpl({
    required this.client,
  });
  @override
  Future swap({
    required String mintURL,
    required List<WalletCashuProof> proofs,
    required List<WalletCashuBlindedMessage> outputs,
  }) {}
}
