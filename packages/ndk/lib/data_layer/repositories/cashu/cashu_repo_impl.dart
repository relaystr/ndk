import 'dart:convert';

import '../../../domain_layer/entities/cashu/wallet_cashu_blinded_message.dart';
import '../../../domain_layer/entities/cashu/wallet_cashu_blinded_signature.dart';
import '../../../domain_layer/entities/cashu/wallet_cashu_proof.dart';
import '../../../domain_layer/repositories/cashu_repo.dart';
import '../../../domain_layer/usecases/cashu_wallet/cashu_tools.dart';
import '../../data_sources/http_request.dart';

final headers = {'Content-Type': 'application/json'};

class CashuRepoImpl implements CashuRepo {
  final HttpRequestDS client;

  CashuRepoImpl({
    required this.client,
  });
  @override
  Future<WalletCashuBlindedSignature> swap({
    required String mintURL,
    required List<WalletCashuProof> proofs,
    required List<WalletCashuBlindedMessage> outputs,
  }) async {
    final url = CashuTools.composeUrl(mintUrl: mintURL, path: 'swap');

    final body = {
      'inputs': proofs.map((e) => e.toJson()).toList(),
      'outputs': outputs.map((e) => e.toJson()).toList(),
    };

    final response = await client.post(
      url: Uri.parse(url),
      body: jsonEncode(body),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error swapping cashu tokens: ${response.statusCode}, ${response.body}',
      );
    }

    final responseBody = jsonDecode(response.body);
    if (responseBody is! Map<String, dynamic>) {
      throw Exception('Invalid response format: $responseBody');
    }

    return WalletCashuBlindedSignature.fromServerMap(responseBody);
  }
}
