import 'dart:convert';

import '../../../domain_layer/entities/cashu/cashu_keyset.dart';
import '../../../domain_layer/entities/cashu/cashu_blinded_message.dart';
import '../../../domain_layer/entities/cashu/cashu_blinded_signature.dart';
import '../../../domain_layer/entities/cashu/cashu_melt_response.dart';
import '../../../domain_layer/entities/cashu/cashu_mint_info.dart';
import '../../../domain_layer/entities/cashu/cashu_proof.dart';
import '../../../domain_layer/entities/cashu/cashu_quote.dart';
import '../../../domain_layer/entities/cashu/cashu_quote_melt.dart';
import '../../../domain_layer/entities/cashu/cashu_token_state_response.dart';
import '../../../domain_layer/repositories/cashu_repo.dart';
import '../../../domain_layer/usecases/cashu/cashu_keypair.dart';
import '../../../domain_layer/usecases/cashu/cashu_tools.dart';
import '../../data_sources/http_request.dart';

final headers = {'Content-Type': 'application/json'};

class CashuRepoImpl implements CashuRepo {
  final HttpRequestDS client;

  CashuRepoImpl({
    required this.client,
  });
  @override
  Future<List<CashuBlindedSignature>> swap({
    required String mintUrl,
    required List<CashuProof> proofs,
    required List<CashuBlindedMessage> outputs,
  }) async {
    final url = CashuTools.composeUrl(mintUrl: mintUrl, path: 'swap');

    outputs.sort((a, b) => a.amount.compareTo(b.amount));

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

    final List<dynamic> signaturesUnparsed = responseBody['signatures'];

    if (signaturesUnparsed.isEmpty) {
      throw Exception('No signatures returned from swap');
    }

    return signaturesUnparsed
        .map((e) => CashuBlindedSignature.fromServerMap(e))
        .toList();
  }

  @override
  Future<List<CahsuKeysetResponse>> getKeysets({
    required String mintUrl,
  }) async {
    final url = CashuTools.composeUrl(mintUrl: mintUrl, path: 'keysets');

    final response = await client.get(
      url: Uri.parse(url),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error fetching keysets: ${response.statusCode}, ${response.body}',
      );
    }
    final responseBody = jsonDecode(response.body);

    if (responseBody is! Map) {
      throw Exception('Invalid response format: $responseBody');
    }
    final List<dynamic> keysetsUnparsed = responseBody['keysets'];
    return keysetsUnparsed
        .map((e) => CahsuKeysetResponse.fromServerMap(
              map: e as Map<String, dynamic>,
              mintUrl: mintUrl,
            ))
        .toList();
  }

  @override
  Future<List<CahsuKeysResponse>> getKeys({
    required String mintUrl,
    String? keysetId,
  }) async {
    final baseUrl = CashuTools.composeUrl(mintUrl: mintUrl, path: 'keys');

    final String url;
    if (keysetId != null) {
      url = '$baseUrl/$keysetId';
    } else {
      url = baseUrl;
    }

    final response = await client.get(
      url: Uri.parse(url),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Error fetching keys: ${response.statusCode}, ${response.body}',
      );
    }
    final responseBody = jsonDecode(response.body);
    if (responseBody is! Map) {
      throw Exception('Invalid response format: $responseBody');
    }
    final List<dynamic> keysUnparsed = responseBody['keysets'];
    return keysUnparsed
        .map((e) => CahsuKeysResponse.fromServerMap(
              map: e as Map<String, dynamic>,
              mintUrl: mintUrl,
            ))
        .toList();
  }

  @override
  Future<CashuQuote> getMintQuote({
    required String mintUrl,
    required int amount,
    required String unit,
    required String method,
    String description = '',
  }) async {
    CashuKeypair quoteKey = CashuKeypair.generateCashuKeyPair();

    final url =
        CashuTools.composeUrl(mintUrl: mintUrl, path: 'mint/quote/$method');

    final body = {
      'amount': amount,
      'unit': unit,
      'description': description,
      'pubkey': quoteKey.publicKey,
    };

    final response = await client.post(
      url: Uri.parse(url),
      body: jsonEncode(body),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error getting mint quote: ${response.statusCode}, ${response.body}',
      );
    }

    final responseBody = jsonDecode(response.body);
    if (responseBody is! Map<String, dynamic>) {
      throw Exception('Invalid response format: $responseBody');
    }

    return CashuQuote.fromServerMap(
      map: responseBody,
      mintUrl: mintUrl,
      quoteKey: quoteKey,
    );
  }

  @override
  Future<CashuQuoteState> checkMintQuoteState({
    required String mintUrl,
    required String quoteID,
    required String method,
  }) async {
    final url = CashuTools.composeUrl(
        mintUrl: mintUrl, path: 'mint/quote/$method/$quoteID');

    final response = await client.get(
      url: Uri.parse(url),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error checking quote state: ${response.statusCode}, ${response.body}',
      );
    }

    final responseBody = jsonDecode(response.body);
    if (responseBody is! Map<String, dynamic>) {
      throw Exception('Invalid response format: $responseBody');
    }

    return CashuQuoteState.fromValue(
      responseBody['state'] as String,
    );
  }

  @override
  Future<List<CashuBlindedSignature>> mintTokens({
    required String mintUrl,
    required String quote,
    required List<CashuBlindedMessage> blindedMessagesOutputs,
    required String method,
    required CashuKeypair quoteKey,
  }) async {
    final url = CashuTools.composeUrl(mintUrl: mintUrl, path: 'mint/$method');

    if (blindedMessagesOutputs.isEmpty) {
      throw Exception('No outputs provided for minting');
    }

    final quoteSignature = CashuTools.createMintSignature(
      quote: quote,
      blindedMessagesOutputs: blindedMessagesOutputs,
      privateKeyHex: quoteKey.privateKey,
    );

    final body = {
      'quote': quote,
      'outputs': blindedMessagesOutputs.map((e) {
        return {
          'id': e.id,
          'amount': e.amount,
          'B_': e.blindedMessage,
        };
      }).toList(),
      "signature": quoteSignature,
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

    final List<dynamic> signaturesUnparsed = responseBody['signatures'];

    if (signaturesUnparsed.isEmpty) {
      throw Exception('No signatures returned from mint');
    }

    return signaturesUnparsed
        .map((e) => CashuBlindedSignature.fromServerMap(e))
        .toList();
  }

  @override
  Future<CashuQuoteMelt> getMeltQuote({
    required String mintUrl,
    required String request,
    required String unit,
    required String method,
  }) async {
    final url =
        CashuTools.composeUrl(mintUrl: mintUrl, path: 'melt/quote/$method');

    final body = {
      'request': request,
      'unit': unit,
    };

    final response = await client.post(
      url: Uri.parse(url),
      body: jsonEncode(body),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error getting melt quote: ${response.statusCode}, ${response.body}',
      );
    }

    return CashuQuoteMelt.fromServerMap(
      json: jsonDecode(response.body) as Map<String, dynamic>,
      mintUrl: mintUrl,
      request: request,
    );
  }

  @override
  Future<CashuQuoteMelt> checkMeltQuoteState({
    required String mintUrl,
    required String quoteID,
    required String method,
  }) async {
    final url = CashuTools.composeUrl(
        mintUrl: mintUrl, path: 'melt/quote/$method/$quoteID');

    final response = await client.get(
      url: Uri.parse(url),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error checking quote state: ${response.statusCode}, ${response.body}',
      );
    }

    final responseBody = jsonDecode(response.body);
    if (responseBody is! Map<String, dynamic>) {
      throw Exception('Invalid response format: $responseBody');
    }

    return CashuQuoteMelt.fromServerMap(
      json: responseBody,
      mintUrl: mintUrl,
    );
  }

  @override
  Future<CashuMeltResponse> meltTokens({
    required String mintUrl,
    required String quoteId,
    required List<CashuProof> proofs,
    required List<CashuBlindedMessage> outputs,
    String method = 'bolt11',
  }) async {
    final body = {
      'quote': quoteId,
      'inputs': proofs.map((e) => e.toJson()).toList(),
      'outputs': outputs.map((e) => e.toJson()).toList()
    };
    final url = CashuTools.composeUrl(mintUrl: mintUrl, path: 'melt/$method');

    final response = await client.post(
      url: Uri.parse(url),
      body: jsonEncode(body),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error melting cashu tokens: ${response.statusCode}, ${response.body}',
      );
    }
    final responseBody = jsonDecode(response.body);
    if (responseBody is! Map<String, dynamic>) {
      throw Exception('Invalid response format: $responseBody');
    }
    return CashuMeltResponse.fromServerMap(
      map: responseBody,
      mintUrl: mintUrl,
      quoteId: quoteId,
    );
  }

  @override
  Future<CashuMintInfo> getMintInfo({required String mintUrl}) {
    final url = CashuTools.composeUrl(mintUrl: mintUrl, path: 'info');

    return client
        .get(
      url: Uri.parse(url),
      headers: headers,
    )
        .then((response) {
      if (response.statusCode != 200) {
        throw Exception(
          'Error fetching mint info: ${response.statusCode}, ${response.body}',
        );
      }
      final responseBody = jsonDecode(response.body);
      if (responseBody is! Map<String, dynamic>) {
        throw Exception('Invalid response format: $responseBody');
      }
      return CashuMintInfo.fromJson(responseBody, mintUrl: mintUrl);
    });
  }

  @override
  Future<List<CashuTokenStateResponse>> checkTokenState({
    required List<String> proofPubkeys,
    required String mintUrl,
  }) async {
    final url = CashuTools.composeUrl(mintUrl: mintUrl, path: 'checkstate');

    final body = {
      'Ys': proofPubkeys,
    };
    final response = await client.post(
      url: Uri.parse(url),
      body: jsonEncode(body),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Error checking token state: ${response.statusCode}, ${response.body}',
      );
    }
    final responseBody = jsonDecode(response.body);
    if (responseBody is! Map<String, dynamic>) {
      throw Exception('Invalid response format: $responseBody');
    }
    final List<dynamic> statesUnparsed = responseBody['states'];
    if (statesUnparsed.isEmpty) {
      throw Exception('No states returned from check state');
    }

    return statesUnparsed
        .map((e) => CashuTokenStateResponse.fromServerMap(
              e as Map<String, dynamic>,
            ))
        .toList();
  }
}
