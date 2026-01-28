import '../../../config/nip_05_defaults.dart';
import '../../entities/nip_05.dart';
import '../../repositories/cache_manager.dart';
import '../../repositories/nip_05_repo.dart';

/// usecase to handle Nip05 operations (verify and fetch)
class Nip05Usecase {
  // Static map to keep track of in-flight requests
  static final Map<String, Future<Nip05>> _inFlightRequests = {};
  static final Map<String, Future<Nip05?>> _inFlightFetches = {};

  final CacheManager _database;
  final Nip05Repository _nip05Repository;

  /// creates a new [Nip05Usecase] instance
  /// [_database] the cache manager
  /// [_nip05Repository] the nip05 repository
  Nip05Usecase({
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

    final databaseResult = await _database.loadNip05(pubkey);

    if (databaseResult != null) {
      int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      int lastCheck = databaseResult.networkFetchTime ?? 0;
      if (now - lastCheck < NIP_05_VALID_DURATION.inSeconds) {
        return databaseResult;
      }
    }

    // Check if there's an in-flight request for this nip05
    if (_inFlightRequests.containsKey(nip05)) {
      // Wait for the existing request to complete
      return await _inFlightRequests[nip05]!;
    }

    // Create a new request and add it to the in-flight map
    final request =
        _performCheck(nip05, pubkey, Nip05(pubKey: pubkey, nip05: nip05));
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
      result.relays = networkResult.relays;
    }

    /// needs to be outside the if statement to update the networkFetchTime even on 404
    result.networkFetchTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _database.saveNip05(result);
    return result;
  }

  /// resolves NIP-05 data without requiring a pubkey for validation
  /// returns the [Nip05] object with pubkey and relays
  ///
  /// [nip05] the nip05 identifier (e.g. "username@example.com")
  /// returns the [Nip05] object or null if not found
  Future<Nip05?> resolve(String nip05) async {
    if (nip05.isEmpty) {
      throw Exception("nip05 empty");
    }

    // Check if there's an in-flight fetch for this nip05
    if (_inFlightFetches.containsKey(nip05)) {
      return await _inFlightFetches[nip05]!;
    }

    // Create a new fetch and add it to the in-flight map
    final fetch = _performFetch(nip05);
    _inFlightFetches[nip05] = fetch;

    try {
      return await fetch;
    } finally {
      _inFlightFetches.remove(nip05);
    }
  }

  Future<Nip05?> _performFetch(String nip05) async {
    try {
      final result = await _nip05Repository.fetchNip05(nip05);
      if (result != null) {
        await _database.saveNip05(result);
      }
      return result;
    } catch (e) {
      return null;
    }
  }
}
