import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

void main() {
  group('NwcExtension', () {
    test('maps the registered NWC extension identifiers', () {
      expect(NwcExtension.fromIdentifier('02'), NwcExtension.notifications);
      expect(NwcExtension.fromIdentifier('03'), NwcExtension.holdInvoices);
      expect(NwcExtension.fromIdentifier('04'), NwcExtension.keysend);
      expect(
        NwcExtension.fromIdentifier('05'),
        NwcExtension.transactionHistory,
      );
      expect(
        NwcExtension.fromIdentifier('06'),
        NwcExtension.metadata,
      );
      expect(NwcExtension.fromIdentifier('07'), NwcExtension.deepLinks);
      expect(
        NwcExtension.fromIdentifier('321'),
        NwcExtension.bip321,
      );
    });

    test('parses space-separated values and ignores unknown extensions', () {
      expect(
        NwcExtension.fromIdentifiers(['02  03\t321', '999']),
        {
          NwcExtension.notifications,
          NwcExtension.holdInvoices,
          NwcExtension.bip321,
        },
      );
      expect(NwcExtension.fromIdentifier('999'), isNull);
    });
  });

  group('GetInfoResponse extensions', () {
    test('deserializes and checks supported extensions', () {
      final response = GetInfoResponse.deserialize({
        'result_type': 'get_info',
        'result': {
          'alias': 'wallet',
          'network': 'mainnet',
          'methods': ['pay_invoice'],
          'extensions': ['02', '05', 'unknown'],
        },
      });

      expect(
        response.extensions,
        {NwcExtension.notifications, NwcExtension.transactionHistory},
      );
      expect(response.supportsExtension(NwcExtension.notifications), isTrue);
      expect(response.supportsExtension(NwcExtension.holdInvoices), isFalse);
    });

    test('defaults to no extensions when the optional field is absent', () {
      final response = GetInfoResponse.deserialize({
        'result_type': 'get_info',
        'result': {'alias': 'wallet', 'network': 'mainnet'},
      });

      expect(response.extensions, isEmpty);
    });
  });

  test('NwcConnection can add and check advertised extensions', () {
    final connection = NwcConnection(
      NostrWalletConnectUri(
        walletPubkey: 'wallet-pubkey',
        relays: ['wss://relay.example.com'],
        secret: 'secret',
      ),
      eventSignerFactory: const Bip340EventSignerFactory(),
    );

    connection.addSupportedExtensions(['02 04']);

    expect(connection.supportsExtension(NwcExtension.notifications), isTrue);
    expect(connection.supportsExtension(NwcExtension.keysend), isTrue);
    expect(connection.supportsExtension(NwcExtension.holdInvoices), isFalse);
  });
}
