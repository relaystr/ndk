import '../../../config/nip_05_defaults.dart';
import '../../entities/nip_05.dart';
import '../../repositories/cache_manager.dart';
import '../../repositories/nip_05_repo.dart';

/// usecase to verify the Nip05 object
class VerifyNip05 {
  // Static map to keep track of in-flight requests
  static final Map<String, Future<Nip05>> _inFlightRequests = {};

  final CacheManager _database;
  final Nip05Repository _nip05Repository;

  /// creates a new [VerifyNip05] instance
  /// [_database] the cache manager
  /// [_nip05Repository] the nip05 repository
  VerifyNip05({
    required CacheManager database,
    required Nip05Repository nip05Repository,
  })  : _database = database,
        _nip05Repository = nip05Repository;

  /// checks the nip05 object for validity
  /// it checks the cache first, if not found it fetches from the network
  /// if either fails valid is set to false
  ///
  /// [nip05] the nip05 identifier
  /// [pubkey] the public key
  /// returns the [Nip05] object
  Future<Nip05> check({required String nip05, required String pubkey}) async {
    if (nip05.isEmpty || pubkey.isEmpty) {
      throw Exception("nip05 or pubkey empty");
    }

    final result = Nip05(pubKey: pubkey, nip05: nip05);

    final databaseResult = await _database.loadNip05(nip05);

    if (databaseResult != null) {
      int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      int lastCheck = databaseResult.networkFetchTime ?? 0;
      if (now - lastCheck < NIP_05_VALID_DURATION) {
        return databaseResult;
      }
    }

    // Check if there's an in-flight request for this nip05
    if (_inFlightRequests.containsKey(nip05)) {
      // Wait for the existing request to complete
      return await _inFlightRequests[nip05]!;
    }

    // Create a new request and add it to the in-flight map
    final request = _performCheck(nip05, pubkey, result);
    _inFlightRequests[nip05] = request;

    try {
      return await request;
    } finally {
      // Remove the request from the in-flight map once it's completed
      _inFlightRequests.remove(nip05);
    }
  }

  Future<Nip05> _performCheck(String nip05, String pubkey, Nip05 result) async {
    Nip05? networkResult;
    try {
      networkResult = await _nip05Repository.requestNip05(nip05, pubkey);
    } catch (e) {
      networkResult = null;
    }

    if (networkResult != null) {
      result.valid = networkResult.valid;
    }

    await _database.saveNip05(result);
    return result;
  }
}
