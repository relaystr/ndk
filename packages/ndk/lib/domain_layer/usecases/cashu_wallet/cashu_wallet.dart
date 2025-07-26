import '../../../config/cashu_config.dart';
import '../../../shared/logger/logger.dart';
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
import 'cashu_wallet_proof_select.dart';

class CashuWallet {
  final CashuRepo _cashuRepo;
  final CacheManager _cacheManager;

  late final CashuKeysets _cashuKeysets;
  late final CashuWalletProofSelect _cashuWalletProofSelect;
  CashuWallet({
    required CashuRepo cashuRepo,
    required CacheManager cacheManager,
  })  : _cashuRepo = cashuRepo,
        _cacheManager = cacheManager {
    _cashuKeysets = CashuKeysets(
      cashuRepo: _cashuRepo,
      cacheManager: _cacheManager,
    );
    _cashuWalletProofSelect = CashuWalletProofSelect(
      cashuRepo: _cashuRepo,
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
  Future<List<WalletCashuProof>> spend({
    required String mint,
    required int amount,
    required String unit,
  }) async {
    if (amount <= 0) {
      throw Exception('Amount must be greater than zero');
    }

    final keysets = await _cashuKeysets.getKeysetsFromMint(mint);
    if (keysets.isEmpty) {
      throw Exception('No keysets found for mint: $mint');
    }

    // filter unit
    final keysetsFiltered =
        keysets.where((keyset) => keyset.unit == unit).toList();

    if (keysetsFiltered.isEmpty) {
      throw Exception('No keysets found for mint: $mint with unit: $unit');
    }

    final keyset = CashuTools.findActiveKeyset(keysetsFiltered);
    if (keyset == null) {
      throw Exception('No active keyset found for mint: $mint');
    }

    final proofs = await _cacheManager.getProofs(mintUrl: mint);
    if (proofs.isEmpty) {
      throw Exception('No proofs found for mint: $mint');
    }

    final selectionResult =
        CashuWalletProofSelect.selectProofsForSpending(proofs, amount);

    if (selectionResult.selectedProofs.isEmpty) {
      throw Exception('Not enough funds to spend the requested amount');
    }

    if (selectionResult.needsSplit) {
      Logger.log.d(
          'Need to split ${selectionResult.splitAmount} $unit from ${selectionResult.totalSelected} total');

      // split to get exact change
      final splitResult = await _cashuWalletProofSelect.performSplit(
        mint: mint,
        proofsToSplit: selectionResult.selectedProofs,
        targetAmount: amount,
        changeAmount: selectionResult.splitAmount,
        keyset: keyset,
      );

      await _cacheManager.removeProofs(
        proofs: selectionResult.selectedProofs,
        mintUrl: mint,
      );
      // save change proofs
      await _cacheManager.saveProofs(
        tokens: splitResult.changeProofs,
        mintUrl: mint,
      );

      return splitResult.exactProofs;
    } else {
      Logger.log.d('No split needed, using selected proofs directly');
      await _cacheManager.removeProofs(
        proofs: selectionResult.selectedProofs,
        mintUrl: mint,
      );
      return selectionResult.selectedProofs;
    }
  }

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

    await _cacheManager.removeProofs(
      proofs: sameSendRcv,
      mintUrl: rcvToken.mintUrl,
    );

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
