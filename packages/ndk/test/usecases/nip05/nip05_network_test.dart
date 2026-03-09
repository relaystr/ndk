import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:http/testing.dart';
import 'package:mockito/annotations.dart';
import 'package:ndk/config/nip_05_defaults.dart';
import 'package:ndk/data_layer/data_sources/http_request.dart';
import 'package:ndk/data_layer/repositories/nip_05_http_impl.dart';
import 'package:ndk/domain_layer/entities/nip_05.dart';
import 'package:ndk/domain_layer/usecases/nip05/nip_05.dart';
import 'package:ndk/ndk.dart';

@GenerateMocks([http.Client])
void main() {
  Future<http.Response> requestHandler(http.Request request) async {
    const apiResponse =
        '{"names": {"username": "pubkey"}, "relays": {"pubkey": ["relay1", "relay2"]}}';
    return http.Response(apiResponse, 200);
  }

  Future<http.Response> requestHandler2(http.Request request) async {
    const apiResponse =
        '{"names": {"_": "pubkey"}, "relays": {"pubkey": ["relay1", "relay2"]}}';
    return http.Response(apiResponse, 200);
  }

  Future<http.Response> requestHandlerErr(http.Request request) async {
    const apiResponse = '';
    return http.Response(apiResponse, 500);
  }

  group('Nip05', () {
    test('throw if no pubkey or nip 05', () async {
      final client = MockClient(requestHandler);

      final cache = MemCacheManager();
      final nip05Repos = Nip05HttpRepositoryImpl(httpDS: HttpRequestDS(client));

      Nip05Usecase nip05Usecase = Nip05Usecase(
        database: cache,
        nip05Repository: nip05Repos,
      );

      expect(nip05Usecase.check(nip05: '', pubkey: ''), throwsException);
      expect(nip05Usecase.check(nip05: 'test@example.com', pubkey: ''),
          throwsException);
      expect(
          nip05Usecase.check(nip05: '', pubkey: 'testPubkey'), throwsException);
      expect(
          nip05Usecase.check(nip05: 'test@example.com', pubkey: 'testPubkey'),
          isA<Future<Nip05>>());
    });
    test('returns Nip05 if the http call completes successfully', () async {
      final client = MockClient(requestHandler);

      final cache = MemCacheManager();
      final nip05Repos = Nip05HttpRepositoryImpl(httpDS: HttpRequestDS(client));

      Nip05Usecase nip05Usecase = Nip05Usecase(
        database: cache,
        nip05Repository: nip05Repos,
      );

      await Future.delayed(const Duration(milliseconds: 10));

      expect(
          await nip05Usecase.check(
              nip05: 'username@example.com', pubkey: 'pubkey'),
          isA<Nip05>());
    });

    test('return false if the http call completes with an error', () async {
      final client = MockClient(requestHandlerErr);

      final cache = MemCacheManager();
      final nip05Repos = Nip05HttpRepositoryImpl(httpDS: HttpRequestDS(client));

      Nip05Usecase nip05Usecase = Nip05Usecase(
        database: cache,
        nip05Repository: nip05Repos,
      );

      var result = await nip05Usecase.check(
          nip05: 'username@url.test', pubkey: 'pubkey');

      expect(result.valid, false);
    });

    test('result is invalid', () async {
      final client = MockClient(requestHandler);
      final cache = MemCacheManager();
      final nip05Repos = Nip05HttpRepositoryImpl(httpDS: HttpRequestDS(client));

      Nip05Usecase nip05Usecase = Nip05Usecase(
        database: cache,
        nip05Repository: nip05Repos,
      );

      var result = await nip05Usecase.check(
          nip05: 'username@url.test', pubkey: 'non-existing-pubkey');

      expect(result.valid, false);
    });

    test('result is valid', () async {
      final client = MockClient(requestHandler);

      final cache = MemCacheManager();
      final nip05Repos = Nip05HttpRepositoryImpl(httpDS: HttpRequestDS(client));

      Nip05Usecase nip05Usecase = Nip05Usecase(
        database: cache,
        nip05Repository: nip05Repos,
      );

      var result = await nip05Usecase.check(
          nip05: 'username@url.test', pubkey: 'pubkey');

      expect(result.valid, true);
    });

    test('result is valid with _ as name', () async {
      final client = MockClient(requestHandler2);

      final cache = MemCacheManager();
      final nip05Repos = Nip05HttpRepositoryImpl(httpDS: HttpRequestDS(client));

      Nip05Usecase nip05Usecase = Nip05Usecase(
        database: cache,
        nip05Repository: nip05Repos,
      );

      var result = await nip05Usecase.check(
          nip05: 'domain@domain.test', pubkey: 'pubkey');

      expect(result.valid, true);
    });

    test('spam requests - check in flight', () async {
      final client = MockClient(requestHandler);

      final cache = MemCacheManager();
      final nip05Repos = Nip05HttpRepositoryImpl(httpDS: HttpRequestDS(client));

      Nip05Usecase nip05Usecase = Nip05Usecase(
        database: cache,
        nip05Repository: nip05Repos,
      );

      final check1 =
          nip05Usecase.check(nip05: 'username@url.test', pubkey: 'pubkey');
      final check2 = nip05Usecase.check(
          nip05: 'somethingDiffrent@url.test', pubkey: 'pubkey');
      final check3 =
          nip05Usecase.check(nip05: 'username@url.test', pubkey: 'pubkey');
      final check4 =
          nip05Usecase.check(nip05: 'username@url.test', pubkey: 'pubkey');

      final results = await Future.wait([check1, check2, check3, check4]);

      expect(results.first.valid, true);
      expect(results.last.valid, true);
      expect(results.first.hashCode, equals(results.last.hashCode));
    });

    test('returns true when updatedAt is older than the given duration',
        () async {
      final client = MockClient(requestHandler);

      final cache = MemCacheManager();
      final nip05Repos = Nip05HttpRepositoryImpl(httpDS: HttpRequestDS(client));
      // Create a Nip05 object with an old updatedAt timestamp
      final oldTimestamp = (DateTime.now()
              .subtract(Duration(seconds: NIP_05_VALID_DURATION.inSeconds - 1))
              .millisecondsSinceEpoch ~/
          1000);

      final oldNip05 = Nip05(
        pubKey: 'test_pubkey',
        nip05: 'test_nip05',
        valid: true,
        networkFetchTime: oldTimestamp,
      );

      await cache.saveNip05(oldNip05);

      Nip05Usecase nip05Usecase = Nip05Usecase(
        database: cache,
        nip05Repository: nip05Repos,
      );

      final result =
          await nip05Usecase.check(nip05: 'test_nip05', pubkey: 'test_pubkey');

      expect(result.valid,
          true); // Should return true since the object is older than 5 days
    });

    test('returns false when updatedAt is more recent than the given duration',
        () async {
      final client = MockClient(requestHandler);

      final cache = MemCacheManager();
      final nip05Repos = Nip05HttpRepositoryImpl(httpDS: HttpRequestDS(client));
      Nip05Usecase nip05Usecase = Nip05Usecase(
        database: cache,
        nip05Repository: nip05Repos,
      );

      // Create a Nip05 object with a recent updatedAt timestamp
      final recentTimestamp = (DateTime.now()
              .subtract(
                  Duration(seconds: NIP_05_VALID_DURATION.inSeconds + 200))
              .millisecondsSinceEpoch ~/
          1000);
      final oldNip05 = Nip05(
          pubKey: 'test_pubkey',
          nip05: 'test_nip05',
          valid: true,
          networkFetchTime: recentTimestamp);

      await cache.saveNip05(oldNip05);

      // Test with a duration of 5 days
      final result =
          await nip05Usecase.check(nip05: 'test_nip05', pubkey: 'test_pubkey');
      expect(result.valid,
          false); // Should return false since the object is more recent than 5 days
    });

    test('returns false when updatedAt is exactly the duration ago', () async {
      final client = MockClient(requestHandler);

      final cache = MemCacheManager();
      final nip05Repos = Nip05HttpRepositoryImpl(httpDS: HttpRequestDS(client));
      Nip05Usecase nip05Usecase = Nip05Usecase(
        database: cache,
        nip05Repository: nip05Repos,
      );

      // Create a Nip05 object with an updatedAt timestamp exactly equal to the duration
      final exactTimestamp = (DateTime.now()
              .subtract(Duration(seconds: NIP_05_VALID_DURATION.inSeconds))
              .millisecondsSinceEpoch ~/
          1000);
      final oldNip05 = Nip05(
        pubKey: 'test_pubkey',
        nip05: 'test_nip05',
        valid: true,
        networkFetchTime: exactTimestamp,
      );

      await cache.saveNip05(oldNip05);

      final result =
          await nip05Usecase.check(nip05: 'test_nip05', pubkey: 'test_pubkey');

      expect(result.valid,
          false); // Should return false since it's exactly at the limit
    });

    test('test if data is saved even when network fails', () async {
      final client = MockClient(requestHandlerErr);

      final cache = MemCacheManager();
      final nip05Repos = Nip05HttpRepositoryImpl(httpDS: HttpRequestDS(client));
      Nip05Usecase nip05Usecase = Nip05Usecase(
        database: cache,
        nip05Repository: nip05Repos,
      );

      await nip05Usecase.check(
          nip05: 'test_nip05_cache', pubkey: 'test_pubkey_cache');

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final cacheResult = await cache.loadNip05(pubKey: 'test_pubkey_cache');

      /// check that the timestamp is within 5 seconds of the current time
      expect(cacheResult!.networkFetchTime, greaterThanOrEqualTo(now - 5));
      expect(cacheResult.networkFetchTime, lessThanOrEqualTo(now));
    });

    test('test if relays are saved', () async {
      final client = MockClient(requestHandler);

      final cache = MemCacheManager();
      final nip05Repos = Nip05HttpRepositoryImpl(httpDS: HttpRequestDS(client));
      Nip05Usecase nip05Usecase = Nip05Usecase(
        database: cache,
        nip05Repository: nip05Repos,
      );

      final result = await nip05Usecase.check(
          nip05: 'username@example.com', pubkey: 'pubkey');

      expect(result.relays, equals(['relay1', 'relay2']));
    });

    test('resolve() returns pubkey without validation', () async {
      final client = MockClient(requestHandler);

      final cache = MemCacheManager();
      final nip05Repos = Nip05HttpRepositoryImpl(httpDS: HttpRequestDS(client));
      Nip05Usecase nip05Usecase = Nip05Usecase(
        database: cache,
        nip05Repository: nip05Repos,
      );

      final result = await nip05Usecase.resolve('username@example.com');

      expect(result, isNotNull);
      expect(result!.pubKey, equals('pubkey'));
      expect(result.nip05, equals('username@example.com'));
      expect(result.relays, equals(['relay1', 'relay2']));
    });

    test('resolve() returns null on error', () async {
      final client = MockClient(requestHandlerErr);

      final cache = MemCacheManager();
      final nip05Repos = Nip05HttpRepositoryImpl(httpDS: HttpRequestDS(client));
      Nip05Usecase nip05Usecase = Nip05Usecase(
        database: cache,
        nip05Repository: nip05Repos,
      );

      final result = await nip05Usecase.resolve('username@example.com');

      expect(result, isNull);
    });

    test('resolve() throws if nip05 is empty', () async {
      final client = MockClient(requestHandler);

      final cache = MemCacheManager();
      final nip05Repos = Nip05HttpRepositoryImpl(httpDS: HttpRequestDS(client));
      Nip05Usecase nip05Usecase = Nip05Usecase(
        database: cache,
        nip05Repository: nip05Repos,
      );

      expect(nip05Usecase.resolve(''), throwsException);
    });

    test('resolve() deduplicates in-flight requests', () async {
      final client = MockClient(requestHandler);

      final cache = MemCacheManager();
      final nip05Repos = Nip05HttpRepositoryImpl(httpDS: HttpRequestDS(client));
      Nip05Usecase nip05Usecase = Nip05Usecase(
        database: cache,
        nip05Repository: nip05Repos,
      );

      final resolve1 = nip05Usecase.resolve('username@example.com');
      final resolve2 = nip05Usecase.resolve('username@example.com');
      final resolve3 = nip05Usecase.resolve('username@example.com');

      final results = await Future.wait([resolve1, resolve2, resolve3]);

      expect(results[0]!.pubKey, equals('pubkey'));
      expect(results[0].hashCode, equals(results[1].hashCode));
      expect(results[1].hashCode, equals(results[2].hashCode));
    });

    test('resolve() uses cache when valid, refetches when expired', () async {
      final client = MockClient(requestHandler);

      final cache = MemCacheManager();
      final nip05Repos = Nip05HttpRepositoryImpl(httpDS: HttpRequestDS(client));
      Nip05Usecase nip05Usecase = Nip05Usecase(
        database: cache,
        nip05Repository: nip05Repos,
      );

      // Save an expired nip05 in cache
      final expiredTimestamp = (DateTime.now()
              .subtract(
                  Duration(seconds: NIP_05_VALID_DURATION.inSeconds + 100))
              .millisecondsSinceEpoch ~/
          1000);
      final expiredNip05 = Nip05(
        pubKey: 'old_pubkey',
        nip05: 'username@example.com',
        valid: true,
        networkFetchTime: expiredTimestamp,
      );
      await cache.saveNip05(expiredNip05);

      // resolve() should refetch because cache is expired
      final result = await nip05Usecase.resolve('username@example.com');
      expect(result, isNotNull);
      expect(
          result!.pubKey, equals('pubkey')); // From network, not 'old_pubkey'

      // Second call should return cached result (now valid)
      final result2 = await nip05Usecase.resolve('username@example.com');
      expect(result2, isNotNull);
      expect(result2!.pubKey, equals('pubkey'));
      expect(result.hashCode, equals(result2.hashCode)); // Same cached object
    });
  });
}
