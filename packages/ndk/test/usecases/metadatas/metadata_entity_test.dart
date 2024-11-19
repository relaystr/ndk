import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/entities.dart';
import 'dart:convert';

void main() {
  group('Metadata', () {
    test('fromJson', () {
      final json = {
        'name': 'John',
        'display_name': 'John Doe',
        'picture': 'http://example.com/picture.jpg',
        'banner': 'http://example.com/banner.jpg',
        'website': 'http://example.com',
        'about': 'About me',
        'nip05': 'john@example.com',
        'lud16': 'john@lightning.com',
        'lud06': 'lnurl1234',
      };

      final metadata = Metadata.fromJson(json);

      expect(metadata.name, 'John');
      expect(metadata.displayName, 'John Doe');
      expect(metadata.picture, 'http://example.com/picture.jpg');
      expect(metadata.banner, 'http://example.com/banner.jpg');
      expect(metadata.website, 'http://example.com');
      expect(metadata.about, 'About me');
      expect(metadata.nip05, 'john@example.com');
      expect(metadata.lud16, 'john@lightning.com');
      expect(metadata.lud06, 'lnurl1234');
    });

    test('toJson', () {
      final metadata = Metadata(
        pubKey: 'testPubKey',
        name: 'John',
        displayName: 'John Doe',
        picture: 'http://example.com/picture.jpg',
        banner: 'http://example.com/banner.jpg',
        website: 'http://example.com',
        about: 'About me',
        nip05: 'john@example.com',
        lud16: 'john@lightning.com',
        lud06: 'lnurl1234',
      );

      final json = metadata.toJson();

      expect(json['name'], 'John');
      expect(json['display_name'], 'John Doe');
      expect(json['picture'], 'http://example.com/picture.jpg');
      expect(json['banner'], 'http://example.com/banner.jpg');
      expect(json['website'], 'http://example.com');
      expect(json['about'], 'About me');
      expect(json['nip05'], 'john@example.com');
      expect(json['lud16'], 'john@lightning.com');
      expect(json['lud06'], 'lnurl1234');
    });

    test('toFullJson', () {
      final metadata = Metadata(
        pubKey: 'testPubKey',
        name: 'John',
      );

      final json = metadata.toFullJson();

      expect(json['pub_key'], 'testPubKey');
      expect(json['name'], 'John');
    });

    test('fromEvent', () {
      final event = Nip01Event(
        pubKey: 'testPubKey',
        content: '{"name":"John","display_name":"John Doe"}',
        kind: Metadata.KIND,
        tags: [],
        createdAt: 1234567890,
      );

      final metadata = Metadata.fromEvent(event);

      expect(metadata.pubKey, 'testPubKey');
      expect(metadata.name, 'John');
      expect(metadata.displayName, 'John Doe');
      expect(metadata.updatedAt, 1234567890);
    });

    test('toEvent', () {
      final metadata = Metadata(
        pubKey: 'testPubKey',
        name: 'John',
        displayName: 'John Doe',
        updatedAt: 1234567890,
      );

      final event = metadata.toEvent();

      expect(event.pubKey, 'testPubKey');
      expect(event.kind, Metadata.KIND);
      expect(event.createdAt, 1234567890);

      final content = jsonDecode(event.content);
      expect(content['name'], 'John');
      expect(content['display_name'], 'John Doe');
    });

    test('cleanNip05', () {
      expect(Metadata(nip05: '_@example.com').cleanNip05, '@example.com');
      expect(
          Metadata(nip05: 'John@EXAMPLE.COM').cleanNip05, 'john@example.com');
      expect(Metadata(nip05: null).cleanNip05, null);
    });

    test('getName', () {
      expect(
          Metadata(displayName: 'John Doe', name: 'John', pubKey: 'testPubKey')
              .getName(),
          'John Doe');
      expect(Metadata(name: 'John', pubKey: 'testPubKey').getName(), 'John');
      expect(Metadata(pubKey: 'testPubKey').getName(), 'testPubKey');
    });

    test('matchesSearch', () {
      final metadata = Metadata(
        displayName: 'John Doe',
        name: 'JohnnyD',
      );

      expect(metadata.matchesSearch('John'), true);
      expect(metadata.matchesSearch('Doe'), true);
      expect(metadata.matchesSearch('Johnny'), true);
      expect(metadata.matchesSearch('Alice'), false);
    });

    test('equality', () {
      final metadata1 = Metadata(pubKey: 'testPubKey1');
      final metadata2 = Metadata(pubKey: 'testPubKey1');
      final metadata3 = Metadata(pubKey: 'testPubKey2');

      expect(metadata1 == metadata2, true);
      expect(metadata1 == metadata3, false);
    });

    test('hashCode', () {
      final metadata = Metadata(pubKey: 'testPubKey');
      expect(metadata.hashCode, 'testPubKey'.hashCode);
    });
  });
}
