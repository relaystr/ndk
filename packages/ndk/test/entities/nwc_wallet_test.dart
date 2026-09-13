import 'package:ndk/domain_layer/entities/wallet/providers/nwc/nwc_wallet.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet.dart';
import 'package:ndk/domain_layer/usecases/nwc/consts/nwc_method.dart';
import 'package:test/test.dart';

void main() {
  group('NwcWallet', () {
    test('restores authenticated-response requirement from metadata', () {
      final wallet = NwcWallet.fromStorage(
        id: 'strict-nwc',
        name: 'Coinos',
        supportedUnits: {'sat'},
        metadata: const {
          'nwcUrl':
              'nostr+walletconnect://aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa?relay=wss%3A%2F%2Frelay.example.com&secret=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
          NwcWallet.kRequireAuthenticatedResponseMetadataKey: true,
        },
      );

      expect(wallet.requireAuthenticatedResponse, isTrue);
      expect(
        wallet.toMetadata()[NwcWallet.kRequireAuthenticatedResponseMetadataKey],
        isTrue,
      );
    });

    test('canSend and canReceive use cached permissions from storage', () {
      final wallet = NwcWallet.fromStorage(
        id: 'w1',
        name: 'NWC',
        supportedUnits: {'sat'},
        metadata: {
          'nwcUrl':
              'nostr+walletconnect://a?relay=wss://relay.example&secret=secret',
          NwcWallet.kPermissionsMetadataKey: [
            NwcMethod.MAKE_INVOICE.name,
            NwcMethod.PAY_INVOICE.name,
          ],
          NwcWallet.kProviderIdMetadataKey: 'alby',
        },
      );

      expect(wallet.canReceive, isTrue);
      expect(wallet.canSend, isTrue);
      expect(wallet.providerId, 'alby');
      expect(
        wallet.cachedPermissions,
        containsAll([NwcMethod.MAKE_INVOICE.name, NwcMethod.PAY_INVOICE.name]),
      );
    });

    test('withCachedPermissions returns wallet with updated metadata', () {
      final wallet = NwcWallet(
        id: 'w1',
        name: 'NWC',
        supportedUnits: {'sat'},
        nwcUrl:
            'nostr+walletconnect://a?relay=wss://relay.example&secret=secret',
        providerId: 'coinos',
      );

      final updated = wallet.withCachedPermissions({
        NwcMethod.PAY_INVOICE.name,
      });

      expect(updated.canSend, isTrue);
      expect(updated.canReceive, isFalse);
      expect(updated.providerId, 'coinos');
      expect(updated.metadata[NwcWallet.kPermissionsMetadataKey], [
        NwcMethod.PAY_INVOICE.name,
      ]);
    });

    test('pay and receive permissions enable wallet operations', () {
      final wallet = NwcWallet.fromStorage(
        id: 'w1',
        name: 'NWC',
        supportedUnits: {'sat'},
        metadata: {
          'nwcUrl':
              'nostr+walletconnect://a?relay=wss://relay.example&secret=secret',
          NwcWallet.kPermissionsMetadataKey: [
            NwcMethod.PAY.name,
            NwcMethod.RECEIVE.name,
          ],
        },
      );

      expect(wallet.canSend, isTrue);
      expect(wallet.canReceive, isTrue);
      expect(wallet.supportsBip321Pay, isTrue);
      expect(wallet.supportsBip321Receive, isTrue);
      expect(
        wallet.sendPaymentProtocols,
        containsAll(WalletPaymentProtocol.values),
      );
      expect(
        wallet.receivePaymentProtocols,
        containsAll(WalletPaymentProtocol.values),
      );
    });
  });
}
