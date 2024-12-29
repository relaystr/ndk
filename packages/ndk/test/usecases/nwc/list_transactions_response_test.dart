import 'package:ndk/domain_layer/usecases/nwc/responses/list_transactions_response.dart';
import 'package:test/test.dart';

void main() {
  group('ListTransactionsResponse', () {
    test('should deserialize correctly from a valid input map', () {
      final input = {
        'result': {
          'transactions': [
            {
              'type': 'incoming',
              'invoice': 'invoice_123',
              'description': 'Test transaction',
              'description_hash': 'hash_123',
              'preimage': 'preimage_123',
              'payment_hash': 'payment_hash_123',
              'amount': 1000,
              'fees_paid': 10,
              'created_at': 1633036800,
              'expires_at': 1633123200,
              'settled_at': 1633040400,
              'metadata': {'key': 'value'},
            }
          ]
        }
      };

      final response = ListTransactionsResponse.deserialize(input);

      expect(response.transactions.length, equals(1));
      final transaction = response.transactions.first;
      expect(transaction.type, equals('incoming'));
      expect(transaction.invoice, equals('invoice_123'));
      expect(transaction.description, equals('Test transaction'));
      expect(transaction.amount, equals(1000));
    });

    test('should throw an exception for invalid input', () {
      final input = {'invalid_key': {}};

      expect(
            () => ListTransactionsResponse.deserialize(input),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('TransactionResult', () {
    test('should calculate amountSat correctly', () {
      final transaction = TransactionResult(
        type: 'incoming',
        paymentHash: 'payment_hash_123',
        amount: 1500,
        feesPaid: 10,
        createdAt: 1633036800,
      );

      expect(transaction.amountSat, equals(1));
    });

    test('should identify incoming transactions', () {
      final transaction = TransactionResult(
        type: 'incoming',
        paymentHash: 'payment_hash_123',
        amount: 1000,
        feesPaid: 10,
        createdAt: 1633036800,
      );

      expect(transaction.isIncoming, isTrue);
    });

    test('should return zapperPubKey if metadata contains nostr kind 9734', () {
      final transaction = TransactionResult(
        type: 'incoming',
        paymentHash: 'payment_hash_123',
        amount: 1000,
        feesPaid: 10,
        createdAt: 1633036800,
        metadata: {
          'nostr': {'kind': 9734, 'pubkey': 'pubkey_123'}
        },
      );

      expect(transaction.zapperPubKey, equals('pubkey_123'));
    });

    test('should return null for zapperPubKey if metadata is null', () {
      final transaction = TransactionResult(
        type: 'incoming',
        paymentHash: 'payment_hash_123',
        amount: 1000,
        feesPaid: 10,
        createdAt: 1633036800,
      );

      expect(transaction.zapperPubKey, isNull);
    });
  });
}