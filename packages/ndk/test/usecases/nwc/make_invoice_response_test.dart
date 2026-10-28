import 'package:ndk/domain_layer/usecases/nwc/responses/make_invoice_response.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> makeInvoiceResult(Object? feesPaid) => {
    'result_type': 'make_invoice',
    'result': {
      'type': 'incoming',
      'invoice': 'lnbc1test',
      'description': 'invoice',
      'payment_hash': 'hash',
      'amount': 1000,
      'fees_paid': feesPaid,
      'created_at': 1700000000,
      'expires_at': 1700086400,
    },
  };

  test('deserializes fees_paid', () {
    final response = MakeInvoiceResponse.deserialize(makeInvoiceResult(21));

    expect(response.feesPaid, 21);
  });

  test('defaults null fees_paid to 0', () {
    final response = MakeInvoiceResponse.deserialize(makeInvoiceResult(null));

    expect(response.feesPaid, 0);
  });
}
