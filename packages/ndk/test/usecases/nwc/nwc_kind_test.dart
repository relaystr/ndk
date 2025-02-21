import 'package:ndk/domain_layer/usecases/nwc/consts/nwc_kind.dart';
import 'package:test/test.dart';

void main() {
  group('NwcKind', () {
    test('fromValue returns correct NwcKind for valid values', () {
      expect(NwcKind.fromValue(13194), NwcKind.INFO);
      expect(NwcKind.fromValue(23194), NwcKind.REQUEST);
      expect(NwcKind.fromValue(23195), NwcKind.RESPONSE);
      expect(NwcKind.fromValue(23196), NwcKind.LEGACY_NOTIFICATION);
      expect(NwcKind.fromValue(23197), NwcKind.NOTIFICATION);
    });

    test('fromValue throws ArgumentError for invalid values', () {
      expect(() => NwcKind.fromValue(99999), throwsA(isA<ArgumentError>()));
    });
  });
}
