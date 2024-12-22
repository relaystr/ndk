import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ndk/domain_layer/usecases/lnurl/lnurl.dart';
import 'package:test/test.dart';

import 'lnurl_test.mocks.dart';

// Mock classes
@GenerateMocks([http.Client])
void main() {
  group('Lnurl', () {

    test('getLud16LinkFromLud16 returns correct URL', () {
      expect(
        Lnurl.getLud16LinkFromLud16('name@domain.com'),
        'https://domain.com/.well-known/lnurlp/name',
      );
    });

    test('getLud16LinkFromLud16 returns null for invalid input', () {
      expect(Lnurl.getLud16LinkFromLud16('invalid'), isNull);
    });

    test('getLnurlResponse returns LnurlResponse for valid link', () async {
      final client = MockClient();
      final link = 'https://domain.com/.well-known/lnurlp/name';
      final response = {
        'callback': 'https://domain.com/callback',
        'commentAllowed': 100,
      };

      // Mock the client.get method
      when(client.get(Uri.parse(link)))
          .thenAnswer((_) async => http.Response(jsonEncode(response), 200));

      var lnurlResponse = await Lnurl.getLnurlResponse(link, client: client);
      expect(lnurlResponse, isNotNull);
      expect(lnurlResponse!.callback, response['callback']);
    });

    test('getLnurlResponse returns null for invalid link', () async {
      final client = MockClient();
      final link = 'https://invalid.com';

      when(client.get(Uri.parse(link)))
          .thenAnswer((_) async => http.Response('Not Found', 404));

      var lnurlResponse = await Lnurl.getLnurlResponse(link, client: client);
      expect(lnurlResponse, isNull);
    });
  });
}
