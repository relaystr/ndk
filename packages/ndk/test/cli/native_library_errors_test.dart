import 'package:ndk/src/cli/native_library_errors.dart';
import 'package:test/test.dart';

void main() {
  group('isNativeLibraryLoadError', () {
    test('recognizes missing native symbol errors', () {
      final error = ArgumentError(
        "Failed to lookup symbol 'verify_schnorr_signature_packed': "
        'dlsym(RTLD_DEFAULT, verify_schnorr_signature_packed): symbol not found',
      );

      expect(isNativeLibraryLoadError(error), isTrue);
    });

    test('does not classify unrelated argument errors', () {
      expect(
        isNativeLibraryLoadError(ArgumentError('Invalid event data')),
        isFalse,
      );
    });
  });
}
