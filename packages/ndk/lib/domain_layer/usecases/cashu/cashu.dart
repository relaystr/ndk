import 'package:rxdart/rxdart.dart';

import '../../../config/cashu_config.dart';
import '../../../shared/logger/logger.dart';
import '../../../shared/nips/nip01/helpers.dart';
import '../../entities/cashu/cashu_blinded_message.dart';
import '../../entities/cashu/cashu_blinded_signature.dart';
import '../../entities/cashu/cashu_mint_balance.dart';
import '../../entities/cashu/cashu_mint_info.dart';
import '../../entities/cashu/cashu_proof.dart';
import '../../entities/cashu/cashu_quote.dart';
import '../../entities/cashu/cashu_restore_result.dart';
import '../../entities/cashu/cashu_spending_result.dart';
import '../../entities/cashu/cashu_token.dart';
import '../../entities/cashu/cashu_user_seedphrase.dart';
import '../../entities/wallet/wallet_transaction.dart';
import '../../entities/wallet/wallet_type.dart';
import '../../repositories/cache_manager.dart';
import '../../repositories/cashu_key_derivation.dart';
import '../../repositories/cashu_repo.dart';

import 'cashu_bdhke.dart';
import 'cashu_cache_decorator.dart';
import 'cashu_keysets.dart';
import 'cashu_restore.dart';

import 'cashu_seed.dart';
import 'cashu_token_encoder.dart';
import 'cashu_tools.dart';
import 'cashu_proof_select.dart';

class Cashu {
  final CashuRepo _cashuRepo;
  final CacheManager _cacheManager;
  late final CashuCacheDecorator _cacheManagerCashu;

  late final CashuKeysets _cashuKeysets;
  late final CashuProofSelect _cashuWalletProofSelect;

  late final CashuSeed _cashuSeed;

  final CashuKeyDerivation _cashuKeyDerivation;

  Cashu({
    required CashuRepo cashuRepo,
    required CacheManager cacheManager,
    required CashuKeyDerivation cashuKeyDerivation,
    CashuUserSeedphrase? cashuUserSeedphrase,
  })  : _cashuRepo = cashuRepo,
        _cacheManager = cacheManager,
        _cashuKeyDerivation = cashuKeyDerivation {
    _cashuKeysets = CashuKeysets(
      cashuRepo: _cashuRepo,
      cacheManager: _cacheManager,
    );
    _cashuWalletProofSelect = CashuProofSelect(
      cashuRepo: _cashuRepo,
      cashuSeedSecretGenerator: _cashuKeyDerivation,
    );
    _cacheManagerCashu = CashuCacheDecorator(cacheManager: _cacheManager);

    _cashuSeed = CashuSeed(
      userSeedPhrase: cashuUserSeedphrase,
    );
    if (cashuUserSeedphrase == null) {
      Logger.log.w(
          'Cashu initialized without user seed phrase, cashu features will not work \nSet the seed phrase using NdkConfig or Cashu.setCashuSeedPhrase()');
    }
  }

  /// mints this usecase has interacted with \
  ///? does not mark trusted mints!
  final Set<CashuMintInfo> _knownMints = {};

  BehaviorSubject<Set<CashuMintInfo>>? _knownMintsSubject;

  final List<CashuWalletTransaction> _latestTransactions = [];

  BehaviorSubject<List<CashuWalletTransaction>>? _latestTransactionsSubject;

  final Set<CashuWalletTransaction> _pendingTransactions = {};
  BehaviorSubject<List<CashuWalletTransaction>>? _pendingTransactionsSubject;

  /// stream of balances \
  BehaviorSubject<List<CashuMintBalance>>? _balanceSubject;

  /// set cashu user seed phrase, required for using cashu features \
  /// ideally use the NdkConfig to set the seed phrase on initialization \
  /// you can use CashuSeed.generateSeedPhrase() to generate a new seed phrase
  void setCashuSeedPhrase(CashuUserSeedphrase userSeedPhrase) {
    _cashuSeed.setSeedPhrase(
      seedPhrase: userSeedPhrase.seedPhrase,
    );
  }

  /// Get the cashu seed instance
  CashuSeed getCashuSeed() {
    return _cashuSeed;
  }

  /// Restores proofs from a mint using the wallet's seed phrase.
  ///
  /// This implements NUT-09 (Restore) using NUT-13 (Deterministic Secrets).
  /// It will scan the mint for proofs that belong to this wallet's seed.
  ///
  /// [mintUrl] - The URL of the mint to restore from
  /// [unit] - The unit to restore proofs for (default: 'sat')
  /// [startCounter] - The counter to start scanning from (default: 0)
  /// [batchSize] - How many secrets to check in each batch (default: 100)
  /// [gapLimit] - How many consecutive empty batches before stopping (default: 2)
  ///
  /// Yields [CashuRestoreResult] updates as proofs are discovered during scanning.
  /// The final yielded result contains all restored proofs.
  Stream<CashuRestoreResult> restore({
    required String mintUrl,
    String unit = 'sat',
    int startCounter = 0,
    int batchSize = 100,
    int gapLimit = 2,
  }) async* {
    Logger.log.i('Starting restore from $mintUrl');

    // Get keysets for this mint and unit
    final allKeysets = await _cashuKeysets.getKeysetsFromMint(mintUrl);
    final keysets = allKeysets.where((keyset) => keyset.unit == unit).toList();

    if (keysets.isEmpty) {
      throw Exception('No keysets found for mint $mintUrl with unit $unit');
    }

    Logger.log.i('Found ${keysets.length} keysets for unit $unit');

    // Create restore instance
    final cashuRestore = CashuRestore(
      cashuRepo: _cashuRepo,
      cashuKeyDerivation: _cashuKeyDerivation,
      cacheManager: _cacheManagerCashu,
      cashuSeed: _cashuSeed,
    );

    // Restore all keysets and yield progress
    await for (final result in cashuRestore.restoreAllKeysets(
      mintUrl: mintUrl,
      keysets: keysets,
      startCounter: startCounter,
      batchSize: batchSize,
      gapLimit: gapLimit,
    )) {
      // Save restored proofs incrementally as they're discovered
      final newProofs = result.keysetResults
          .expand((keysetResult) => keysetResult.restoredProofs)
          .toList();

      if (newProofs.isNotEmpty) {
        // Check which proofs are actually unspent
        try {
          final proofStates = await _cashuRepo.checkTokenState(
            proofPubkeys: newProofs.map((p) => p.Y).toList(),
            mintUrl: mintUrl,
          );

          // Filter out spent proofs
          final unspentProofs = <CashuProof>[];
          for (int i = 0; i < newProofs.length; i++) {
            if (i < proofStates.length &&
                proofStates[i].state == CashuProofState.unspend) {
              unspentProofs.add(newProofs[i]);
            }
          }

          if (unspentProofs.isNotEmpty) {
            await _cacheManagerCashu.saveProofs(
              proofs: unspentProofs,
              mintUrl: mintUrl,
            );
            Logger.log.i(
                'Saved ${unspentProofs.length} unspent proofs to cache (filtered out ${newProofs.length - unspentProofs.length} spent proofs)');

            // Update balance stream
            await _updateBalances();
          } else {
            Logger.log.i(
                'All ${newProofs.length} restored proofs were already spent, skipping save');
          }
        } catch (e) {
          Logger.log.e('Error checking proof states during restore: $e');
          // If we can't check state, save the proofs anyway (better to have duplicates than lose proofs)
          await _cacheManagerCashu.saveProofs(
            proofs: newProofs,
            mintUrl: mintUrl,
          );
          Logger.log.w(
              'Saved ${newProofs.length} proofs without state check due to error');

          // Update balance stream
          await _updateBalances();
        }
      }

      // Yield progress update
      yield result;
    }

    Logger.log.i('Restore completed');
  }

  Future<int> getBalanceMintUnit({
    required String unit,
    required String mintUrl,
  }) async {
    final proofs = await _cacheManagerCashu.getProofs(mintUrl: mintUrl);
    final filteredProofs = CashuTools.filterProofsByUnit(
      proofs: proofs,
      unit: unit,
      keysets: await _cashuKeysets.getKeysetsFromMint(mintUrl),
    );

    return CashuTools.sumOfProofs(proofs: filteredProofs);
  }

  /// get balances for all mints \
  Future<List<CashuMintBalance>> getBalances({
    bool returnZeroValues = true,
  }) async {
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

      if (!returnZeroValues && keysetProofs.isEmpty) {
        continue;
      }

      final unit =
          allKeysets.firstWhere((keyset) => keyset.id == keysetId).unit;
      final totalBalanceForKeyset = CashuTools.sumOfProofs(
        proofs: keysetProofs,
      );

      if (totalBalanceForKeyset >= 0) {
        balances[mintUrl]![unit] =
            totalBalanceForKeyset + (balances[mintUrl]![unit] ?? 0);
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
    if (_pendingTransactionsSubject == null) {
      _pendingTransactionsSubject =
          BehaviorSubject<List<CashuWalletTransaction>>.seeded(
        _pendingTransactions.toList(),
      );
      _getPendingTransactionsDb().then((transactions) {
        _pendingTransactions.clear();
        _pendingTransactions.addAll(transactions);
        _pendingTransactionsSubject?.add(_pendingTransactions.toList());
      }).catchError((error) {
        _pendingTransactionsSubject?.addError(
          Exception('Failed to load pending transactions: $error'),
        );
      });
    }

    return _pendingTransactionsSubject!;
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
    int limit = 50,
  }) async {
    final transactions = await _cacheManagerCashu.getTransactions(
      limit: limit,
    );

    // Filter to exclude draft and pending transactions (includes completed, failed, canceled)
    final fTransactions = transactions
        .whereType<CashuWalletTransaction>()
        .where((tx) => !tx.state.isPending)
        .toList();

    return fTransactions;
  }

  Future<List<CashuWalletTransaction>> _getPendingTransactionsDb() async {
    final transactions = await _cacheManagerCashu.getTransactions(
      limit: 20,
    );

    // Filter to only include draft and pending transactions
    final pendingTransactions = transactions
        .whereType<CashuWalletTransaction>()
        .where((tx) => tx.state.isPending)
        .toList();

    return pendingTransactions;
  }

  Future<List<CashuMintInfo>> _getMintInfosDb() async {
    final mintInfos = await _cacheManager.getMintInfos();
    if (mintInfos == null) {
      return [];
    }
    return mintInfos;
  }

  /// get mint info from network \
  /// [mintUrl] is the URL of the mint \
  /// Returns a [CashuMintInfo] object containing the mint details.
  /// throws if the mint info cannot be fetched
  Future<CashuMintInfo> getMintInfoNetwork({
    required String mintUrl,
  }) {
    return _cashuRepo.getMintInfo(mintUrl: mintUrl);
  }

  /// checks if the mint can be fetched \
  /// and adds it to known mints \
  /// [mintUrl] is the URL of the mint \
  /// Returns true if the mint was added to known mints, false otherwise (already known).
  /// Throws if the mint info cannot be fetched
  Future<bool> addMintToKnownMints({
    required String mintUrl,
  }) async {
    final result = await _checkIfMintIsKnown(mintUrl);
    return !result;
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
    String? memo,
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
      description: memo ?? '',
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
    await _addAndSavePendingTransaction(draftTransaction);

    // save draft transaction to cache
    await _cacheManagerCashu.saveTransactions(transactions: [draftTransaction]);

    return draftTransaction;
  }

  /// retrieve funds from a pending funding transaction \
  /// [draftTransaction] - the draft transaction from initiateFund() \
  /// Returns a stream of [CashuWalletTransaction] that emits the transaction state as it progresses.
  /// Throws if the draft transaction is missing required fields.
  Stream<CashuWalletTransaction> retrieveFunds({
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

    // Remove draft transaction from pending if it exists
    _removePendingTransaction(draftTransaction);

    CashuQuoteState payStatus;

    final pendingTransaction = draftTransaction.copyWith(
      state: WalletTransactionState.pending,
    );

    // update pending transactions
    await _addAndSavePendingTransaction(pendingTransaction);

    // save pending state to cache
    await _cacheManagerCashu
        .saveTransactions(transactions: [pendingTransaction]);

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
          transactionDate: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        );

        // remove from pending and save to latest transactions
        _removePendingTransaction(expiredTransaction);
        await _addAndSaveLatestTransaction(expiredTransaction);

        Logger.log.w('Quote expired before payment was received');
        yield expiredTransaction;
        return;
      }

      await Future.delayed(CashuConfig.FUNDING_CHECK_INTERVAL);
    }

    List<int> splittedAmounts = CashuTools.splitAmount(quote.amount);
    final blindedMessagesOutputs = await CashuBdhke.createBlindedMsgForAmounts(
      keysetId: draftTransaction.usedKeysets!.first.id,
      amounts: splittedAmounts,
      cacheManager: _cacheManagerCashu,
      cashuSeed: _cashuSeed,
      mintUrl: mintUrl,
      cashuSeedSecretGenerator: _cashuKeyDerivation,
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
        transactionDate: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );

      // remove from pending and save to latest transactions
      _removePendingTransaction(failedTransaction);
      await _addAndSaveLatestTransaction(failedTransaction);

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
        transactionDate: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );

      // remove from pending and save to latest transactions
      _removePendingTransaction(failedTransaction);
      await _addAndSaveLatestTransaction(failedTransaction);

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

    // remove completed transaction
    _removePendingTransaction(completedTransaction);

    // save completed transaction
    await _cacheManagerCashu
        .saveTransactions(transactions: [completedTransaction]);

    // add to latest transactions
    _latestTransactions.add(completedTransaction);
    _latestTransactionsSubject?.add(_latestTransactions);

    // update balance
    await _updateBalances();

    yield completedTransaction;
  }

  /// redeem token for x (usually lightning)
  /// [mintUrl] - URL of the mint
  /// [request] - the method request to redeem (like lightning invoice)
  /// [unit] - the unit of the token (sat)
  /// [method] - the method to use for redemption (bolt11)
  /// Returns a [CashuWalletTransaction] with info about fees. \
  /// use redeem() to complete the redeem process.
  Future<CashuWalletTransaction> initiateRedeem({
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

    final draftTransaction = CashuWalletTransaction(
      id: meltQuote.quoteId,
      walletId: mintUrl,
      changeAmount: -1 * meltQuote.amount,
      unit: unit,
      walletType: WalletType.CASHU,
      state: WalletTransactionState.draft,
      mintUrl: mintUrl,
      qouteMelt: meltQuote,
      method: method,
      initiatedDate: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    return draftTransaction;
  }

  /// redeem tokens from a pending redeem transaction \
  /// use initiateRedeem() to create a draft transaction [CashuWalletTransaction] \
  Stream<CashuWalletTransaction> redeem({
    required CashuWalletTransaction draftRedeemTransaction,
  }) async* {
    if (draftRedeemTransaction.qouteMelt == null) {
      throw Exception("Melt Quote is not available in the transaction");
    }
    final meltQuote = draftRedeemTransaction.qouteMelt!;
    final mintUrl = draftRedeemTransaction.mintUrl;
    if (mintUrl.isEmpty) {
      throw Exception("Mint URL is not specified in the transaction");
    }
    if (draftRedeemTransaction.method == null) {
      throw Exception("Method is not specified in the transaction");
    }
    final method = draftRedeemTransaction.method!;
    await _checkIfMintIsKnown(mintUrl);

    final unit = draftRedeemTransaction.unit;
    if (unit.isEmpty) {
      throw Exception("Unit is not specified in the transaction");
    }
    final request = meltQuote.request;
    if (request.isEmpty) {
      throw Exception("Request is not specified in the transaction");
    }

    final mintKeysets = await _cashuKeysets.getKeysetsFromMint(mintUrl);
    if (mintKeysets.isEmpty) {
      throw Exception('No keysets found for mint: $mintUrl');
    }

    final keysetsForUnit =
        CashuTools.filterKeysetsByUnit(keysets: mintKeysets, unit: unit);

    final int amountToSpend;

    if (meltQuote.feeReserve != null) {
      amountToSpend = meltQuote.amount + meltQuote.feeReserve!;
    } else {
      amountToSpend = meltQuote.amount;
    }

    late final ProofSelectionResult selectionResult;

    await _cacheManagerCashu.runInTransaction(() async {
      final proofsUnfiltered = await _cacheManager.getProofs(
        mintUrl: mintUrl,
      );

      final proofs = CashuTools.filterProofsByUnit(
          proofs: proofsUnfiltered, unit: unit, keysets: keysetsForUnit);

      if (proofs.isEmpty) {
        throw Exception('No proofs found for mint: $mintUrl and unit: $unit');
      }

      selectionResult = CashuProofSelect.selectProofsForSpending(
        proofs: proofs,
        targetAmount: amountToSpend,
        keysets: keysetsForUnit,
      );

      _changeProofState(
        proofs: selectionResult.selectedProofs,
        state: CashuProofState.pending,
      );

      await _cacheManager.saveProofs(
        proofs: selectionResult.selectedProofs,
        mintUrl: mintUrl,
      );
    });

    final activeKeyset =
        CashuTools.filterKeysetsByUnitActive(keysets: mintKeysets, unit: unit);

    /// outputs to send to mint
    final List<CashuBlindedMessageItem> myOutputs = [];

    /// we dont have the exact amount
    if (selectionResult.needsSplit) {
      final blindedMessagesOutputsOverpay =
          await CashuBdhke.createBlindedMsgForAmounts(
              keysetId: activeKeyset.id,
              amounts: CashuTools.splitAmount(selectionResult.splitAmount),
              cacheManager: _cacheManagerCashu,
              cashuSeed: _cashuSeed,
              mintUrl: mintUrl,
              cashuSeedSecretGenerator: _cashuKeyDerivation);
      myOutputs.addAll(
        blindedMessagesOutputsOverpay,
      );
    }

    /// blank outputs for (lightning) fee reserve
    if (meltQuote.feeReserve != null) {
      final numBlankOutputs =
          CashuTools.calculateNumberOfBlankOutputs(meltQuote.feeReserve!);

      final blankOutputs = await CashuBdhke.createBlindedMsgForAmounts(
          keysetId: activeKeyset.id,
          amounts: List.generate(numBlankOutputs, (_) => 0),
          cacheManager: _cacheManagerCashu,
          cashuSeed: _cashuSeed,
          mintUrl: mintUrl,
          cashuSeedSecretGenerator: _cashuKeyDerivation);
      myOutputs.addAll(blankOutputs);
    }

    myOutputs.sort(
        (a, b) => b.amount.compareTo(a.amount)); // sort outputs by amount desc

    // Remove draft transaction from pending if it exists
    _removePendingTransaction(draftRedeemTransaction);

    final pendingTransaction = draftRedeemTransaction.copyWith(
      state: WalletTransactionState.pending,
    );
    await _addAndSavePendingTransaction(pendingTransaction);
    yield pendingTransaction;

    try {
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

      /// mark used proofs as spent
      _changeProofState(
        proofs: selectionResult.selectedProofs,
        state: CashuProofState.spend,
      );
      await _cacheManager.saveProofs(
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

        await _cacheManagerCashu.saveProofs(
          proofs: changeUnblinded,
          mintUrl: mintUrl,
        );
      }

      final completedTransaction = pendingTransaction.copyWith(
        state: WalletTransactionState.completed,
        transactionDate: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      // remove completed transaction
      _removePendingTransaction(completedTransaction);
      // save completed transaction
      _addAndSaveLatestTransaction(completedTransaction);

      // update balance
      await _updateBalances();
      yield completedTransaction;
    } catch (e) {
      // Check if proofs were actually spent on the mint
      try {
        final proofStates = await _cashuRepo.checkTokenState(
          proofPubkeys: selectionResult.selectedProofs.map((p) => p.Y).toList(),
          mintUrl: mintUrl,
        );

        final allSpent =
            proofStates.every((state) => state.state == CashuProofState.spend);

        if (allSpent) {
          // Proofs were spent on mint side, mark them as spent locally
          _changeProofState(
            proofs: selectionResult.selectedProofs,
            state: CashuProofState.spend,
          );
          await _cacheManagerCashu.saveProofs(
            proofs: selectionResult.selectedProofs,
            mintUrl: mintUrl,
          );

          final failedTransaction = pendingTransaction.copyWith(
            state: WalletTransactionState.failed,
            completionMsg:
                'Proofs were spent but melt failed: $e. Proofs marked as spent to prevent reuse.',
          );
          _removePendingTransaction(failedTransaction);
          yield failedTransaction;
        } else {
          // Proofs were not spent, safe to release them
          _changeProofState(
            proofs: selectionResult.selectedProofs,
            state: CashuProofState.unspend,
          );
          await _cacheManagerCashu.saveProofs(
            proofs: selectionResult.selectedProofs,
            mintUrl: mintUrl,
          );

          final failedTransaction = pendingTransaction.copyWith(
            state: WalletTransactionState.failed,
            completionMsg: 'Redeeming failed: $e',
          );
          _removePendingTransaction(failedTransaction);
          yield failedTransaction;
        }
      } catch (stateCheckError) {
        // If we can't check the state, assume proofs might be spent and mark them as such to be safe
        _changeProofState(
          proofs: selectionResult.selectedProofs,
          state: CashuProofState.spend,
        );
        await _cacheManagerCashu.saveProofs(
          proofs: selectionResult.selectedProofs,
          mintUrl: mintUrl,
        );

        final failedTransaction = pendingTransaction.copyWith(
          state: WalletTransactionState.failed,
          completionMsg:
              'Redeeming failed: $e. Could not verify proof state: $stateCheckError. Proofs marked as spent for safety.',
        );
        _removePendingTransaction(failedTransaction);
        yield failedTransaction;
      }
      return;
    }
  }

  Future<CashuSpendingResult> initiateSpend({
    required String mintUrl,
    required int amount,
    required String unit,
    String? memo,
  }) async {
    if (amount <= 0) {
      throw Exception('Amount must be greater than zero');
    }

    final allKeysets = await _cashuKeysets.getKeysetsFromMint(mintUrl);
    if (allKeysets.isEmpty) {
      throw Exception('No keysets found for mint: $mintUrl');
    }

    final keysetsForUnit = CashuTools.filterKeysetsByUnit(
      keysets: allKeysets,
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
          keysets: allKeysets,
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
    await _addAndSavePendingTransaction(pendingTransaction);

    Logger.log.d(
        'Initiated spend for $amount $unit from mint $mintUrl, using ${selectionResult.selectedProofs.length} proofs');

    final List<CashuProof> proofsToReturn;

    // split so we get exact change
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
          cacheManagerCashu: _cacheManagerCashu,
          cashuSeed: _cashuSeed,
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
          transactionDate: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          completionMsg: 'Failed to swap proofs to get exact change: $e',
        );
        await _addAndSaveLatestTransaction(completedTransaction);

        Logger.log.e('Error during spend initiation: $e');
        throw Exception('Spend initiation failed: $e');
      }

      // save change proofs
      await _cacheManagerCashu.saveProofs(
        proofs: splitResult.changeProofs,
        mintUrl: mintUrl,
      );

      proofsToReturn = splitResult.exactProofs;
    } else {
      proofsToReturn = selectionResult.selectedProofs;
      Logger.log.d('No split needed, using selected proofs directly');
    }

    /// mark proofs as spent
    _changeProofState(
      proofs: selectionResult.selectedProofs,
      state: CashuProofState.spend,
    );

    /// update proofs in cache
    await _cacheManagerCashu.saveProofs(
      proofs: selectionResult.selectedProofs,
      mintUrl: mintUrl,
    );

    pendingTransaction = pendingTransaction.copyWith(
      proofPubKeys: proofsToReturn.map((e) => e.Y).toList(),
    );
    await _addAndSavePendingTransaction(pendingTransaction);

    await _updateBalances();

    checkSpendingState(
      transaction: pendingTransaction,
    );

    final token = proofsToToken(
      proofs: proofsToReturn,
      mintUrl: mintUrl,
      unit: unit,
      memo: memo ?? '',
    );

    pendingTransaction = pendingTransaction.copyWith(
      token: token.toV4TokenString(),
    );
    await _addAndSavePendingTransaction(pendingTransaction);

    return CashuSpendingResult(
      token: token,
      transaction: pendingTransaction,
    );
  }

  /// todo: restore pending transaction from cache
  /// todo: recover funds
  /// todo: timeout
  void checkSpendingState({
    required CashuWalletTransaction transaction,
  }) async {
    if (transaction.proofPubKeys == null || transaction.proofPubKeys!.isEmpty) {
      throw Exception('No proof public keys provided for checking state');
    }

    try {
      while (true) {
        final checkResult = await _cashuRepo.checkTokenState(
          proofPubkeys: transaction.proofPubKeys!,
          mintUrl: transaction.mintUrl,
        );

        /// check that all proofs are spent
        if (checkResult.every((e) => e.state == CashuProofState.spend)) {
          Logger.log
              .d('All proofs are spent for transaction ${transaction.id}');
          final completedTransaction = transaction.copyWith(
            state: WalletTransactionState.completed,
            transactionDate: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          );
          await _addAndSaveLatestTransaction(completedTransaction);
          _removePendingTransaction(transaction);

          // mark proofs as spent in db
          final allPendingProofs = await _cacheManagerCashu.getProofs(
            mintUrl: transaction.mintUrl,
            state: CashuProofState.pending,
          );

          final transactionProofs = allPendingProofs
              .where((e) => transaction.proofPubKeys!.contains(e.Y))
              .toList();

          _changeProofState(
            proofs: transactionProofs,
            state: CashuProofState.spend,
          );
          await _cacheManagerCashu.saveProofs(
            proofs: transactionProofs,
            mintUrl: transaction.mintUrl,
          );

          return;
        }

        // retry after a delay
        await Future.delayed(CashuConfig.SPEND_CHECK_INTERVAL);
      }
    } catch (e) {
      Logger.log.e(
          'Error checking spending state for transaction ${transaction.id}: $e');
      // Mark transaction as failed
      final failedTransaction = transaction.copyWith(
        state: WalletTransactionState.failed,
        transactionDate: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        completionMsg: 'Failed to verify spending state: $e',
      );
      _removePendingTransaction(transaction);
      await _addAndSaveLatestTransaction(failedTransaction);
    }
  }

  /// accept token from user
  /// [token] - the Cashu token string to receive \
  /// returns a stream of [CashuWalletTransaction] that emits the transaction state as it progresses.
  Stream<CashuWalletTransaction> receive(String token) async* {
    final rcvToken = CashuTokenEncoder.decodedToken(token);
    if (rcvToken == null) {
      throw Exception('Invalid Cashu token format');
    }

    if (rcvToken.proofs.isEmpty) {
      throw Exception('No proofs found in the Cashu token');
    }

    await _checkIfMintIsKnown(rcvToken.mintUrl);

    final keysets = await _cashuKeysets.getKeysetsFromMint(rcvToken.mintUrl);

    if (keysets.isEmpty) {
      throw Exception('No keysets found for mint: ${rcvToken.mintUrl}');
    }

    final keyset = CashuTools.filterKeysetsByUnitActive(
      keysets: keysets,
      unit: rcvToken.unit,
    );

    final rcvSum = CashuTools.sumOfProofs(proofs: rcvToken.proofs);

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    CashuWalletTransaction pendingTransaction = CashuWalletTransaction(
      id: rcvToken.mintUrl + now.toString(), //todo use a better id
      mintUrl: rcvToken.mintUrl,
      walletId: rcvToken.mintUrl,
      changeAmount: rcvSum,
      unit: rcvToken.unit,
      walletType: WalletType.CASHU,
      state: WalletTransactionState.pending,
      initiatedDate: DateTime.now().millisecondsSinceEpoch ~/ 1000,

      usedKeysets: [keyset],
      note: rcvToken.memo,
    );

    await _addAndSavePendingTransaction(pendingTransaction);
    yield pendingTransaction;

    List<int> splittedAmounts = CashuTools.splitAmount(rcvSum);
    final blindedMessagesOutputs = await CashuBdhke.createBlindedMsgForAmounts(
        keysetId: keyset.id,
        amounts: splittedAmounts,
        cacheManager: _cacheManagerCashu,
        cashuSeed: _cashuSeed,
        mintUrl: rcvToken.mintUrl,
        cashuSeedSecretGenerator: _cashuKeyDerivation);

    blindedMessagesOutputs.sort(
      (a, b) => a.blindedMessage.amount.compareTo(b.blindedMessage.amount),
    );

    final List<CashuBlindedSignature> myBlindedSingatures;
    try {
      myBlindedSingatures = await _cashuRepo.swap(
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
    } catch (e) {
      _removePendingTransaction(pendingTransaction);
      final failedTransaction = pendingTransaction.copyWith(
        state: WalletTransactionState.failed,
        completionMsg: 'Failed to swap proofs: $e',
        transactionDate: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      await _addAndSaveLatestTransaction(failedTransaction);
      yield failedTransaction;
      throw Exception('Failed to swap proofs: $e');
    }

    // unblind
    final myUnblindedTokens = CashuBdhke.unblindSignatures(
      mintSignatures: myBlindedSingatures,
      blindedMessages: blindedMessagesOutputs,
      mintPublicKeys: keyset,
    );

    if (myUnblindedTokens.isEmpty) {
      _removePendingTransaction(pendingTransaction);
      final failedTransaction = pendingTransaction.copyWith(
        state: WalletTransactionState.failed,
        completionMsg: 'Unblinding failed, no tokens returned',
      );
      await _addAndSaveLatestTransaction(failedTransaction);
      yield failedTransaction;
      throw Exception('Unblinding failed, no tokens returned');
    }

    // check if we recived our own proofs
    // final ownTokens = await _cacheManager.getProofs(mintUrl: rcvToken.mintUrl);

    // final sameSendRcv = rcvToken.proofs
    //     .where((e) => ownTokens.any((ownToken) => ownToken.Y == e.Y))
    //     .toList();

    // await _cacheManagerCashu.atomicSaveAndRemove(
    //   proofsToRemove: sameSendRcv,
    //   tokensToSave: myUnblindedTokens,
    //   mintUrl: rcvToken.mintUrl,
    // );
    await _cacheManagerCashu.saveProofs(
      proofs: myUnblindedTokens,
      mintUrl: rcvToken.mintUrl,
    );

    _removePendingTransaction(pendingTransaction);

    final completedTransaction = pendingTransaction.copyWith(
      state: WalletTransactionState.completed,
      transactionDate: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    _addAndSaveLatestTransaction(completedTransaction);

    _updateBalances();

    yield completedTransaction;
  }

  CashuToken proofsToToken({
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
    return cashuToken;
  }

  Future<void> _addAndSavePendingTransaction(
    CashuWalletTransaction transaction,
  ) async {
    // update transaction
    _pendingTransactions.removeWhere((t) => t.id == transaction.id);

    _pendingTransactions.add(transaction);
    _pendingTransactionsSubject?.add(_pendingTransactions.toList());
    // save pending transaction to cache
    await _cacheManagerCashu.saveTransactions(transactions: [transaction]);
  }

  void _removePendingTransaction(
    CashuWalletTransaction transaction,
  ) {
    _pendingTransactions.removeWhere((t) => t.id == transaction.id);
    _pendingTransactionsSubject?.add(_pendingTransactions.toList());
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
