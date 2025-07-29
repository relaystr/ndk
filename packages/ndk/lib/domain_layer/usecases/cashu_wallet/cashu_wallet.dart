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

    final keyset = CashuTools.filterKeysetsByUnitActive(
      keysets: keysets,
      unit: unit,
    );

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

  /// redeem token for x (usually lightning)
  /// [mintURL] - URL of the mint
  /// [request] - the method request to redeem (like lightning invoice)
  /// [unit] - the unit of the token (sat)
  /// [method] - the method to use for redemption (bolt11)
  Future redeem({
    required String mintURL,
    required String request,
    required String unit,
    required String method,
  }) async {
    final meltQuote = await _cashuRepo.getMeltQuote(
      mintURL: mintURL,
      request: request,
      unit: unit,
      method: method,
    );
    final feeReserve = meltQuote.feeReserve;

    final proofsUnfiltered = await _cacheManager.getProofs(
      mintUrl: mintURL,
    );
    final proofs =
        CashuTools.filterProofsByUnit(proofs: proofsUnfiltered, unit: unit);

    if (proofs.isEmpty) {
      throw Exception('No proofs found for mint: $mintURL and unit: $unit');
    }

    final int amountToSpend;

    // todo: add mint fees

    if (feeReserve != null) {
      amountToSpend = meltQuote.amount + feeReserve;
    } else {
      amountToSpend = meltQuote.amount;
    }

    final mintKeysets = await _cashuKeysets.getKeysetsFromMint(mintURL);
    if (mintKeysets.isEmpty) {
      throw Exception('No keysets found for mint: $mintURL');
    }

    final keysetsForUnit =
        CashuTools.filterKeysetsByUnit(keysets: mintKeysets, unit: unit);

    final selectionResult = CashuWalletProofSelect.selectProofsForSpending(
      proofs: proofs,
      targetAmount: amountToSpend,
      keysets: keysetsForUnit,
    );

    final activeKeyset =
        CashuTools.filterKeysetsByUnitActive(keysets: mintKeysets, unit: unit);

    /// outputs to send to mint
    final List<WalletCashuBlindedMessageItem> myOutputs = [];

    /// we dont have the exact amount
    if (selectionResult.needsSplit) {
      final blindedMessagesOutputsOverpay =
          CashuBdhke.createBlindedMsgForAmounts(
              keysetId: activeKeyset.id,
              amounts: CashuTools.splitAmount(selectionResult.splitAmount));
      myOutputs.addAll(
        blindedMessagesOutputsOverpay,
      );
    }

    /// blank outputs for (lightning) fee reserve
    if (meltQuote.feeReserve != null) {
      final numBlankOutputs =
          CashuTools.calculateNumberOfBlankOutputs(meltQuote.feeReserve!);

      final blankOutputs = CashuBdhke.createBlindedMsgForAmounts(
        keysetId: activeKeyset.id,
        amounts: List.generate(numBlankOutputs, (_) => 0),
      );
      myOutputs.addAll(blankOutputs);
    }

    // todo communicate with user to check if everything is ok (fees, overpay, etc)

    final meltResult = await _cashuRepo.meltTokens(
      mintURL: mintURL,
      quoteId: meltQuote.quoteId,
      proofs: selectionResult.selectedProofs,
      outputs: myOutputs
          .map(
            (e) => WalletCashuBlindedMessage(
              amount: e.amount,
              id: e.blindedMessage.id,
              blindedMessage: e.blindedMessage.blindedMessage,
            ),
          )
          .toList(),
      method: method,
    );

    /// remove used proofs
    await _cacheManager.removeProofs(
      proofs: selectionResult.selectedProofs,
      mintUrl: mintURL,
    );

    /// save change proofs if any
    if (meltResult.change.isNotEmpty) {
      /// unblind change proofs
      final changeUnblinded = CashuBdhke.unblindSignatures(
        mintSignatures: meltResult.change,
        blindedMessages: myOutputs,
        mintPublicKeys: activeKeyset,
      );

      await _cacheManager.saveProofs(
        tokens: changeUnblinded,
        mintUrl: mintURL,
      );
    }
    return meltResult;
  }

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

    final keysetsForUnit = CashuTools.filterKeysetsByUnit(
      keysets: keysets,
      unit: unit,
    );

    final proofs = await _cacheManager.getProofs(mintUrl: mint);
    if (proofs.isEmpty) {
      throw Exception('No proofs found for mint: $mint');
    }

    final selectionResult = CashuWalletProofSelect.selectProofsForSpending(
        proofs: proofs, targetAmount: amount, keysets: keysetsForUnit);

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
        keysets: keysetsForUnit,
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

    final keyset = CashuTools.filterKeysetsByUnitActive(
      keysets: keysets,
      unit: rcvToken.unit,
    );

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
