import 'package:ndk/domain_layer/usecases/nwc/responses/lookup_invoice_response.dart';
import 'package:test/test.dart';

void main() {
  test('deserializes hold invoice settlement deadline', () {
    final response = LookupInvoiceResponse.deserialize({
      'result_type': 'lookup_invoice',
      'result': {
        'type': 'incoming',
        'invoice': 'lnbc1test',
        'state': 'pending',
        'description': 'hold invoice',
        'description_hash': '',
        'preimage': '',
        'payment_hash': 'hash',
        'amount': 1000,
        'fees_paid': 0,
        'created_at': 1700000000,
        'expires_at': 1700086400,
        'settled_at': null,
        'settle_deadline': 1700000060,
      },
    });

    expect(response.settleDeadline, 1700000060);
  });

  test('allows missing hold invoice settlement deadline', () {
    final response = LookupInvoiceResponse.deserialize({
      'result_type': 'lookup_invoice',
      'result': {
        'type': 'incoming',
        'invoice': 'lnbc1test',
        'state': 'pending',
        'description': 'unpaid invoice',
        'description_hash': '',
        'preimage': '',
        'payment_hash': 'hash',
        'amount': 1000,
        'fees_paid': 0,
        'created_at': 1700000000,
        'expires_at': 1700086400,
        'settled_at': null,
      },
    });

    expect(response.settleDeadline, isNull);
  });
}
