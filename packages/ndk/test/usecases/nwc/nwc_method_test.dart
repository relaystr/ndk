import 'package:ndk/domain_layer/usecases/nwc/consts/nwc_method.dart';
import 'package:test/test.dart';

void main() {
  group('NwcMethod', () {
    test('should return the correct NwcMethod for known plaintext', () {
      expect(NwcMethod.fromPlaintext('get_info'), equals(NwcMethod.GET_INFO));
      expect(NwcMethod.fromPlaintext('get_balance'),
          equals(NwcMethod.GET_BALANCE));
      expect(NwcMethod.fromPlaintext('get_budget'),
          equals(NwcMethod.GET_BUDGET));
      expect(NwcMethod.fromPlaintext('pay_invoice'),
          equals(NwcMethod.PAY_INVOICE));
      expect(NwcMethod.fromPlaintext('multi_pay_invoice'),
          equals(NwcMethod.MULTI_PAY_INVOICE));
      expect(NwcMethod.fromPlaintext('pay_keysend'),
          equals(NwcMethod.PAY_KEYSEND));
      expect(NwcMethod.fromPlaintext('multi_pay_keysend'),
          equals(NwcMethod.MULTI_PAY_KEYSEND));
      expect(NwcMethod.fromPlaintext('make_invoice'),
          equals(NwcMethod.MAKE_INVOICE));
      expect(NwcMethod.fromPlaintext('lookup_invoice'),
          equals(NwcMethod.LOOKUP_INVOICE));
      expect(NwcMethod.fromPlaintext('list_transactions'),
          equals(NwcMethod.LIST_TRANSACTIONS));
    });

    test('should return UNKNOWN for unknown plaintext', () {
      expect(
          NwcMethod.fromPlaintext('unknown_method'), equals(NwcMethod.UNKNOWN));
    });
  });
}
