import 'dart:convert';

import '../../../domain_layer/entities/cashu/wallet_cahsu_keyset.dart';
import '../../../domain_layer/entities/cashu/wallet_cashu_blinded_message.dart';
import '../../../domain_layer/entities/cashu/wallet_cashu_blinded_signature.dart';
import '../../../domain_layer/entities/cashu/wallet_cashu_proof.dart';
import '../../../domain_layer/entities/cashu/wallet_cashu_quote.dart';
import '../../../domain_layer/repositories/cashu_repo.dart';
import '../../../domain_layer/usecases/cashu_wallet/cashu_keypair.dart';
import '../../../domain_layer/usecases/cashu_wallet/cashu_tools.dart';
import '../../data_sources/http_request.dart';

final headers = {'Content-Type': 'application/json'};

class CashuRepoImpl implements CashuRepo {
  final HttpRequestDS client;

  CashuRepoImpl({
    required this.client,
  });
  @override
  Future<List<WalletCashuBlindedSignature>> swap({
    required String mintURL,
    required List<WalletCashuProof> proofs,
    required List<WalletCashuBlindedMessage> outputs,
  }) async {
    final url = CashuTools.composeUrl(mintUrl: mintURL, path: 'swap');

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
        .map((e) => WalletCashuBlindedSignature.fromServerMap(e))
        .toList();
  }

  @override
  Future<List<WalletCahsuKeysetResponse>> getKeysets({
    required String mintURL,
  }) async {
    final url = CashuTools.composeUrl(mintUrl: mintURL, path: 'keysets');

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
        .map((e) => WalletCahsuKeysetResponse.fromServerMap(
              map: e as Map<String, dynamic>,
              mintURL: mintURL,
            ))
        .toList();
  }

  @override
  Future<List<WalletCahsuKeysResponse>> getKeys({
    required String mintURL,
    String? keysetId,
  }) async {
    final baseUrl = CashuTools.composeUrl(mintUrl: mintURL, path: 'keys');

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
        .map((e) => WalletCahsuKeysResponse.fromServerMap(
              map: e as Map<String, dynamic>,
              mintURL: mintURL,
            ))
        .toList();
  }

  @override
  Future<WalletCashuQuote> getMintQuote({
    required String mintURL,
    required int amount,
    required String unit,
    required String method,
    String description = '',
  }) async {
    CashuKeypair quoteKey = CashuKeypair.generateCashuKeyPair();

    final url =
        CashuTools.composeUrl(mintUrl: mintURL, path: 'mint/quote/$method');

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

    return WalletCashuQuote.fromServerMap(
      map: responseBody,
      mintURL: mintURL,
      quoteKey: quoteKey,
    );
  }

  @override
  Future<CashuQuoteState> checkMintQuoteState({
    required String mintURL,
    required String quoteID,
    required String method,
  }) async {
    final url = CashuTools.composeUrl(
        mintUrl: mintURL, path: 'mint/quote/$method/$quoteID');

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
  Future<List<WalletCashuBlindedSignature>> mintTokens({
    required String mintURL,
    required String quote,
    required List<WalletCashuBlindedMessage> blindedMessagesOutputs,
    required String method,
    required CashuKeypair quoteKey,
  }) async {
    final url = CashuTools.composeUrl(mintUrl: mintURL, path: 'mint/$method');

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
        .map((e) => WalletCashuBlindedSignature.fromServerMap(e))
        .toList();
  }
}
