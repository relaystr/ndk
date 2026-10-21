import 'package:ndk/domain_layer/usecases/nwc/responses/pay_invoice_response.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> payInvoiceResult(Object? feesPaid) => {
    'result_type': 'pay_invoice',
    'result': {'preimage': 'preimage', 'fees_paid': feesPaid},
  };

  test('deserializes fees_paid', () {
    final response = PayInvoiceResponse.deserialize(payInvoiceResult(21));

    expect(response.feesPaid, 21);
  });

  test('defaults null fees_paid to 0', () {
    final response = PayInvoiceResponse.deserialize(payInvoiceResult(null));

    expect(response.feesPaid, 0);
  });
}
