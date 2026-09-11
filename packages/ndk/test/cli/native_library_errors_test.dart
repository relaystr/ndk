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

    test('does not classify unrelated load errors', () {
      expect(
        isNativeLibraryLoadError(ArgumentError('Failed to load event data')),
        isFalse,
      );
    });

    test('recognizes dynamic library load errors', () {
      expect(
        isNativeLibraryLoadError(
          ArgumentError('Failed to load dynamic library: library not found'),
        ),
        isTrue,
      );
    });
  });
}
