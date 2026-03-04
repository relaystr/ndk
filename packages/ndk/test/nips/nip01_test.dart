import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

void main() {
  group('Bip340', () {
    test('sign and verify', () {
      final keyPair = Bip340.generatePrivateKey();
      const message = 'Hello, World!';
      final messageSha256 =
          Uint8List.fromList(sha256.convert(utf8.encode(message)).bytes);
      final messageHex = hex.encode(messageSha256);
      final signature = Bip340.sign(messageHex, keyPair.privateKey!);
      expect(Bip340.verify(messageHex, signature, keyPair.publicKey), isTrue);
    });

    test('getPublicKey', () {
      final keyPair = Bip340.generatePrivateKey();
      expect(
          Bip340.getPublicKey(keyPair.privateKey!), equals(keyPair.publicKey));
    });
  });
  group('Metadata', () {
    test('to/from json/event', () {
      final Map<String, dynamic> contentData = {
        'name': "name",
        'display_name': "display name",
        'picture': "https://bla.com/picture.jpg",
        'banner': "https://bla.com/banner.jpg",
        'website': "https://bla.com",
        'about': "about...",
        'nip05': "bla@bla.com",
        'lud16': "bla@bla.com",
        'lud06': "bla@bla.com",
      };

      final Map<String, dynamic> data = {
        'pubKey': 'pubKey1',
        'content': contentData,
        'tags': [
          ['i', 'test']
        ],
        'updatedAt': 1234567890,
      };

      Metadata metadata = Metadata.fromJson(data);
      Map<String, dynamic> toJson = metadata.toJson();

      expect(toJson['pubKey'], data['pubKey']);
      expect(toJson['content'], data['content']);
      expect(toJson['tags'], data['tags']);
      expect(toJson['updatedAt'], data['updatedAt']);

      Nip01Event event = metadata.toEvent();
      Metadata metadataFromEvent = Metadata.fromEvent(event);
      expect(metadata, metadataFromEvent);
    });
  });
}
