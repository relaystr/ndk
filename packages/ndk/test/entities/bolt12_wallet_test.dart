import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ndk/entities.dart';
import 'package:test/test.dart';

const _offer =
    'lno1pqqq5xj5wajkcan9gdshx6pq23jhxarfdenjqstyv3ex2umnzcss80xkrjkyrjk43u5dgu8f6a450fg2cnjtg7lhg76c3gtk5gdhshns';
const _blindedPathOffer =
    'lno1pgqppmsrse80qf0aara4slvcjxrvu6j2rp5ftmjy4yntlsmsutpkvkt6878sx37ttar5fpecarm57v2y2can2uxq02l7k0er7czs6gsuzkdhe4tlqgpat4k4mrvvjwla3whdhmkvdtfq98w4jlg8wgsf26cndmndd0c33fqqx0y9hunesw4caaxfnw3uam5yy4kxtuqvujapdx93sd24wt7mdpeukuw46tp5zugxceqrr2ffkzpjcen3p77sy8jk8v7h04wlp9lg6ls76xqcn3nethq7e7553xn3vugt5vzlea2sqqedvc6k8r8hetzw9tvnlnw9muh4vaywdn5jgvj80ad3r9600ang39vvjnvn0aytg07ss05v6g9ru45p2srs';

void main() {
  group('Bolt12WalletProvider input resolution', () {
    test('accepts and decodes a direct offer', () async {
      final resolved = await Bolt12WalletProvider.resolveInput(_offer);

      expect(resolved.offer, _offer);
      expect(resolved.decoded['type'], 'offer');
      expect(resolved.decoded['valid'], isTrue);
      expect(resolved.decoded['offer_description'], isNotEmpty);
      expect(resolved.toMetadata(), isNot(contains('offerId')));
    });

    test('extracts an offer from a BIP321 URI', () async {
      final resolved = await Bolt12WalletProvider.resolveInput(
        'bitcoin:?amount=1&lno=${_offer.toUpperCase()}',
      );

      expect(resolved.offer, _offer);
      expect(resolved.bip353Address, isNull);
    });

    test('accepts the commonly scanned bitcoin?lno shorthand', () async {
      final resolved = await Bolt12WalletProvider.resolveInput(
        'bitcoin?lno=$_offer',
      );

      expect(resolved.offer, _offer);
    });

    test('accepts a current blinded-path offer in BIP321', () async {
      final resolved = await Bolt12WalletProvider.resolveInput(
        'bitcoin:?lno=$_blindedPathOffer',
      );

      expect(resolved.offer, _blindedPathOffer);
      expect(resolved.decoded['type'], 'offer');
      expect(resolved.decoded['valid'], isTrue);
      expect(resolved.toMetadata()['hasBlindedPaths'], isTrue);
      expect(resolved.toMetadata()['description'], isNull);
      expect(resolved.toMetadata()['amount'], isNull);
    });

    test('resolves BIP353 and remembers its address', () async {
      String? requestedAddress;
      final resolved = await Bolt12WalletProvider.resolveInput(
        '₿alice@example.com',
        bip353Resolver: (address) async {
          requestedAddress = address;
          return _offer;
        },
      );

      expect(requestedAddress, 'alice@example.com');
      expect(resolved.offer, _offer);
      expect(resolved.bip353Address, 'alice@example.com');
    });

    test('rejects BIP353 records without an offer', () async {
      expect(
        () => Bolt12WalletProvider.resolveInput(
          'alice@example.com',
          bip353Resolver: (_) async => null,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('resolves DNSSEC-authenticated BIP353 through custom DoH', () async {
      final endpoint = Uri.parse('https://resolver.example/dns-query');
      final client = MockClient((request) async {
        expect(request.url.origin + request.url.path, endpoint.toString());
        expect(
          request.url.queryParameters['name'],
          'alice.user._bitcoin-payment.example.com',
        );
        expect(request.url.queryParameters['type'], 'TXT');
        expect(request.headers['Accept'], 'application/dns-json');
        return http.Response(
          jsonEncode({
            'Status': 0,
            'AD': true,
            'Answer': [
              {
                'type': 16,
                'data': '"bitcoin:?lno=${_offer.substring(0, 60)}" '
                    '"${_offer.substring(60)}"',
              },
            ],
          }),
          200,
        );
      });

      final resolved = await Bolt12WalletProvider.resolveInput(
        'alice@example.com',
        bip353DohEndpoint: endpoint,
        httpClient: client,
      );

      expect(resolved.offer, _offer);
    });

    test('rejects BIP353 response without DNSSEC authentication', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'Status': 0,
            'AD': false,
            'Answer': [
              {'type': 16, 'data': '"bitcoin:?lno=$_offer"'},
            ],
          }),
          200,
        ),
      );

      expect(
        () => Bolt12WalletProvider.resolveInput(
          'alice@example.com',
          httpClient: client,
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('DNSSEC'),
          ),
        ),
      );
    });

    test('rejects malformed input', () async {
      expect(
        () => Bolt12WalletProvider.resolveInput('not a payment target'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  test('wallet is receive-only and round-trips through storage', () async {
    final resolved = await Bolt12WalletProvider.resolveInput(_offer);
    const provider = Bolt12WalletProvider();
    final wallet = provider.createWallet(
      id: 'bolt12-1',
      name: 'Donations',
      supportedUnits: {'sat'},
      metadata: resolved.toMetadata(),
    ) as Bolt12Wallet;

    expect(wallet.type, WalletType.BOLT12);
    expect(wallet.canReceive, isTrue);
    expect(wallet.canSend, isFalse);
    expect(
      await provider.receive(wallet, 123),
      'bitcoin:?amount=0.00000123&lno=$_offer',
    );
    final bip321 = await provider.receiveBip321(wallet);
    expect(bip321.bip321, 'bitcoin:?lno=$_offer');
    final bip321WithAmount = await provider.receiveBip321(
      wallet,
      amountMsat: 123001,
    );
    expect(
      bip321WithAmount.bip321,
      'bitcoin:?amount=0.00000123001&lno=$_offer',
    );
    expect(
      () => provider.send(wallet, 'lnbc...'),
      throwsA(isA<UnsupportedError>()),
    );

    final restored = WalletFactory.fromStorage(
      id: wallet.id,
      name: wallet.name,
      type: wallet.type,
      supportedUnits: wallet.supportedUnits,
      metadata: wallet.toMetadata(),
    ) as Bolt12Wallet;
    expect(restored.offer, wallet.offer);
    expect(restored.description, wallet.description);
    expect(restored.issuer, wallet.issuer);
    expect(restored.hasBlindedPaths, wallet.hasBlindedPaths);
  });
}
