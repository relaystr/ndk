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

      expect(result.nip94!.dimensions, equals("1920x1080"));
      expect(result2.nip94!.dimensions, equals("100"));
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
      expect(result.dimensions, equals("590x1280"));
      // replaced by second instance (BAD!!)
      // https://github.com/hzrd149/blossom/pull/60
      expect(result.fallback!.first, equals("https://nostr.download/bbbb.mp4"));
      expect(result.thumbnail!.first,
          equals("https://nostr.download/thumb/aaaa.webp"));
    });

    test('size is null when missing or unparseable, not 0', () {
      final missing = BlobDescriptor.fromJson({
        "url": '',
        "sha256": '',
        "type": "notype",
      });
      final garbage = BlobDescriptor.fromJson({
        "url": '',
        "sha256": '',
        "size": "not-a-number",
        "type": "notype",
      });
      expect(missing.size, isNull);
      expect(garbage.size, isNull);
    });

    test('dimensions is null when dim is missing, not the string "null"', () {
      final result = BlobNip94.fromJson({
        "url": '',
        "x": '',
        "m": '',
      });
      expect(result.dimensions, isNull);
    });
  });

  group('toJson', () {
    test('BlobDescriptor.toJson encodes uploaded as unix seconds', () {
      final descriptor = BlobDescriptor(
        url: 'https://cdn.example.com/abc',
        sha256: 'abc',
        size: 42,
        type: 'image/png',
        uploaded: DateTime.fromMillisecondsSinceEpoch(1700000000 * 1000),
      );
      final json = descriptor.toJson();
      expect(json['url'], 'https://cdn.example.com/abc');
      expect(json['sha256'], 'abc');
      expect(json['size'], 42);
      expect(json['type'], 'image/png');
      expect(json['uploaded'], 1700000000);
      expect(json['nip94'], isNull);
    });

    test('BlobDescriptor roundtrips through toJson / fromJson', () {
      final original = BlobDescriptor(
        url: 'https://cdn.example.com/abc',
        sha256:
            '0000000000000000000000000000000000000000000000000000000000000000',
        size: 1234,
        type: 'video/mp4',
        // truncate to second precision since toJson stores unix seconds
        uploaded: DateTime.fromMillisecondsSinceEpoch(1700000000 * 1000),
      );
      final restored = BlobDescriptor.fromJson(original.toJson());
      expect(restored.url, original.url);
      expect(restored.sha256, original.sha256);
      expect(restored.size, original.size);
      expect(restored.type, original.type);
      expect(restored.uploaded, original.uploaded);
      expect(restored.nip94, isNull);
    });

    test('BlobNip94.toJson uses NIP-94 short tag keys', () {
      final nip94 = BlobNip94(
        content: 'a video',
        url: 'https://cdn.example.com/v.mp4',
        mimeType: 'video/mp4',
        sha256: 'deadbeef',
        size: 999,
        dimensions: '1920x1080',
        magnet: 'magnet:?xt=...',
        torrentInfoHash: 'hash123',
        blurhash: 'L00000',
        thumbnail: ['https://cdn.example.com/thumb.png'],
        image: ['https://cdn.example.com/preview.png'],
        fallback: ['https://mirror.example.com/v.mp4'],
        summary: 'a short clip',
        alt: 'description',
        service: 'nip-96',
      );
      final json = nip94.toJson();
      expect(json['m'], 'video/mp4');
      expect(json['x'], 'deadbeef');
      expect(json['i'], 'hash123');
      expect(json['dim'], '1920x1080');
      expect(json['size'], 999);
      expect(json['thumb'], 'https://cdn.example.com/thumb.png');
      expect(json['image'], 'https://cdn.example.com/preview.png');
      expect(json['fallback'], 'https://mirror.example.com/v.mp4');
      expect(json['service'], 'nip-96');
    });

    test('BlobNip94.toJson emits null for empty/absent list fields', () {
      final nip94 = BlobNip94(
        content: '',
        url: '',
        mimeType: '',
        sha256: '',
        size: null,
      );
      final json = nip94.toJson();
      expect(json['thumb'], isNull);
      expect(json['image'], isNull);
      expect(json['fallback'], isNull);
      expect(json['dim'], isNull);
    });

    test('BlobDescriptor with nested nip94 roundtrips', () {
      final original = BlobDescriptor(
        url: 'https://cdn.example.com/v.mp4',
        sha256: 'aaaa',
        size: 6762754,
        type: 'video/mp4',
        uploaded: DateTime.fromMillisecondsSinceEpoch(1700000000 * 1000),
        nip94: BlobNip94(
          content: '',
          url: 'https://cdn.example.com/v.mp4',
          mimeType: 'video/mp4',
          sha256: 'aaaa',
          size: 6762754,
          dimensions: '590x1280',
          thumbnail: ['https://cdn.example.com/thumb.webp'],
        ),
      );
      final restored = BlobDescriptor.fromJson(original.toJson());
      expect(restored.nip94, isNotNull);
      expect(restored.nip94!.mimeType, 'video/mp4');
      expect(restored.nip94!.sha256, 'aaaa');
      expect(restored.nip94!.size, 6762754);
      expect(restored.nip94!.dimensions, '590x1280');
      expect(restored.nip94!.thumbnail!.first,
          'https://cdn.example.com/thumb.webp');
    });
  });
}
