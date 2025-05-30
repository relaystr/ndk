import 'dart:convert';

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

    test(
        'NIP92 - should handle malformed server response gracefully - dim 1920x1080',
        () {
      final Map<String, dynamic> malformedJson = {
        "url": '',
        "sha256": '',
        "size": "512",
        "type": "notype",
        "nip94": {
          "dim": "1920x1080",
        },
      };

      final Map<String, dynamic> malformedJson2 = {
        "url": '',
        "sha256": '',
        "size": "512",
        "dim": 100,
        "type": "notype",
        "nip94": {
          "dim": 100,
        },
      };

      final result = BlobDescriptor.fromJson(malformedJson);
      final result2 = BlobDescriptor.fromJson(malformedJson2);

      expect(result.nip94!.dimenssions, equals("1920x1080"));
      expect(result2.nip94!.dimenssions, equals("100"));
    });

    test(
        'NIP92 - should handle multiple repeated fields - image / thumb / fallback',
        () {
      final json = '''{
              "url": "https://nostr.download/aaaa.mp4",
              "duration": "24.293322",
              "bitrate": "2227033",
              "x": "aaaa",
              "thumb": "https://nostr.download/thumb/aaaa.webp",
              "m": "video/mp4",
              "dim": "590x1280",
              "size": "6762754",
              "fallback": "https://nostr.download/aaaa.mp4",
              "fallback": "https://nostr.download/bbbb.mp4"
          }''';

      final obj = jsonDecode(json);
      final result = BlobNip94.fromJson(obj);
      expect(result.dimenssions, equals("590x1280"));
      // replaced by second instance (BAD!!)
      // https://github.com/hzrd149/blossom/pull/60
      expect(result.fallback!.first, equals("https://nostr.download/bbbb.mp4"));
      expect(result.thumbnail!.first,
          equals("https://nostr.download/thumb/aaaa.webp"));
    });
  });
}
