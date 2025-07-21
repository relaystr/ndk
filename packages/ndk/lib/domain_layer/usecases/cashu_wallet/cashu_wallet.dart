import '../../entities/cashu/wallet_cahsu_keyset.dart';
import '../../repositories/cashu_repo.dart';

class CashuWallet {
  final CashuRepo _cashuRepo;

  CashuWallet({
    required CashuRepo cashuRepo,
  }) : _cashuRepo = cashuRepo;

  // final Set<Transaction> _transactions = {};

  // final Set<Mint> _mints = {};

  // final Set<Proof> _proofs = {};

  // final Set<Pending> _pending = {};

  getBalance({required String unit}) {}

  /// funds the wallet (usually with lightning) and get ecash
  fund() {}

  /// redeem toke for x (usually with lightning)
  redeem() {}

  /// send token to user
  spend() {}

  /// accept token from user
  receive() {
    //_cashuRepo.swap();
  }

  Future<List<WalletCahsuKeyset>> getKeysetMintFromNetwork({
    required String mintURL,
  }) async {
    final List<WalletCahsuKeyset> mintKeys = [];
    final keySets = await _cashuRepo.getKeysets(
      mintURL: mintURL,
    );

    for (final keySet in keySets) {
      final keys = await _cashuRepo.getKeys(
        mintURL: mintURL,
        keysetId: keySet.id,
      );

      mintKeys.add(
        WalletCahsuKeyset.fromResponses(
          keysetResponse: keySet,
          keysResponse: keys.first,
        ),
      );
    }
    return mintKeys;
  }
}
