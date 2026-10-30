import '../../../config/nip_05_defaults.dart';
import '../../entities/nip_05.dart';
import '../../entities/nip_05_resolve_result.dart';
import '../../repositories/cache_manager.dart';
import '../../repositories/nip_05_repo.dart';

/// usecase to handle Nip05 operations (verify and fetch)
class Nip05Usecase {
  // Keep request deduplication local to this use case/NDK instance. Different
  // instances may use different repositories and caches for the same NIP-05.
  final Map<String, Future<Nip05ResolveResult>> _inFlightResolves = {};

  final CacheManager _database;
  final Nip05Repository _nip05Repository;

  /// creates a new [Nip05Usecase] instance
  /// [_database] the cache manager
  /// [_nip05Repository] the nip05 repository
  Nip05Usecase({
    required CacheManager database,
    required Nip05Repository nip05Repository,
  }) : _database = database,
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

    final result = await resolve(nip05);
    if (result case Nip05Found(:final data) when data.pubKey == pubkey) {
      return data;
    }
    return Nip05(
      pubKey: pubkey,
      identifier: Nip05.canonicalIdentifier(nip05) ?? nip05,
      valid: false,
    );
  }

  /// Resolves NIP-05 data without requiring a pubkey for validation.
  ///
  /// [nip05] the nip05 identifier (e.g. "username@example.com")
  /// returns a [Nip05ResolveResult] — one of [Nip05Found], [Nip05NotFound],
  /// or [Nip05ResolveError]. Throws if [nip05] is empty.
  /// A [Nip05NotFound] is remembered for [NIP_05_NOT_FOUND_DURATION].
  Future<Nip05ResolveResult> resolve(String nip05) async {
    if (nip05.isEmpty) {
      throw Exception("nip05 empty");
    }

    final identifier = Nip05.canonicalIdentifier(nip05);
    if (identifier == null) {
      return const Nip05NotFound();
    }

    // Check cache first
    final databaseResult = await _database.loadNip05(identifier);
    if (databaseResult != null) {
      int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      int age = now - (databaseResult.networkFetchTime ?? 0);
      if (databaseResult.pubKey == null &&
          age < NIP_05_NOT_FOUND_DURATION.inSeconds) {
        return const Nip05NotFound();
      }
      // before #936, check() also cached failed verifications
      if (databaseResult.pubKey != null &&
          databaseResult.valid &&
          age < NIP_05_VALID_DURATION.inSeconds) {
        return Nip05Found(databaseResult);
      }
    }

    // Check if there's an in-flight fetch for this nip05
    if (_inFlightResolves.containsKey(identifier)) {
      return await _inFlightResolves[identifier]!;
    }

    // Create a new fetch and add it to the in-flight map
    final fetch = _performResolve(identifier);
    _inFlightResolves[identifier] = fetch;

    try {
      return await fetch;
    } finally {
      _inFlightResolves.remove(identifier);
    }
  }

  Future<Nip05ResolveResult> _performResolve(String nip05) async {
    try {
      final result = await _nip05Repository.fetchNip05(nip05);
      if (result == null) {
        await _database.saveNip05(
          Nip05(
            pubKey: null,
            identifier: nip05,
            networkFetchTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          ),
        );
        return const Nip05NotFound();
      }
      await _database.saveNip05(result);
      return Nip05Found(result);
    } on FormatException catch (e) {
      return Nip05ResolveInvalidResponse(e);
    } on TypeError catch (e) {
      return Nip05ResolveInvalidResponse(Exception(e.toString()));
    } catch (e) {
      return Nip05ResolveNetworkError(
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }
}
