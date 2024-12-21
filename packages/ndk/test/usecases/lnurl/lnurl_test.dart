import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ndk/data_layer/repositories/signers/bip340_event_signer.dart';
import 'package:ndk/domain_layer/usecases/lnurl/lnurl.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import 'lnurl_test.mocks.dart';

// Mock classes
@GenerateMocks([http.Client])
void main() {
  group('Lnurl', () {
    KeyPair key = Bip340.generatePrivateKey();

    test('getLud16LinkFromLud16 returns correct URL', () {
      expect(
        Lnurl.getLud16LinkFromLud16('name@domain.com'),
        'https://domain.com/.well-known/lnurlp/name',
      );
    });

    test('getLud16LinkFromLud16 returns null for invalid input', () {
      expect(Lnurl.getLud16LinkFromLud16('invalid'), isNull);
    });

    test('getLnurlFromLud16 returns correct lnurl', () {
      // Assuming the Nip19.convertBits and Bech32Encoder are working correctly
      // This test would need to be adjusted based on the actual implementation
      var lnurl = Lnurl.getLnurlFromLud16('name@domain.com');
      expect(lnurl, isNotNull);
      expect(lnurl, startsWith('LNURL'));
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

    test('getInvoiceCode returns invoice code for valid input', () async {
      final client = MockClient();
      final response = {
        'callback': 'https://domain.com/callback',
        'commentAllowed': 100,
        'allowsNostr': true,
      };
      final link = 'https://domain.com/.well-known/lnurlp/name';

      // Mock the client.get method
      when(client.get(Uri.parse(link)))
          .thenAnswer((_) async => http.Response(jsonEncode(response), 200));

      when(client.get(argThat(
        TypeMatcher<Uri>().having((uri) => uri.toString(), 'uri',
            startsWith('https://domain.com/callback')),
      ))).thenAnswer((_) async => http.Response(
          jsonEncode({
            "status": "OK",
            "successAction": {"tag": "message", "message": "Payment Received!"},
            "routes": [],
            "pr": "lnbc100...."
          }),
          200));

      var invoiceCode = await Lnurl.getInvoiceCode(
          lud16Link: link,
          sats: 1000,
          signer: Bip340EventSigner(privateKey: key.privateKey, publicKey: key.publicKey),
          pubKey: 'pubKey',
          eventId: 'eventId',
          relays: ['relay1', 'relay2'],
          pollOption: 'option',
          comment: 'comment',
          client: client);
      expect(invoiceCode, startsWith("lnbc100"));
    });

    test('getInvoiceCode returns null for invalid input', () async {
      var invoiceCode = await Lnurl.getInvoiceCode(
        lud16Link: 'invalid',
        sats: 1000,
      );
      expect(invoiceCode, isNull);
    });
  });
}
