import '../entities/cashu/wallet_cahsu_keyset.dart';
import '../entities/cashu/wallet_cashu_blinded_message.dart';
import '../entities/cashu/wallet_cashu_blinded_signature.dart';
import '../entities/cashu/wallet_cashu_proof.dart';
import '../entities/cashu/wallet_cashu_quote.dart';
import '../entities/cashu/wallet_cashu_quote_melt.dart';
import '../usecases/cashu_wallet/cashu_keypair.dart';

abstract class CashuRepo {
  Future<List<WalletCashuBlindedSignature>> swap({
    required String mintURL,
    required List<WalletCashuProof> proofs,
    required List<WalletCashuBlindedMessage> outputs,
  });

  Future<List<WalletCahsuKeysetResponse>> getKeysets({
    required String mintURL,
  });

  Future<List<WalletCahsuKeysResponse>> getKeys({
    required String mintURL,
    String? keysetId,
  });

  Future<WalletCashuQuote> getMintQuote({
    required String mintURL,
    required int amount,
    required String unit,
    required String method,
    String description = '',
  });

  Future<CashuQuoteState> checkMintQuoteState({
    required String mintURL,
    required String quoteID,
    required String method,
  });

  Future<List<WalletCashuBlindedSignature>> mintTokens({
    required String mintURL,
    required String quote,
    required List<WalletCashuBlindedMessage> blindedMessagesOutputs,
    required String method,
    required CashuKeypair quoteKey,
  });

  /// [mintURL] is the URL of the mint \
  /// [request] is usually a lightning invoice \
  /// [unit] is usually 'sat' \
  /// [method] is usually 'bolt11' \
  /// Returns a [WalletCashuQuoteMelt] object containing the melt quote details.
  Future<WalletCashuQuoteMelt> getMeltQuote({
    required String mintURL,
    required String request,
    required String unit,
    required String method,
  });

  /// [mintURL] is the URL of the mint \
  /// [quoteID] is the ID of the melt quote \
  /// [method] is usually 'bolt11' \
  /// Returns a [WalletCashuQuoteMelt] object containing the melt quote details.
  Future<WalletCashuQuoteMelt> checkMeltQuoteState({
    required String mintURL,
    required String quoteID,
    required String method,
  });
}
