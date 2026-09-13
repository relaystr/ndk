import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ndk/entities.dart';
import 'package:test/test.dart';

void main() {
  const url = 'https://lnbits.example/base';
  const key = 'admin-secret';

  LnBitsWallet wallet() => LnBitsWallet(
        id: 'local-id',
        name: 'My LNbits',
        supportedUnits: const {'sat'},
        lnbitsUrl: url,
        adminKey: key,
      );

  group('LnBitsWallet', () {
    test('normalizes URL and round-trips storage metadata', () {
      final provider = LnBitsWalletProvider(MockClient((_) async {
        throw StateError('not called');
      }));
      final created = provider.createWallet(
        id: 'local-id',
        name: 'My LNbits',
        supportedUnits: const {'sat'},
        metadata: const {
          LnBitsWallet.urlMetadataKey: '$url/',
          LnBitsWallet.adminKeyMetadataKey: ' $key ',
          LnBitsWallet.remoteWalletIdMetadataKey: 'remote-id',
        },
      ) as LnBitsWallet;

      expect(created.lnbitsUrl, url);
      expect(created.adminKey, key);
      expect(created.remoteWalletId, 'remote-id');
      expect(created.canSend, isTrue);
      expect(created.canReceive, isTrue);

      final restored = LnBitsWallet.fromStorage(
        id: created.id,
        name: created.name,
        supportedUnits: created.supportedUnits,
        metadata: created.toMetadata(),
      );
      expect(restored.lnbitsUrl, url);
      expect(restored.adminKey, key);
      expect(restored.remoteWalletId, 'remote-id');
      expect(
          WalletFactory.fromStorage(
            id: created.id,
            name: created.name,
            type: WalletType.LNBITS,
            supportedUnits: created.supportedUnits,
            metadata: created.metadata,
          ),
          isA<LnBitsWallet>());
    });

    test('invoice/read key creates receive-only wallet and round-trips', () {
      final readOnlyWallet = LnBitsWallet(
        id: 'read-only',
        name: 'Read-only LNbits',
        supportedUnits: const {'sat'},
        lnbitsUrl: url,
        adminKey: 'invoice-key',
        readOnly: true,
      );

      expect(readOnlyWallet.canSend, isFalse);
      expect(readOnlyWallet.canReceive, isTrue);
      final restored = LnBitsWallet.fromStorage(
        id: readOnlyWallet.id,
        name: readOnlyWallet.name,
        supportedUnits: readOnlyWallet.supportedUnits,
        metadata: readOnlyWallet.toMetadata(),
      );
      expect(restored.readOnly, isTrue);
      expect(restored.adminKey, 'invoice-key');
    });

    test('rejects invalid URLs and missing credentials', () {
      expect(
        () => LnBitsWalletProvider.normalizeUrl('lnbits.example'),
        throwsFormatException,
      );
      expect(
        () => LnBitsWalletProvider.normalizeUrl('https://lnbits.example?q=1'),
        throwsFormatException,
      );
      expect(
        () => LnBitsWallet.fromStorage(
          id: 'id',
          name: 'name',
          supportedUnits: const {'sat'},
          metadata: const {},
        ),
        throwsArgumentError,
      );
    });
  });

  group('LnBitsWalletProvider', () {
    test('probes credentials, initializes remote id, and reads balance',
        () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode({'id': 'remote-id', 'name': 'Remote', 'balance': 12345}),
          200,
        );
      });
      final provider = LnBitsWalletProvider(client);

      final info = await LnBitsWalletProvider.probe(
        lnbitsUrl: '$url/',
        adminKey: key,
        client: client,
      );
      expect(info.id, 'remote-id');
      expect(info.name, 'Remote');
      expect(info.balanceMsat, 12345);

      final initialized = await provider.initialize(wallet()) as LnBitsWallet;
      expect(initialized.remoteWalletId, 'remote-id');
      final balances = await provider.getBalances(initialized).first;
      expect(balances.single.amount, 12);
      expect(balances.single.unit, 'sat');
      expect(requests, hasLength(3));
      expect(
          requests
              .every((request) => request.url.path == '/base/api/v1/wallet'),
          isTrue);
      expect(requests.every((request) => request.headers['X-Api-Key'] == key),
          isTrue);
    });

    test('creates and pays invoices with Admin Key authentication', () async {
      final requests = <http.Request>[];
      final provider = LnBitsWalletProvider(MockClient((request) async {
        requests.add(request);
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        if (body['out'] == true) {
          return http.Response(
            jsonEncode({
              'payment_hash': 'hash',
              'preimage': 'preimage',
              'fee': -21,
              'time': 10,
            }),
            201,
          );
        }
        return http.Response(
          jsonEncode({
            'payment_hash': 'incoming-hash',
            'payment_request': 'lnbc1invoice',
          }),
          201,
        );
      }));

      final paid = await provider.send(wallet(), 'lnbc1outgoing');
      expect(paid.preimage, 'preimage');
      expect(paid.feesPaid, 21);

      final invoice = await provider.receive(wallet(), 42);
      expect(invoice, 'lnbc1invoice');
      final received = await provider.receiveBip321(
        wallet(),
        amountMsat: 42000,
        description: 'memo',
      );
      expect(received.bip321, 'bitcoin:?lightning=lnbc1invoice');
      expect(received.transactionId, 'incoming-hash');
      expect(requests, hasLength(3));
      expect(requests.every((request) => request.method == 'POST'), isTrue);
      expect(
          requests
              .every((request) => request.url.path == '/base/api/v1/payments'),
          isTrue);
    });

    test('invoice/read key rejects outgoing payments before HTTP request',
        () async {
      var requested = false;
      final provider = LnBitsWalletProvider(MockClient((_) async {
        requested = true;
        return http.Response('{}', 200);
      }));
      final readOnlyWallet = LnBitsWallet(
        id: 'read-only',
        name: 'Read-only LNbits',
        supportedUnits: const {'sat'},
        lnbitsUrl: url,
        adminKey: 'invoice-key',
        readOnly: true,
      );

      await expectLater(
        provider.send(readOnlyWallet, 'lnbc1invoice'),
        throwsUnsupportedError,
      );
      expect(requested, isFalse);
    });

    test('maps pending and completed LNbits transactions', () async {
      final provider = LnBitsWalletProvider(MockClient((_) async {
        return http.Response(
          jsonEncode([
            {
              'payment_hash': 'pending',
              'amount': -2000,
              'pending': true,
              'time': 10,
              'memo': 'Paying',
            },
            {
              'payment_hash': 'settled',
              'amount': 3000,
              'pending': false,
              'status': 'success',
              'time': 20,
            },
          ]),
          200,
        );
      }));

      final pending = await provider.getPendingTransactions(wallet()).first;
      final recent = await provider.getRecentTransactions(wallet()).first;

      expect(pending.single.id, 'pending');
      expect(pending.single.changeAmount, -2);
      expect(pending.single.state, WalletTransactionState.pending);
      expect(recent.single.id, 'settled');
      expect(recent.single.changeAmount, 3);
      expect(recent.single.walletType, WalletType.LNBITS);
    });

    test('reports API detail without exposing Admin Key', () async {
      final provider = LnBitsWalletProvider(MockClient((_) async {
        return http.Response(jsonEncode({'detail': 'Invalid key'}), 401);
      }));

      await expectLater(
        provider.getBalances(wallet()).first,
        throwsA(
          isA<LnBitsApiException>()
              .having((error) => error.statusCode, 'statusCode', 401)
              .having((error) => error.toString(), 'message',
                  contains('Invalid key'))
              .having(
                  (error) => error.toString(), 'secret', isNot(contains(key))),
        ),
      );
    });

    test('rejects outgoing payment when configured with invoice/read key',
        () async {
      final provider = LnBitsWalletProvider(MockClient((_) async {
        throw StateError('HTTP must not be called');
      }));
      final readOnlyWallet = LnBitsWallet(
        id: 'read-only',
        name: 'Read-only LNbits',
        supportedUnits: const {'sat'},
        lnbitsUrl: url,
        adminKey: 'invoice-key',
        readOnly: true,
      );

      await expectLater(
        provider.send(readOnlyWallet, 'lnbc1invoice'),
        throwsUnsupportedError,
      );
    });
  });
}
