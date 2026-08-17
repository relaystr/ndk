import 'package:ndk/domain_layer/entities/wallet/bip321.dart';
import 'package:test/test.dart';

void main() {
  group('Bip321', () {
    test('round-trips a BOLT11 instruction', () {
      const invoice = 'lnbc210n1paymentdata';

      final payment = Bip321.fromBolt11(invoice);

      expect(payment, 'bitcoin:?lightning=lnbc210n1paymentdata');
      expect(Bip321.getBolt11(payment), invoice);
    });

    test('decodes BOLT11 amounts in millisatoshis', () {
      expect(Bip321.getBolt11AmountMsat('lnbc1paymentdata'), isNull);
      expect(Bip321.getBolt11AmountMsat('lnbc210n1paymentdata'), 21000);
      expect(Bip321.getBolt11AmountMsat('lnbc2m1paymentdata'), 200000000);
      expect(Bip321.getBolt11AmountMsat('lntb3u1paymentdata'), 300000);
      expect(Bip321.getBolt11AmountMsat('lnbcrt4n1paymentdata'), 400);
      expect(Bip321.getBolt11AmountMsat('lnsb50p1paymentdata'), 5);
    });

    test('rejects unknown required parameters', () {
      expect(
        () => Bip321.getBolt11(
          'bitcoin:?lightning=lnbc1paymentdata&req-example=value',
        ),
        throwsUnsupportedError,
      );
    });

    test('rejects missing and duplicate lightning instructions', () {
      expect(
        () => Bip321.getBolt11('bitcoin:?amount=1'),
        throwsFormatException,
      );
      expect(
        () => Bip321.getBolt11(
          'bitcoin:?lightning=lnbc1first&lightning=lnbc1second',
        ),
        throwsFormatException,
      );
    });
  });
}
