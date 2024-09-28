import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex/hex.dart';

void main() {
  group('Bip340', () {
    test('sign and verify', () {
      final keyPair = Bip340.generatePrivateKey();
      const message = 'Hello, World!';
      final messageSha256 =
          Uint8List.fromList(sha256.convert(utf8.encode(message)).bytes);
      final messageHex = HEX.encode(messageSha256);
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
      final Map<String, dynamic> data = <String, dynamic>{};
      data['name'] = "name";
      data['display_name'] = "display name";
      data['picture'] = "https://bla.com/picture.jpg";
      data['banner'] = "https://bla.com/banner.jpg";
      data['website'] = "https://bla.com";
      data['about'] = "about...";
      data['nip05'] = "bla@bla.com";
      data['lud16'] = "bla@bla.com";
      data['lud06'] = "bla@bla.com";

      Metadata metadata = Metadata.fromJson(data);
      metadata.pubKey = "pubKey1";
      Map<String, dynamic> toJson = <String, dynamic>{};
      toJson = metadata.toJson();
      expect(data, toJson);

      Nip01Event event = metadata.toEvent();
      Metadata metadataFromEvent = Metadata.fromEvent(event);
      expect(metadata, metadataFromEvent);
    });
  });
}
