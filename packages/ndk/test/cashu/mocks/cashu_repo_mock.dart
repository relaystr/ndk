import 'package:ndk/data_layer/repositories/cashu/cashu_repo_impl.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_blinded_message.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_blinded_signature.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_proof.dart';

class CashuRepoMock extends CashuRepoImpl {
  CashuRepoMock({required super.client});

  @override
  Future<List<CashuBlindedSignature>> swap({
    required String mintUrl,
    required List<CashuProof> proofs,
    required List<CashuBlindedMessage> outputs,
  }) async {
    throw Exception("force swap to fail");
  }
}
