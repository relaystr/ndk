import 'package:ndk/domain_layer/entities/nip_05.dart';
import 'package:test/test.dart';

void main() {
  group('Nip05.canonicalIdentifier', () {
    test('lowercases and trims', () {
      expect(Nip05.canonicalIdentifier(' Bob@Example.COM '), 'bob@example.com');
    });

    test('a bare domain becomes _@domain', () {
      expect(Nip05.canonicalIdentifier('example.com'), '_@example.com');
    });

    test('rejects malformed identifiers', () {
      expect(Nip05.canonicalIdentifier(''), isNull);
      expect(Nip05.canonicalIdentifier('@example.com'), isNull);
      expect(Nip05.canonicalIdentifier('bob@'), isNull);
      expect(Nip05.canonicalIdentifier('a@b@example.com'), isNull);
    });
  });
}
