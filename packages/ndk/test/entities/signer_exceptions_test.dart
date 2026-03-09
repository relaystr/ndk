import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

void main() {
  group('SignerRequestRejectedException', () {
    test('toString with requestId and message', () {
      final e = SignerRequestRejectedException(
        requestId: 'req123',
        originalMessage: 'denied',
      );
      expect(e.toString(), contains('req123'));
      expect(e.toString(), contains('denied'));
    });

    test('toString with only requestId', () {
      final e = SignerRequestRejectedException(requestId: 'req456');
      expect(e.toString(), contains('req456'));
    });

    test('toString with only message', () {
      final e = SignerRequestRejectedException(originalMessage: 'error');
      expect(e.toString(), contains('error'));
    });

    test('toString with no params', () {
      final e = SignerRequestRejectedException();
      expect(e.toString(), contains('SignerRequestRejectedException'));
    });
  });

  group('SignerRequestCancelledException', () {
    test('toString formats correctly', () {
      final e = SignerRequestCancelledException('req789');
      expect(e.toString(), contains('req789'));
    });
  });
}
