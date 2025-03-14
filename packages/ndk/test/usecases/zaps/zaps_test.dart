import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ndk/data_layer/data_sources/http_request.dart';
import 'package:ndk/data_layer/repositories/lnurl_http_impl.dart';
import 'package:ndk/data_layer/repositories/signers/bip340_event_signer.dart';
import 'package:ndk/domain_layer/usecases/lnurl/lnurl.dart';
import 'package:ndk/domain_layer/usecases/zaps/zap_request.dart';
import 'package:ndk/domain_layer/usecases/zaps/zaps.dart';
import 'package:ndk/presentation_layer/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import '../lnurl/lnurl_test.mocks.dart';

// Mock classes
@GenerateMocks([http.Client])
void main() {
  group('Zaps', () {
    KeyPair key = Bip340.generatePrivateKey();

    test('fetchInvoice returns invoice code for valid input', () async {
      final client = MockClient();
      final response = {
        'callback': 'https://domain.com/callback',
        'commentAllowed': 100,
        'allowsNostr': true,
      };
      final link = 'https://domain.com/.well-known/lnurlp/name';

      // Mock the client.get method
      when(client.get(Uri.parse(link), headers: {"Accept": "application/json"}))
          .thenAnswer((_) async => http.Response(jsonEncode(response), 200));

      when(client.get(
              argThat(
                TypeMatcher<Uri>().having((uri) => uri.toString(), 'uri',
                    startsWith('https://domain.com/callback')),
              ),
              headers: {"Accept": "application/json"}))
          .thenAnswer((_) async => http.Response(
              jsonEncode({
                "status": "OK",
                "successAction": {
                  "tag": "message",
                  "message": "Payment Received!"
                },
                "routes": [],
                "pr": "lnbc1000...."
              }),
              200));
      final amount = 1000;

      final ndk = Ndk.defaultConfig();
      final transport = LnurlTransportHttpImpl(HttpRequestDS(client));
      final Lnurl lnurl = Lnurl(transport: transport);
      final zaps = Zaps(requests: ndk.requests, nwc: ndk.nwc, lnurl: lnurl);
      // Logger.setLogLevel(Logger.logLevels.trace);

      ZapRequest zapRequest = await zaps.createZapRequest(
          amountSats: amount,
          eventId: 'eventId',
          comment: 'comment',
          signer: Bip340EventSigner(
              privateKey: key.privateKey, publicKey: key.publicKey),
          pubKey: 'pubKey',
          relays: ['relay1', 'relay2']);

      var invoiceResponse = await zaps.fetchInvoice(
        lud16Link: link,
        amountSats: amount,
        zapRequest: zapRequest,
      );
      expect(invoiceResponse!.amountSats, amount);
      expect(invoiceResponse.invoice, startsWith("lnbc$amount"));
    });

    test('fetchInvoice returns null for invalid input', () async {
      Ndk ndk = Ndk.defaultConfig();
      var invoiceCode = await ndk.zaps.fetchInvoice(
        lud16Link: 'invalid',
        amountSats: 1000,
      );
      expect(invoiceCode, isNull);
    });

    test('zapRequest returns valid ZapRequest for correct inputs', () async {
      final amount = 1000;
      final eventId = 'eventId';
      final comment = 'comment';
      final pubKey = 'pubKey';
      final relays = ['relay1', 'relay2'];
      Ndk ndk = Ndk.defaultConfig();

      ZapRequest zapRequest = await ndk.zaps.createZapRequest(
        amountSats: amount,
        eventId: eventId,
        comment: comment,
        signer: Bip340EventSigner(
            privateKey: key.privateKey, publicKey: key.publicKey),
        pubKey: pubKey,
        relays: relays,
      );

      expect(zapRequest, isNotNull);
      expect(
          zapRequest.tags,
          containsAll([
            ['amount', (amount * 1000).toString()],
            ['e', eventId],
            ['p', pubKey],
            ['relays', ...relays]
          ]));
      expect(zapRequest.content, comment);
      expect(zapRequest.sig, isNotEmpty);
    });

    test('zapRequest throws error for negative amount', () async {
      Ndk ndk = Ndk.defaultConfig();

      expect(
        () async => await ndk.zaps.createZapRequest(
          amountSats: -1000,
          eventId: 'eventId',
          comment: 'comment',
          signer: Bip340EventSigner(
              privateKey: key.privateKey, publicKey: key.publicKey),
          pubKey: 'pubKey',
          relays: ['relay1', 'relay2'],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('zapRequest handles empty relays list', () async {
      Ndk ndk = Ndk.defaultConfig();

      ZapRequest zapRequest = await ndk.zaps.createZapRequest(
        amountSats: 1000,
        eventId: 'eventId',
        comment: 'comment',
        signer: Bip340EventSigner(
            privateKey: key.privateKey, publicKey: key.publicKey),
        pubKey: 'pubKey',
        relays: [],
      );

      expect(zapRequest, isNotNull);
    });
  });
}
