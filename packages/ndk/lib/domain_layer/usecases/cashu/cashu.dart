import 'package:rxdart/rxdart.dart';

import '../../../config/cashu_config.dart';
import '../../../shared/logger/logger.dart';
import '../../../shared/nips/nip01/helpers.dart';
import '../../entities/cashu/cashu_blinded_message.dart';
import '../../entities/cashu/cashu_mint_balance.dart';
import '../../entities/cashu/cashu_mint_info.dart';
import '../../entities/cashu/cashu_proof.dart';
import '../../entities/cashu/cashu_quote.dart';
import '../../entities/cashu/cashu_token.dart';
import '../../entities/wallet/wallet_transaction.dart';
import '../../entities/wallet/wallet_type.dart';
import '../../repositories/cache_manager.dart';
import '../../repositories/cashu_repo.dart';
import 'cashu_bdhke.dart';
import 'cashu_cache_decorator.dart';
import 'cashu_keysets.dart';

import 'cashu_token_encoder.dart';
import 'cashu_tools.dart';
import 'cashu_proof_select.dart';

class Cashu {
  final CashuRepo _cashuRepo;
  final CacheManager _cacheManager;
  late final CashuCacheDecorator _cacheManagerCashu;

  late final CashuKeysets _cashuKeysets;
  late final CashuProofSelect _cashuWalletProofSelect;
  Cashu({
    required CashuRepo cashuRepo,
    required CacheManager cacheManager,
  })  : _cashuRepo = cashuRepo,
        _cacheManager = cacheManager {
    _cashuKeysets = CashuKeysets(
      cashuRepo: _cashuRepo,
      cacheManager: _cacheManager,
    );
    _cashuWalletProofSelect = CashuProofSelect(
      cashuRepo: _cashuRepo,
    );
    _cacheManagerCashu = CashuCacheDecorator(cacheManager: _cacheManager);
  }

  /// mints this usecase has interacted with \
  ///? does not mark trusted mints!
  final Set<CashuMintInfo> _knownMints = {};

  BehaviorSubject<Set<CashuMintInfo>>? _knownMintsSubject;

  final List<CashuWalletTransaction> _latestTransactions = [];

  BehaviorSubject<List<CashuWalletTransaction>>? _latestTransactionsSubject;

  final Set<CashuWalletTransaction> _pendingTransactions = {};
  final BehaviorSubject<List<CashuWalletTransaction>>
      _pendingTransactionsSubject =
      BehaviorSubject<List<CashuWalletTransaction>>.seeded([]);

  /// stream of balances \
  BehaviorSubject<List<CashuMintBalance>>? _balanceSubject;

  Future<int> getBalanceMintUnit({
    required String unit,
    required String mintUrl,
  }) async {
    final proofs = await _cacheManager.getProofs(mintUrl: mintUrl);
    final filteredProofs = CashuTools.filterProofsByUnit(
      proofs: proofs,
      unit: unit,
      keysets: await _cashuKeysets.getKeysetsFromMint(mintUrl),
    );

    return CashuTools.sumOfProofs(proofs: filteredProofs);
  }

  /// get balances for all mints \
  Future<List<CashuMintBalance>> getBalances() async {
    final allProofs = await _cacheManagerCashu.getProofs();
    final allKeysets = await _cacheManagerCashu.getKeysets();
    // {"mintUrl": {unit: balance}}
    final balances = <String, Map<String, int>>{};

    final distinctKeysetIds = allKeysets.map((keyset) => keyset.id).toSet();

    for (final keysetId in distinctKeysetIds) {
      final mintUrl =
          allKeysets.firstWhere((keyset) => keyset.id == keysetId).mintUrl;
      if (!balances.containsKey(mintUrl)) {
        balances[mintUrl] = {};
      }

      final keysetProofs =
          allProofs.where((proof) => proof.keysetId == keysetId).toList();

      if (keysetProofs.isEmpty) continue;

      final unit =
          allKeysets.firstWhere((keyset) => keyset.id == keysetId).unit;
      final totalBalance = CashuTools.sumOfProofs(
        proofs: keysetProofs,
      );

      if (totalBalance > 0) {
        balances[mintUrl]![unit] = totalBalance;
      }
    }
    final mintBalances = balances.entries
        .map((entry) => CashuMintBalance(
              mintUrl: entry.key,
              balances: entry.value,
            ))
        .toList();
    return mintBalances;
  }

  Future<void> _updateBalances() async {
    final balances = await getBalances();
    _balanceSubject ??=
        BehaviorSubject<List<CashuMintBalance>>.seeded(balances);
    _balanceSubject!.add(balances);
  }

  /// list of balances for all mints
  BehaviorSubject<List<CashuMintBalance>> get balances {
    if (_balanceSubject == null) {
      _balanceSubject = BehaviorSubject<List<CashuMintBalance>>.seeded([]);

      getBalances().then((balances) {
        _balanceSubject?.add(balances);
      }).catchError((error) {
        _balanceSubject?.addError(error);
      });
    }

    return _balanceSubject!;
  }

  /// list of the latest transactions
  BehaviorSubject<List<CashuWalletTransaction>> get latestTransactions {
    if (_latestTransactionsSubject == null) {
      _latestTransactionsSubject =
          BehaviorSubject<List<CashuWalletTransaction>>.seeded(
        _latestTransactions,
      );
      _getLatestTransactionsDb().then((transactions) {
        _latestTransactions.clear();
        _latestTransactions.addAll(transactions);
        _latestTransactionsSubject?.add(_latestTransactions);
      }).catchError((error) {
        _latestTransactionsSubject?.addError(
          Exception('Failed to load latest transactions: $error'),
        );
      });
    }

    return _latestTransactionsSubject!;
  }

  /// pending transactions that are not yet completed \
  /// e.g. funding transactions
  BehaviorSubject<List<CashuWalletTransaction>> get pendingTransactions {
    return _pendingTransactionsSubject;
  }

  /// mints this usecase has interacted with \
  ///? does not mark trusted mints!
  BehaviorSubject<Set<CashuMintInfo>> get knownMints {
    if (_knownMintsSubject == null) {
      _knownMintsSubject = BehaviorSubject<Set<CashuMintInfo>>.seeded(
        _knownMints,
      );
      _getMintInfosDb().then((mintInfos) {
        _knownMints.clear();
        _knownMints.addAll(mintInfos);
        _knownMintsSubject?.add(_knownMints);
      }).catchError((error) {
        _knownMintsSubject?.addError(
          Exception('Failed to load known mints: $error'),
        );
      });
    }

    return _knownMintsSubject!;
  }

  Future<List<CashuWalletTransaction>> _getLatestTransactionsDb({
    int limit = 10,
  }) async {
    final transactions = await _cacheManagerCashu.getTransactions(
      limit: limit,
    );

    final fTransactions =
        transactions.whereType<CashuWalletTransaction>().toList();

    return fTransactions;
  }

  Future<List<CashuMintInfo>> _getMintInfosDb() async {
    final mintInfos = await _cacheManager.getMintInfos();
    if (mintInfos == null) {
      return [];
    }
    return mintInfos;
  }

  /// check if mint is known \
  /// if not, it will be added to the known mints \
  /// Returns true if mint is known, false otherwise
  Future<bool> _checkIfMintIsKnown(String mintUrl) async {
    final mintInfos = await _cacheManager.getMintInfos(
      mintUrls: [mintUrl],
    );

    if (mintInfos == null || mintInfos.isEmpty) {
      // fetch mint info from network
      final mintInfoNetwork = await _cashuRepo.getMintInfo(mintUrl: mintUrl);

      await _cacheManager.saveMintInfo(mintInfo: mintInfoNetwork);
      _knownMints.add(mintInfoNetwork);
      _knownMintsSubject?.add(_knownMints);
      return false;
    }
    return true;
  }

  /// initiate funding e.g. minting tokens \
  /// [mintUrl] - URL of the mint to fund from \
  /// [amount] - amount to fund \
  /// [unit] - unit of the amount (e.g. sat) \
  /// [method] - payment method (e.g. bolt11) \
  /// Returns a [CashuWalletTransaction] draft transaction that can be used to track the funding process.
  /// Throws if there are no keysets available
  Future<CashuWalletTransaction> initiateFund({
    required String mintUrl,
    required int amount,
    required String unit,
    required String method,
  }) async {
    await _checkIfMintIsKnown(mintUrl);
    final keysets = await _cashuKeysets.getKeysetsFromMint(mintUrl);

    if (keysets.isEmpty) {
      throw Exception('No keysets found for mint: $mintUrl');
    }

    final keyset = CashuTools.filterKeysetsByUnitActive(
      keysets: keysets,
      unit: unit,
    );

    final quote = await _cashuRepo.getMintQuote(
      mintUrl: mintUrl,
      amount: amount,
      unit: unit,
      method: method,
    );

    CashuWalletTransaction draftTransaction = CashuWalletTransaction(
      id: quote.quoteId, //todo use a better id
      mintUrl: mintUrl,
      walletId: mintUrl,
      changeAmount: amount,
      unit: unit,
      walletType: WalletType.CASHU,
      state: WalletTransactionState.draft,
      initiatedDate: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      qoute: quote,
      usedKeysets: [keyset],
      method: method,
    );

    // add to pending transactions
    _pendingTransactions.add(draftTransaction);
    _pendingTransactionsSubject.add(_pendingTransactions.toList());

    return draftTransaction;
  }

  /// retrieve funds from a pending funding transaction \
  /// [draftTransaction] - the draft transaction from initiateFund() \
  /// Returns a stream of [CashuWalletTransaction] that emits the transaction state as it progresses.
  /// Throws if the draft transaction is missing required fields.
  Stream<CashuWalletTransaction> retriveFunds({
    required CashuWalletTransaction draftTransaction,
  }) async* {
    if (draftTransaction.qoute == null) {
      throw Exception("Quote is not available in the transaction");
    }
    if (draftTransaction.method == null) {
      throw Exception("Method is not specified in the transaction");
    }
    if (draftTransaction.usedKeysets == null) {
      throw Exception("Used keysets is not specified in the transaction");
    }
    final quote = draftTransaction.qoute!;
    final mintUrl = draftTransaction.mintUrl;

    await _checkIfMintIsKnown(mintUrl);

    CashuQuoteState payStatus;

    final pendingTransaction = draftTransaction.copyWith(
      state: WalletTransactionState.pending,
    );

    // update pending transactions
    _pendingTransactions.add(pendingTransaction);
    _pendingTransactionsSubject.add(_pendingTransactions.toList());
    yield pendingTransaction;

    while (true) {
      payStatus = await _cashuRepo.checkMintQuoteState(
        mintUrl: mintUrl,
        quoteID: quote.quoteId,
        method: draftTransaction.method!,
      );

      if (payStatus == CashuQuoteState.paid) {
        break;
      }

      // check if quote has expired
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (currentTime >= quote.expiry) {
        final expiredTransaction = pendingTransaction.copyWith(
          state: WalletTransactionState.failed,
          completionMsg: 'Quote expired before payment was received',
        );
        yield expiredTransaction;
        // remove expired transaction
        _pendingTransactions.remove(expiredTransaction);
        _pendingTransactionsSubject.add(_pendingTransactions.toList());
        Logger.log.w('Quote expired before payment was received');
        return;
      }
      await Future.delayed(CashuConfig.FUNDING_CHECK_INTERVAL);
    }

    List<int> splittedAmounts = CashuTools.splitAmount(quote.amount);
    final blindedMessagesOutputs = CashuBdhke.createBlindedMsgForAmounts(
      keysetId: draftTransaction.usedKeysets!.first.id,
      amounts: splittedAmounts,
    );

    final mintResponse = await _cashuRepo.mintTokens(
      mintUrl: mintUrl,
      quote: quote.quoteId,
      blindedMessagesOutputs: blindedMessagesOutputs
          .map(
            (e) => CashuBlindedMessage(
                amount: e.amount,
                id: e.blindedMessage.id,
                blindedMessage: e.blindedMessage.blindedMessage),
          )
          .toList(),
      method: draftTransaction.method!,
      quoteKey: quote.quoteKey,
    );

    if (mintResponse.isEmpty) {
      final failedTransaction = pendingTransaction.copyWith(
        state: WalletTransactionState.failed,
        completionMsg: 'Minting failed, no signatures returned',
      );
      // remove expired transaction
      _pendingTransactions.remove(failedTransaction);
      _pendingTransactionsSubject.add(_pendingTransactions.toList());
      yield failedTransaction;
      throw Exception('Minting failed, no signatures returned');
    }

    // unblind
    final unblindedTokens = CashuBdhke.unblindSignatures(
      mintSignatures: mintResponse,
      blindedMessages: blindedMessagesOutputs,
      mintPublicKeys: draftTransaction.usedKeysets!.first,
    );
    if (unblindedTokens.isEmpty) {
      final failedTransaction = pendingTransaction.copyWith(
        state: WalletTransactionState.failed,
        completionMsg: 'Unblinding failed, no tokens returned',
      );
      // remove expired transaction
      _pendingTransactions.remove(failedTransaction);
      _pendingTransactionsSubject.add(_pendingTransactions.toList());
      yield failedTransaction;
      throw Exception('Unblinding failed, no tokens returned');
    }
    await _cacheManagerCashu.saveProofs(
      proofs: unblindedTokens,
      mintUrl: mintUrl,
    );

    final completedTransaction = pendingTransaction.copyWith(
      state: WalletTransactionState.completed,
      transactionDate: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    // update balance
    await _updateBalances();

    // remove completed transaction
    _pendingTransactions.remove(completedTransaction);
    _pendingTransactionsSubject.add(_pendingTransactions.toList());

    // save completed transaction
    await _cacheManagerCashu
        .saveTransactions(transactions: [completedTransaction]);

    // add to latest transactions
    _latestTransactions.add(completedTransaction);
    _latestTransactionsSubject?.add(_latestTransactions);

    yield completedTransaction;
  }

  /// funds the wallet (usually with lightning) and get ecash
  ///! reference
  Future<List<CashuProof>> fund({
    required String mintUrl,
    required int amount,
    required String unit,
    required String method,
  }) async {
    final keysets = await _cashuKeysets.getKeysetsFromMint(mintUrl);

    if (keysets.isEmpty) {
      throw Exception('No keysets found for mint: $mintUrl');
    }

    final keyset = CashuTools.filterKeysetsByUnitActive(
      keysets: keysets,
      unit: unit,
    );

    final quote = await _cashuRepo.getMintQuote(
      mintUrl: mintUrl,
      amount: amount,
      unit: unit,
      method: method,
    );

    CashuQuoteState payStatus;

    while (true) {
      payStatus = await _cashuRepo.checkMintQuoteState(
        mintUrl: mintUrl,
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
      mintUrl: mintUrl,
      quote: quote.quoteId,
      blindedMessagesOutputs: blindedMessagesOutputs
          .map(
            (e) => CashuBlindedMessage(
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
      proofs: unblindedTokens,
      mintUrl: mintUrl,
    );

    return unblindedTokens;
  }

  /// redeem token for x (usually lightning)
  /// [mintUrl] - URL of the mint
  /// [request] - the method request to redeem (like lightning invoice)
  /// [unit] - the unit of the token (sat)
  /// [method] - the method to use for redemption (bolt11)
  Future redeem({
    required String mintUrl,
    required String request,
    required String unit,
    required String method,
  }) async {
    final meltQuote = await _cashuRepo.getMeltQuote(
      mintUrl: mintUrl,
      request: request,
      unit: unit,
      method: method,
    );
    final feeReserve = meltQuote.feeReserve;

    final proofsUnfiltered = await _cacheManager.getProofs(
      mintUrl: mintUrl,
    );

    final mintKeysets = await _cashuKeysets.getKeysetsFromMint(mintUrl);
    if (mintKeysets.isEmpty) {
      throw Exception('No keysets found for mint: $mintUrl');
    }
    final keysetsForUnit =
        CashuTools.filterKeysetsByUnit(keysets: mintKeysets, unit: unit);

    final proofs = CashuTools.filterProofsByUnit(
        proofs: proofsUnfiltered, unit: unit, keysets: keysetsForUnit);

    if (proofs.isEmpty) {
      throw Exception('No proofs found for mint: $mintUrl and unit: $unit');
    }

    final int amountToSpend;

    // todo: add mint fees

    if (feeReserve != null) {
      amountToSpend = meltQuote.amount + feeReserve;
    } else {
      amountToSpend = meltQuote.amount;
    }

    final selectionResult = CashuProofSelect.selectProofsForSpending(
      proofs: proofs,
      targetAmount: amountToSpend,
      keysets: keysetsForUnit,
    );

    final activeKeyset =
        CashuTools.filterKeysetsByUnitActive(keysets: mintKeysets, unit: unit);

    /// outputs to send to mint
    final List<CashuBlindedMessageItem> myOutputs = [];

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
      mintUrl: mintUrl,
      quoteId: meltQuote.quoteId,
      proofs: selectionResult.selectedProofs,
      outputs: myOutputs
          .map(
            (e) => CashuBlindedMessage(
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
      mintUrl: mintUrl,
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
        proofs: changeUnblinded,
        mintUrl: mintUrl,
      );
    }
    return meltResult;
  }

  Future<List<CashuProof>> initiateSpend({
    required String mintUrl,
    required int amount,
    required String unit,
  }) async {
    if (amount <= 0) {
      throw Exception('Amount must be greater than zero');
    }

    final keysets = await _cashuKeysets.getKeysetsFromMint(mintUrl);
    if (keysets.isEmpty) {
      throw Exception('No keysets found for mint: $mintUrl');
    }

    final keysetsForUnit = CashuTools.filterKeysetsByUnit(
      keysets: keysets,
      unit: unit,
    );

    late final ProofSelectionResult selectionResult;

    await _cacheManagerCashu.runInTransaction(
      () async {
        // fetch proofs for the mint
        final allProofs = await _cacheManager.getProofs(
          mintUrl: mintUrl,
        );

        final proofsForUnit = CashuTools.filterProofsByUnit(
          proofs: allProofs,
          unit: unit,
          keysets: keysets,
        );
        if (proofsForUnit.isEmpty) {
          throw Exception('No proofs found for mint: $mintUrl and unit: $unit');
        }

        // select proofs for spending
        selectionResult = CashuProofSelect.selectProofsForSpending(
          proofs: proofsForUnit,
          targetAmount: amount,
          keysets: keysetsForUnit,
        );

        if (selectionResult.selectedProofs.isEmpty) {
          throw Exception('Not enough funds to spend the requested amount');
        }

        Logger.log.d(
            'Selected ${selectionResult.selectedProofs.length} proofs for spending, total: ${selectionResult.totalSelected} $unit');

        // mark proofs as pending
        _changeProofState(
          proofs: selectionResult.selectedProofs,
          state: CashuProofState.pending,
        );

        await _cacheManager.saveProofs(
          proofs: selectionResult.selectedProofs,
          mintUrl: mintUrl,
        );
      },
    );

    final transactionId = "spend-${Helpers.getRandomString(5)}";

    CashuWalletTransaction pendingTransaction = CashuWalletTransaction(
      id: transactionId,
      mintUrl: mintUrl,
      walletId: mintUrl,
      changeAmount: -1 * amount,
      unit: unit,
      walletType: WalletType.CASHU,
      state: WalletTransactionState.pending,
      initiatedDate: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      usedKeysets: keysetsForUnit,
    );
    // add to pending transactions

    _addPendingTransaction(pendingTransaction);
    Logger.log.d(
        'Initiated spend for $amount $unit from mint $mintUrl, using ${selectionResult.selectedProofs.length} proofs');

    if (selectionResult.needsSplit) {
      Logger.log.d(
          'Need to split ${selectionResult.splitAmount} $unit from ${selectionResult.totalSelected} total');

      final SplitResult splitResult;
      try {
        // split to get exact change
        splitResult = await _cashuWalletProofSelect.performSplit(
          mint: mintUrl,
          proofsToSplit: selectionResult.selectedProofs,
          targetAmount: amount,
          changeAmount: selectionResult.splitAmount,
          keysets: keysetsForUnit,
        );
      } catch (e) {
        _changeProofState(
          proofs: selectionResult.selectedProofs,
          state: CashuProofState.unspend,
        );

        // update proofs so they can be used again
        await _cacheManagerCashu.saveProofs(
          proofs: selectionResult.selectedProofs,
          mintUrl: mintUrl,
        );

        _removePendingTransaction(pendingTransaction);
        // mark transaction as failed
        final completedTransaction = pendingTransaction.copyWith(
          state: WalletTransactionState.failed,
          completionMsg: 'Failed to swap proofs to get exact change: $e',
        );
        await _addAndSaveLatestTransaction(completedTransaction);

        Logger.log.e('Error during spend initiation: $e');
        throw Exception('Spend initiation failed: $e');
      }

      /// mark selected proofs as spend
      _changeProofState(
        proofs: selectionResult.selectedProofs,
        state: CashuProofState.spend,
      );

      /// update proofs in cache
      await _cacheManagerCashu.saveProofs(
        proofs: selectionResult.selectedProofs,
        mintUrl: mintUrl,
      );
      // save change proofs
      await _cacheManagerCashu.saveProofs(
        proofs: splitResult.changeProofs,
        mintUrl: mintUrl,
      );

      pendingTransaction = pendingTransaction.copyWith(
        proofPubKeys: splitResult.exactProofs.map((e) => e.Y).toList(),
      );
      _addPendingTransaction(pendingTransaction);

      await _updateBalances();

      _checkSpendingState(
        transaction: pendingTransaction,
      );

      return splitResult.exactProofs;
    } else {
      Logger.log.d('No split needed, using selected proofs directly');
      _changeProofState(
        proofs: selectionResult.selectedProofs,
        state: CashuProofState.spend,
      );
      await _cacheManagerCashu.saveProofs(
        proofs: selectionResult.selectedProofs,
        mintUrl: mintUrl,
      );
      pendingTransaction = pendingTransaction.copyWith(
        proofPubKeys: selectionResult.selectedProofs.map((e) => e.Y).toList(),
      );
      _addPendingTransaction(pendingTransaction);

      await _updateBalances();

      _checkSpendingState(
        transaction: pendingTransaction,
      );

      return selectionResult.selectedProofs;
    }
  }

  /// todo: restore pending transaction from cache
  /// todo: recover funds
  void _checkSpendingState({
    required CashuWalletTransaction transaction,
  }) async {
    if (transaction.proofPubKeys == null || transaction.proofPubKeys!.isEmpty) {
      throw Exception('No proof public keys provided for checking state');
    }

    while (true) {
      final checkResult = await _cashuRepo.checkTokenState(
        proofPubkeys: transaction.proofPubKeys!,
        mintUrl: transaction.mintUrl,
      );

      /// check that all proofs are spent
      if (checkResult.every((e) => e.state == CashuProofState.spend)) {
        Logger.log.d('All proofs are spent for transaction ${transaction.id}');
        final completedTransaction = transaction.copyWith(
          state: WalletTransactionState.completed,
          transactionDate: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        );
        await _addAndSaveLatestTransaction(completedTransaction);
        _removePendingTransaction(transaction);
        return;
      }

      // retry after a delay
      await Future.delayed(CashuConfig.SPEND_CHECK_INTERVAL);
    }
  }

  /// send token to user
  Future<List<CashuProof>> spend({
    required String mintUrl,
    required int amount,
    required String unit,
  }) async {
    if (amount <= 0) {
      throw Exception('Amount must be greater than zero');
    }

    final keysets = await _cashuKeysets.getKeysetsFromMint(mintUrl);
    if (keysets.isEmpty) {
      throw Exception('No keysets found for mint: $mintUrl');
    }

    final keysetsForUnit = CashuTools.filterKeysetsByUnit(
      keysets: keysets,
      unit: unit,
    );

    final proofs = await _cacheManager.getProofs(mintUrl: mintUrl);
    if (proofs.isEmpty) {
      throw Exception('No proofs found for mint: $mintUrl');
    }

    final selectionResult = CashuProofSelect.selectProofsForSpending(
        proofs: proofs, targetAmount: amount, keysets: keysetsForUnit);

    if (selectionResult.selectedProofs.isEmpty) {
      throw Exception('Not enough funds to spend the requested amount');
    }

    if (selectionResult.needsSplit) {
      Logger.log.d(
          'Need to split ${selectionResult.splitAmount} $unit from ${selectionResult.totalSelected} total');

      // split to get exact change
      final splitResult = await _cashuWalletProofSelect.performSplit(
        mint: mintUrl,
        proofsToSplit: selectionResult.selectedProofs,
        targetAmount: amount,
        changeAmount: selectionResult.splitAmount,
        keysets: keysetsForUnit,
      );

      await _cacheManager.removeProofs(
        proofs: selectionResult.selectedProofs,
        mintUrl: mintUrl,
      );
      // save change proofs
      await _cacheManager.saveProofs(
        proofs: splitResult.changeProofs,
        mintUrl: mintUrl,
      );

      return splitResult.exactProofs;
    } else {
      Logger.log.d('No split needed, using selected proofs directly');
      await _cacheManager.removeProofs(
        proofs: selectionResult.selectedProofs,
        mintUrl: mintUrl,
      );
      return selectionResult.selectedProofs;
    }
  }

  /// accept token from user
  Future<List<CashuProof>> receive(String token) async {
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
      mintUrl: rcvToken.mintUrl,
      proofs: rcvToken.proofs,
      outputs: blindedMessagesOutputs
          .map(
            (e) => CashuBlindedMessage(
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

    await _cacheManagerCashu.atomicSaveAndRemove(
      proofsToRemove: sameSendRcv,
      tokensToSave: myUnblindedTokens,
      mintUrl: rcvToken.mintUrl,
    );

    return myUnblindedTokens;
  }

  String proofsToToken({
    required List<CashuProof> proofs,
    required String mintUrl,
    required String unit,
    String memo = "",
  }) {
    if (proofs.isEmpty) {
      throw Exception('No proofs provided for token conversion');
    }
    final cashuToken = CashuToken(
      proofs: proofs,
      mintUrl: mintUrl,
      memo: memo,
      unit: unit,
    );
    return cashuToken.toV4TokenString();
  }

  void _addPendingTransaction(
    CashuWalletTransaction transaction,
  ) {
    _pendingTransactions.add(transaction);
    _pendingTransactionsSubject.add(_pendingTransactions.toList());
  }

  void _removePendingTransaction(
    CashuWalletTransaction transaction,
  ) {
    _pendingTransactions.remove(transaction);
    _pendingTransactionsSubject.add(_pendingTransactions.toList());
  }

  Future<void> _addAndSaveLatestTransaction(
    CashuWalletTransaction transaction,
  ) async {
    _latestTransactions.add(transaction);
    _latestTransactionsSubject?.add(_latestTransactions);
    await _cacheManagerCashu.saveTransactions(transactions: [transaction]);
  }
}

void _changeProofState({
  required List<CashuProof> proofs,
  required CashuProofState state,
}) {
  for (final proof in proofs) {
    proof.state = state;
  }
}
