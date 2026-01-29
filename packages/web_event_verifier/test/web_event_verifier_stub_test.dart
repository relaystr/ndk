@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:web_event_verifier/web_event_verifier.dart';

void main() {
  group('WebEventVerifier stub (non-web platforms)', () {
    test('throws UnsupportedError when instantiated on non-web platform', () {
      expect(() => WebEventVerifier(), throwsA(isA<UnsupportedError>()));
    });
  });
}
