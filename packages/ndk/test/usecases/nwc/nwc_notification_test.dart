import 'package:ndk/domain_layer/usecases/nwc/nwc_notification.dart';
import 'package:test/test.dart';

void main() {
  group('NwcNotification', () {
    test('should create an instance from a map', () {
      final map = {
        'type': 'payment_received',
        'invoice': 'invoice_123',
        'description': 'Test payment',
        'description_hash': 'hash_123',
        'preimage': 'preimage_123',
        'payment_hash': 'payment_hash_123',
        'amount': 1000,
        'fees_paid': 10,
        'created_at': 1633036800,
        'expires_at': 1633123200,
        'settled_at': 1633040400,
        'metadata': {'key': 'value'},
      };

      final notification = NwcNotification.fromMap(map);

      expect(notification.type, equals('payment_received'));
      expect(notification.invoice, equals('invoice_123'));
      expect(notification.description, equals('Test payment'));
      expect(notification.descriptionHash, equals('hash_123'));
      expect(notification.preimage, equals('preimage_123'));
      expect(notification.paymentHash, equals('payment_hash_123'));
      expect(notification.amount, equals(1000));
      expect(notification.feesPaid, equals(10));
      expect(notification.createdAt, equals(1633036800));
      expect(notification.expiresAt, equals(1633123200));
      expect(notification.settledAt, equals(1633040400));
      expect(notification.metadata, equals({'key': 'value'}));
    });

    test('should identify incoming transactions', () {
      final notification = NwcNotification(
        type: 'incoming',
        invoice: 'invoice_123',
        preimage: 'preimage_123',
        paymentHash: 'payment_hash_123',
        amount: 1000,
        feesPaid: 10,
        createdAt: 1633036800,
        settledAt: 1633040400,
        metadata: {'key': 'value'},
      );

      expect(notification.isIncoming, isTrue);
    });

    test('should handle null metadata', () {
      final map = {
        'type': 'payment_sent',
        'invoice': 'invoice_123',
        'preimage': 'preimage_123',
        'payment_hash': 'payment_hash_123',
        'amount': 1000,
        'fees_paid': 10,
        'created_at': 1633036800,
        'settled_at': 1633040400,
      };

      final notification = NwcNotification.fromMap(map);

      expect(notification.metadata, isNull);
    });
  });
}