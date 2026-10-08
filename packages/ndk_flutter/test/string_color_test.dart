import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndk_flutter/utils/string_color.dart';

/// Reference values were computed independently from the "String Color"
/// specification (NIP-54 wiki, kind 30818 / d-tag `string-color`) to guard
/// against regressions in the Dart implementation.
void main() {
  Color rgb(int r, int g, int b) => Color.fromARGB(255, r, g, b);

  group('StringColor.fromString', () {
    test('empty input returns neutral grey', () {
      expect(StringColor.fromString(''), StringColor.neutralGrey);
      expect(StringColor.fromString('   '), StringColor.neutralGrey);
    });

    test('text input uses the polynomial hash path', () {
      expect(StringColor.fromString('alice'), rgb(230, 69, 216));
      expect(StringColor.fromString('Bob'), rgb(83, 179, 54));
      expect(StringColor.fromString('hello world'), rgb(119, 73, 245));
    });

    test('normalization is case-insensitive and trims whitespace', () {
      final canonical = StringColor.fromString('Bob');
      expect(StringColor.fromString('bob'), canonical);
      expect(StringColor.fromString('  BOB  '), canonical);
    });

    test('hex input uses the direct BigInt path', () {
      expect(
        StringColor.fromString(
          '660d8c78651f70487ec9b8ddc283e29cf2561693dda3ba246d3fd3c08dbb7083',
        ),
        rgb(57, 191, 189),
      );
      expect(StringColor.fromString('deadbeef'), rgb(60, 191, 57));
      // Short all-hex strings are auto-detected as hex.
      expect(StringColor.fromString('ABC'), rgb(73, 108, 245));
    });

    test('dark text adjustment brightens by 8%', () {
      expect(
        StringColor.fromString('alice', textBrightness: Brightness.dark),
        rgb(248, 75, 233),
      );
    });

    test('light text adjustment darkens by 5%', () {
      expect(
        StringColor.fromString('alice', textBrightness: Brightness.light),
        rgb(219, 66, 205),
      );
    });

    test('text adjustment clamps channels to 255', () {
      // hello world -> base blue (119, 73, 245); dark pushes B past 255.
      expect(
        StringColor.fromString('hello world', textBrightness: Brightness.dark),
        rgb(129, 79, 255),
      );
    });
  });
}
