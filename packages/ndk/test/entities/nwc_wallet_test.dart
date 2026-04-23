import 'package:ndk/domain_layer/entities/wallet/providers/nwc/nwc_wallet.dart';
import 'package:ndk/domain_layer/usecases/nwc/consts/nwc_method.dart';
import 'package:test/test.dart';

void main() {
  group('NwcWallet', () {
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
        },
      );

      expect(wallet.canReceive, isTrue);
      expect(wallet.canSend, isTrue);
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
      );

      final updated =
          wallet.withCachedPermissions({NwcMethod.PAY_INVOICE.name});

      expect(updated.canSend, isTrue);
      expect(updated.canReceive, isFalse);
      expect(
        updated.metadata[NwcWallet.kPermissionsMetadataKey],
        [NwcMethod.PAY_INVOICE.name],
      );
    });
  });
}
