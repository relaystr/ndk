import '../entities/cashu/wallet_cashu_keyset.dart';
import '../entities/cashu/wallet_cashu_blinded_message.dart';
import '../entities/cashu/wallet_cashu_blinded_signature.dart';
import '../entities/cashu/wallet_cashu_melt_response.dart';
import '../entities/cashu/wallet_cashu_proof.dart';
import '../entities/cashu/wallet_cashu_quote.dart';
import '../entities/cashu/wallet_cashu_quote_melt.dart';
import '../usecases/cashu_wallet/cashu_keypair.dart';

abstract class CashuRepo {
  Future<List<WalletCashuBlindedSignature>> swap({
    required String mintUrl,
    required List<WalletCashuProof> proofs,
    required List<WalletCashuBlindedMessage> outputs,
  });

  Future<List<WalletCahsuKeysetResponse>> getKeysets({
    required String mintUrl,
  });

  Future<List<WalletCahsuKeysResponse>> getKeys({
    required String mintUrl,
    String? keysetId,
  });

  Future<WalletCashuQuote> getMintQuote({
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

  Future<List<WalletCashuBlindedSignature>> mintTokens({
    required String mintUrl,
    required String quote,
    required List<WalletCashuBlindedMessage> blindedMessagesOutputs,
    required String method,
    required CashuKeypair quoteKey,
  });

  /// [mintUrl] is the URL of the mint \
  /// [request] is usually a lightning invoice \
  /// [unit] is usually 'sat' \
  /// [method] is usually 'bolt11' \
  /// Returns a [WalletCashuQuoteMelt] object containing the melt quote details.
  Future<WalletCashuQuoteMelt> getMeltQuote({
    required String mintUrl,
    required String request,
    required String unit,
    required String method,
  });

  /// [mintUrl] is the URL of the mint \
  /// [quoteID] is the ID of the melt quote \
  /// [method] is usually 'bolt11' \
  /// Returns a [WalletCashuQuoteMelt] object containing the melt quote details.
  Future<WalletCashuQuoteMelt> checkMeltQuoteState({
    required String mintUrl,
    required String quoteID,
    required String method,
  });

  /// [mintUrl] is the URL of the mint \
  /// [quoteId] is the ID of the melt quote \
  /// [proofs] is a list of [WalletCashuProof] inputs \
  /// [outputs] is a list of blank! [WalletCashuBlindedMessage] outputs \
  /// Returns a [WalletCashuMeltResponse] object containing the melt response details.
  Future<WalletCashuMeltResponse> meltTokens({
    required String mintUrl,
    required String quoteId,
    required List<WalletCashuProof> proofs,
    required List<WalletCashuBlindedMessage> outputs,
    required String method,
  });
}
