import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:mockito/annotations.dart';
import 'package:ndk/data_layer/data_sources/http_request.dart';
import 'package:ndk/data_layer/repositories/nip_05_http_impl.dart';
import 'package:ndk/domain_layer/entities/nip_05.dart';
import 'package:ndk/domain_layer/usecases/nip05/verify_nip_05.dart';
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
    test('returns Nip05 if the http call completes successfully', () async {
      final client = MockClient(requestHandler);

      final cache = MemCacheManager();
      final nip05Repos = Nip05RepositoryImpl(httpDS: HttpRequestDS(client));

      VerifyNip05 verifyNip05 = VerifyNip05(
        database: cache,
        nip05Repository: nip05Repos,
      );

      await Future.delayed(const Duration(milliseconds: 10));

      expect(
          await verifyNip05.check(
              nip05: 'username@example.com', pubkey: 'pubkey'),
          isA<Nip05>());
    });

    test('return false if the http call completes with an error', () async {
      final client = MockClient(requestHandlerErr);

      final cache = MemCacheManager();
      final nip05Repos = Nip05RepositoryImpl(httpDS: HttpRequestDS(client));

      VerifyNip05 verifyNip05 = VerifyNip05(
        database: cache,
        nip05Repository: nip05Repos,
      );

      var result =
          await verifyNip05.check(nip05: 'username@url.test', pubkey: 'pubkey');

      expect(result.valid, false);
    });

    test('result is invalid', () async {
      final client = MockClient(requestHandler);
      final cache = MemCacheManager();
      final nip05Repos = Nip05RepositoryImpl(httpDS: HttpRequestDS(client));

      VerifyNip05 verifyNip05 = VerifyNip05(
        database: cache,
        nip05Repository: nip05Repos,
      );

      var result = await verifyNip05.check(
          nip05: 'username@url.test', pubkey: 'non-existing-pubkey');

      expect(result.valid, false);
    });

    test('result is valid', () async {
      final client = MockClient(requestHandler);

      final cache = MemCacheManager();
      final nip05Repos = Nip05RepositoryImpl(httpDS: HttpRequestDS(client));

      VerifyNip05 verifyNip05 = VerifyNip05(
        database: cache,
        nip05Repository: nip05Repos,
      );

      var result =
          await verifyNip05.check(nip05: 'username@url.test', pubkey: 'pubkey');

      expect(result.valid, true);
    });

    test('result is valid with _ as name', () async {
      final client = MockClient(requestHandler2);

      final cache = MemCacheManager();
      final nip05Repos = Nip05RepositoryImpl(httpDS: HttpRequestDS(client));

      VerifyNip05 verifyNip05 = VerifyNip05(
        database: cache,
        nip05Repository: nip05Repos,
      );

      var result = await verifyNip05.check(
          nip05: 'domain@domain.test', pubkey: 'pubkey');

      expect(result.valid, true);
    });

    test('spam requests - check in flight', () async {
      final client = MockClient(requestHandler);

      final cache = MemCacheManager();
      final nip05Repos = Nip05RepositoryImpl(httpDS: HttpRequestDS(client));

      VerifyNip05 verifyNip05 = VerifyNip05(
        database: cache,
        nip05Repository: nip05Repos,
      );

      final check1 =
          verifyNip05.check(nip05: 'username@url.test', pubkey: 'pubkey');
      final check2 = verifyNip05.check(
          nip05: 'somethingDiffrent@url.test', pubkey: 'pubkey');
      final check3 =
          verifyNip05.check(nip05: 'username@url.test', pubkey: 'pubkey');
      final check4 =
          verifyNip05.check(nip05: 'username@url.test', pubkey: 'pubkey');

      final results = await Future.wait([check1, check2, check3, check4]);

      expect(results.first.valid, true);
      expect(results.last.valid, true);
      expect(results.first.hashCode, equals(results.last.hashCode));
    });
  });
}
