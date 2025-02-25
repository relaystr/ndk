import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

void main() async {
  group('NIP92 - dont break on evil server', () {
    test('should handle malformed json without throwing', () {
      Map<String, dynamic> evilJson = {
        "url": '',
        "sha256": '',
        "size": 0,
        "type": "notype",
        "nip94": {"evil": "field"},
      };

      expect(
        () => BlobDescriptor.fromJson(evilJson),
        isNot(throwsException),
      );
    });

    test('NIP92 - should handle malformed server response gracefully', () {
      final Map<String, dynamic> malformedJson = {
        "url": '',
        "sha256": '',
        "size": 4897,
        "type": "notype",
        "nip94": {"evil": "field"},
      };

      final result = BlobDescriptor.fromJson(malformedJson);

      expect(result, isA<BlobDescriptor>());
      expect(result.url, isEmpty);
      expect(result.sha256, isEmpty);
      expect(result.size, equals(4897));
      expect(result.type, equals('notype'));
    });

    test(
        'NIP92 - should handle malformed server response gracefully - string int',
        () {
      final Map<String, dynamic> malformedJson = {
        "url": '',
        "sha256": '',
        "size": "512",
        "type": "notype",
        "nip94": {"evil": "field"},
      };

      final result = BlobDescriptor.fromJson(malformedJson);

      expect(result, isA<BlobDescriptor>());
      expect(result.url, isEmpty);
      expect(result.sha256, isEmpty);
      expect(result.size, equals(512));
      expect(result.type, equals('notype'));
    });
  });
}
