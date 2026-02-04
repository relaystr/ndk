import 'package:ndk/data_layer/repositories/cashu/cashu_repo_impl.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_blinded_message.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_blinded_signature.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_melt_response.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_proof.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_token_state_response.dart';

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

/// Mock repo that simulates melt failure after proofs are already spent on the mint
class CashuRepoMeltFailAfterSpendMock extends CashuRepoImpl {
  CashuRepoMeltFailAfterSpendMock({required super.client});

  @override
  Future<CashuMeltResponse> meltTokens({
    required String mintUrl,
    required String quoteId,
    required List<CashuProof> proofs,
    required List<CashuBlindedMessage> outputs,
    String method = "bolt11",
  }) async {
    // Simulate that the mint received and burned the proofs, but then an error occurred
    throw Exception("Network error during melt response");
  }

  @override
  Future<List<CashuTokenStateResponse>> checkTokenState({
    required List<String> proofPubkeys,
    required String mintUrl,
  }) async {
    // Return that all proofs are spent on the mint
    return proofPubkeys
        .map((y) => CashuTokenStateResponse(
              Y: y,
              state: CashuProofState.spend,
            ))
        .toList();
  }
}
