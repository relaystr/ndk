import 'package:ndk/domain_layer/usecases/nwc/consts/error_code.dart';
import 'package:ndk/domain_layer/usecases/nwc/requests/pay.dart';
import 'package:ndk/domain_layer/usecases/nwc/requests/receive.dart';
import 'package:ndk/domain_layer/usecases/nwc/responses/pay_response.dart';
import 'package:ndk/domain_layer/usecases/nwc/responses/receive_response.dart';
import 'package:test/test.dart';

void main() {
  group('NWC-321 errors', () {
    test('maps extension error codes', () {
      expect(ErrorCode.fromValue('BAD_REQUEST'), ErrorCode.badRequest);
      expect(
        ErrorCode.fromValue('UNSUPPORTED_PAYMENT_INSTRUCTION'),
        ErrorCode.unsupportedPaymentInstruction,
      );
      expect(
        ErrorCode.fromValue('UNSUPPORTED_NETWORK'),
        ErrorCode.unsupportedNetwork,
      );
    });
  });

  group('PayRequest', () {
    test('serializes all NWC-321 parameters', () {
      const request = PayRequest(
        payment: 'bitcoin:?lightning=lnbc1invoice',
        amountMsat: 123000,
        payerNote: 'Thanks',
        metadata: {'order_id': '123'},
      );

      expect(request.toMap(), {
        'method': 'pay',
        'params': {
          'payment': 'bitcoin:?lightning=lnbc1invoice',
          'amount': 123000,
          'payer_note': 'Thanks',
          'metadata': {'order_id': '123'},
        },
      });
    });

    test('omits optional parameters', () {
      const request = PayRequest(
        payment: 'bitcoin:?lightning=lnbc1invoice',
      );

      expect(request.toMap(), {
        'method': 'pay',
        'params': {'payment': 'bitcoin:?lightning=lnbc1invoice'},
      });
    });
  });

  group('ReceiveRequest', () {
    test('serializes all NWC-321 parameters', () {
      const request = ReceiveRequest(
        amountMsat: 123000,
        description: 'Coffee',
        metadata: {'order_id': '123'},
      );

      expect(request.toMap(), {
        'method': 'receive',
        'params': {
          'amount': 123000,
          'description': 'Coffee',
          'metadata': {'order_id': '123'},
        },
      });
    });

    test('omits amount for a variable-amount instruction', () {
      const request = ReceiveRequest();

      expect(request.toMap(), {'method': 'receive', 'params': {}});
    });
  });

  group('PayResponse', () {
    test('deserializes a settled bolt11 payment', () {
      final response = PayResponse.deserialize({
        'result_type': 'pay',
        'result': {
          'transaction_id': 'transaction-1',
          'state': 'settled',
          'instruction_type': 'bolt11',
          'amount': 123456,
          'fees_paid': 1000,
          'payment_hash': 'payment-hash',
          'preimage': 'preimage',
          'payer_proof': 'proof',
          'txid': 'txid',
          'failure_reason': null,
          'created_at': 1700000000,
          'settled_at': 1700000001,
        },
      });

      expect(response.resultType, 'pay');
      expect(response.transactionId, 'transaction-1');
      expect(response.state, 'settled');
      expect(response.instructionType, 'bolt11');
      expect(response.amountMsat, 123456);
      expect(response.amountSat, 123);
      expect(response.feesPaid, 1000);
      expect(response.paymentHash, 'payment-hash');
      expect(response.preimage, 'preimage');
      expect(response.payerProof, 'proof');
      expect(response.txid, 'txid');
      expect(response.failureReason, isNull);
      expect(response.createdAt, 1700000000);
      expect(response.settledAt, 1700000001);
    });

    test('deserializes optional fields when absent', () {
      final response = PayResponse.deserialize({
        'result_type': 'pay',
        'result': {
          'transaction_id': 'transaction-1',
          'state': 'pending',
          'instruction_type': 'bolt11',
          'amount': 123000,
          'fees_paid': 0,
          'created_at': 1700000000,
        },
      });

      expect(response.paymentHash, isNull);
      expect(response.preimage, isNull);
      expect(response.payerProof, isNull);
      expect(response.txid, isNull);
      expect(response.failureReason, isNull);
      expect(response.settledAt, isNull);
    });
  });

  group('ReceiveResponse', () {
    test('deserializes a bolt11 BIP-321 URI', () {
      final response = ReceiveResponse.deserialize({
        'result_type': 'receive',
        'result': {
          'bip321': 'bitcoin:?lightning=lnbc1invoice',
          'transaction_id': 'transaction-1',
        },
      });

      expect(response.resultType, 'receive');
      expect(response.bip321, 'bitcoin:?lightning=lnbc1invoice');
      expect(response.transactionId, 'transaction-1');
    });

    test('allows an absent transaction identifier', () {
      final response = ReceiveResponse.deserialize({
        'result_type': 'receive',
        'result': {'bip321': 'bitcoin:?lightning=lnbc1invoice'},
      });

      expect(response.transactionId, isNull);
    });
  });
}
