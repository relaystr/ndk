import '../../repositories/cache_manager.dart';
import '../../repositories/cashu_repo.dart';
import 'cashu_keysets.dart';

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
  fund() {}

  /// redeem toke for x (usually with lightning)
  redeem() {}

  /// send token to user
  spend() {}

  /// accept token from user
  receive() {
    //_cashuRepo.swap();
  }
}
