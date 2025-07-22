import '../../entities/cashu/wallet_cashu_blinded_message.dart';
import '../../repositories/cache_manager.dart';
import '../../repositories/cashu_repo.dart';
import 'cashu_bdhke.dart';
import 'cashu_keysets.dart';
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
  fund({
    required String mintURL,
    required int amount,
    required String unit,
    required String method,
  }) async {
    final keysets = await _cashuKeysets.getKeysetsFromMint(mintURL);

    if (keysets.isEmpty) {
      throw Exception('No keysets found for mint: $mintURL');
    }

    // todo filter active keyset
    final keyset = keysets.first;
    final keysetId = keyset.id;

    final quote = await _cashuRepo.getMintQuote(
      mintURL: mintURL,
      amount: amount,
      unit: unit,
      method: method,
    );

    final toPay = quote.request;

    // todo check until payed or expired
    await _cashuRepo.checkMintQuoteState(
      mintURL: mintURL,
      quoteID: quote.quoteId,
      method: method,
    );

    List<int> splittedAmounts = CashuTools.splitAmount(amount);
    final blindedMessagesOutputs = CashuBdhke.createBlindedMsgForAmounts(
        keysetId: keysetId, amounts: splittedAmounts);

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
    print('Minting successful, signatures: $mintResponse');
  }

  /// redeem toke for x (usually with lightning)
  redeem() {}

  /// send token to user
  spend() {}

  /// accept token from user
  receive() {
    //_cashuRepo.swap();
  }
}
