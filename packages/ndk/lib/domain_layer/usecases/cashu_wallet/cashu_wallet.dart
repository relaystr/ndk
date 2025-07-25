import '../../../config/cashu_config.dart';
import '../../entities/cashu/wallet_cashu_blinded_message.dart';
import '../../entities/cashu/wallet_cashu_proof.dart';
import '../../entities/cashu/wallet_cashu_quote.dart';
import '../../entities/cashu/wallet_cashu_token.dart';
import '../../repositories/cache_manager.dart';
import '../../repositories/cashu_repo.dart';
import 'cashu_bdhke.dart';
import 'cashu_keysets.dart';

import 'cashu_token_encoder.dart';
import 'cashu_tools.dart';

class CashuWallet {
  final CashuRepo _cashuRepo;
  final CacheManager _cacheManager;

  late final CashuKeysets _cashuKeysets;
  CashuWallet({
    required CashuRepo cashuRepo,
    required CacheManager cacheManager,
  })  : _cashuRepo = cashuRepo,
        _cacheManager = cacheManager {
    _cashuKeysets = CashuKeysets(
      cashuRepo: _cashuRepo,
      cacheManager: _cacheManager,
    );
  }

  // final Set<Transaction> _transactions = {};

  // final Set<Mint> _mints = {};

  // final Set<Proof> _proofs = {};

  // final Set<Pending> _pending = {};

  getBalance({required String unit}) {}

  /// funds the wallet (usually with lightning) and get ecash
  Future<List<WalletCashuProof>> fund({
    required String mintURL,
    required int amount,
    required String unit,
    required String method,
  }) async {
    final keysets = await _cashuKeysets.getKeysetsFromMint(mintURL);

    if (keysets.isEmpty) {
      throw Exception('No keysets found for mint: $mintURL');
    }

    final keyset = CashuTools.findActiveKeyset(keysets);

    if (keyset == null) {
      throw Exception('No active keyset found for mint: $mintURL');
    }

    final quote = await _cashuRepo.getMintQuote(
      mintURL: mintURL,
      amount: amount,
      unit: unit,
      method: method,
    );

    CashuQuoteState payStatus;

    while (true) {
      payStatus = await _cashuRepo.checkMintQuoteState(
        mintURL: mintURL,
        quoteID: quote.quoteId,
        method: method,
      );

      if (payStatus == CashuQuoteState.paid) {
        break;
      }

      // check if quote has expired
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (currentTime >= quote.expiry) {
        throw Exception('Quote expired before payment was received');
      }
      await Future.delayed(CashuConfig.FUNDING_CHECK_INTERVAL);
    }

    List<int> splittedAmounts = CashuTools.splitAmount(amount);
    final blindedMessagesOutputs = CashuBdhke.createBlindedMsgForAmounts(
      keysetId: keyset.id,
      amounts: splittedAmounts,
    );

    final mintResponse = await _cashuRepo.mintTokens(
      mintURL: mintURL,
      quote: quote.quoteId,
      blindedMessagesOutputs: blindedMessagesOutputs
          .map(
            (e) => WalletCashuBlindedMessage(
                amount: e.amount,
                id: e.blindedMessage.id,
                blindedMessage: e.blindedMessage.blindedMessage),
          )
          .toList(),
      method: method,
      quoteKey: quote.quoteKey,
    );

    if (mintResponse.isEmpty) {
      throw Exception('Minting failed, no signatures returned');
    }

    // unblind

    final unblindedTokens = CashuBdhke.unblindSignatures(
      mintSignatures: mintResponse,
      blindedMessages: blindedMessagesOutputs,
      mintPublicKeys: keyset,
      keysetId: keyset.id,
    );
    if (unblindedTokens.isEmpty) {
      throw Exception('Unblinding failed, no tokens returned');
    }
    await _cacheManager.saveProofs(
      tokens: unblindedTokens,
      mintUrl: mintURL,
    );

    return unblindedTokens;
  }

  /// redeem toke for x (usually with lightning)
  redeem() {}

  /// send token to user
  spend() {}

  /// accept token from user
  Future<List<WalletCashuProof>> receive(String token) async {
    final rcvToken = CashuTokenEncoder.decodedToken(token);
    if (rcvToken == null) {
      throw Exception('Invalid Cashu token format');
    }

    if (rcvToken.proofs.isEmpty) {
      throw Exception('No proofs found in the Cashu token');
    }

    final keysets = await _cashuKeysets.getKeysetsFromMint(rcvToken.mintUrl);

    if (keysets.isEmpty) {
      throw Exception('No keysets found for mint: ${rcvToken.mintUrl}');
    }

    final keyset = CashuTools.findActiveKeyset(keysets);

    if (keyset == null) {
      throw Exception('No active keyset found for mint: ${rcvToken.mintUrl}');
    }

    final rcvSum = CashuTools.sumOfProofs(proofs: rcvToken.proofs);

    List<int> splittedAmounts = CashuTools.splitAmount(rcvSum);
    final blindedMessagesOutputs = CashuBdhke.createBlindedMsgForAmounts(
      keysetId: keyset.id,
      amounts: splittedAmounts,
    );

    final myBlindedSingatures = await _cashuRepo.swap(
      mintURL: rcvToken.mintUrl,
      proofs: rcvToken.proofs,
      outputs: blindedMessagesOutputs
          .map(
            (e) => WalletCashuBlindedMessage(
              amount: e.amount,
              id: e.blindedMessage.id,
              blindedMessage: e.blindedMessage.blindedMessage,
            ),
          )
          .toList(),
    );

    // unblind
    final myUnblindedTokens = CashuBdhke.unblindSignatures(
      mintSignatures: myBlindedSingatures,
      blindedMessages: blindedMessagesOutputs,
      mintPublicKeys: keyset,
      keysetId: keyset.id,
    );

    if (myUnblindedTokens.isEmpty) {
      throw Exception('Unblinding failed, no tokens returned');
    }

    // check if we recived our own proofs
    final ownTokens = await _cacheManager.getProofs(mintUrl: rcvToken.mintUrl);

    final sameSendRcv = rcvToken.proofs
        .where((e) => ownTokens.any((ownToken) => ownToken.secret == e.secret))
        .toList();

    for (final dublicate in sameSendRcv) {
      await _cacheManager.removeProof(
        proof: dublicate,
        mintUrl: rcvToken.mintUrl,
      );
    }

    // save new proofs
    await _cacheManager.saveProofs(
      tokens: myUnblindedTokens,
      mintUrl: rcvToken.mintUrl,
    );

    return myUnblindedTokens;
  }

  String proofsToToken({
    required List<WalletCashuProof> proofs,
    required String mintUrl,
    required String unit,
    String memo = "",
  }) {
    if (proofs.isEmpty) {
      throw Exception('No proofs provided for token conversion');
    }
    final cashuToken = WalletCashuToken(
      proofs: proofs,
      mintUrl: mintUrl,
      memo: memo,
      unit: unit,
    );
    return cashuToken.toV4TokenString();
  }
}
