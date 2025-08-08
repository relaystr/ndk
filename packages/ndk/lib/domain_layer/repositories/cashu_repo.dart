import '../entities/cashu/cashu_keyset.dart';
import '../entities/cashu/cashu_blinded_message.dart';
import '../entities/cashu/cashu_blinded_signature.dart';
import '../entities/cashu/cashu_melt_response.dart';
import '../entities/cashu/cashu_proof.dart';
import '../entities/cashu/cashu_quote.dart';
import '../entities/cashu/cashu_quote_melt.dart';
import '../usecases/cashu_wallet/cashu_keypair.dart';

abstract class CashuRepo {
  Future<List<CashuBlindedSignature>> swap({
    required String mintUrl,
    required List<CashuProof> proofs,
    required List<CashuBlindedMessage> outputs,
  });

  Future<List<CahsuKeysetResponse>> getKeysets({
    required String mintUrl,
  });

  Future<List<CahsuKeysResponse>> getKeys({
    required String mintUrl,
    String? keysetId,
  });

  Future<CashuQuote> getMintQuote({
    required String mintUrl,
    required int amount,
    required String unit,
    required String method,
    String description = '',
  });

  Future<CashuQuoteState> checkMintQuoteState({
    required String mintUrl,
    required String quoteID,
    required String method,
  });

  Future<List<CashuBlindedSignature>> mintTokens({
    required String mintUrl,
    required String quote,
    required List<CashuBlindedMessage> blindedMessagesOutputs,
    required String method,
    required CashuKeypair quoteKey,
  });

  /// [mintUrl] is the URL of the mint \
  /// [request] is usually a lightning invoice \
  /// [unit] is usually 'sat' \
  /// [method] is usually 'bolt11' \
  /// Returns a [CashuQuoteMelt] object containing the melt quote details.
  Future<CashuQuoteMelt> getMeltQuote({
    required String mintUrl,
    required String request,
    required String unit,
    required String method,
  });

  /// [mintUrl] is the URL of the mint \
  /// [quoteID] is the ID of the melt quote \
  /// [method] is usually 'bolt11' \
  /// Returns a [CashuQuoteMelt] object containing the melt quote details.
  Future<CashuQuoteMelt> checkMeltQuoteState({
    required String mintUrl,
    required String quoteID,
    required String method,
  });

  /// [mintUrl] is the URL of the mint \
  /// [quoteId] is the ID of the melt quote \
  /// [proofs] is a list of [CashuProof] inputs \
  /// [outputs] is a list of blank! [CashuBlindedMessage] outputs \
  /// Returns a [CashuMeltResponse] object containing the melt response details.
  Future<CashuMeltResponse> meltTokens({
    required String mintUrl,
    required String quoteId,
    required List<CashuProof> proofs,
    required List<CashuBlindedMessage> outputs,
    required String method,
  });
}
