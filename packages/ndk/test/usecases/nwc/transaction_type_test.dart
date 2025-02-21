import 'package:ndk/domain_layer/usecases/nwc/consts/transaction_type.dart';
import 'package:test/test.dart';

void main() {
  group('TransactionType', () {
    test('fromValue returns incoming for unknown value', () {
      expect(TransactionType.fromValue('unknown'), TransactionType.incoming);
    });

    test('fromValue returns outgoing for outgoing value', () {
      expect(TransactionType.fromValue('outgoing'), TransactionType.outgoing);
    });

    test('fromValue returns incoming for incoming value', () {
      expect(TransactionType.fromValue('incoming'), TransactionType.incoming);
    });
  });
}
