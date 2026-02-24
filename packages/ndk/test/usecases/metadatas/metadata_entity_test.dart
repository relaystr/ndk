import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';
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
        kind: Metadata.kKind,
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
      expect(event.kind, Metadata.kKind);
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

    test('fromEvent preserves tags', () {
      final event = Nip01Event(
        pubKey: 'testPubKey',
        content: '{"name":"John"}',
        kind: Metadata.kKind,
        tags: [
          ['i', 'github:alice', 'proof'],
          ['i', 'twitter:bob', 'proof2'],
        ],
        createdAt: 1234567890,
      );

      final metadata = Metadata.fromEvent(event);

      expect(metadata.tags.length, 2);
      expect(metadata.tags[0], ['i', 'github:alice', 'proof']);
      expect(metadata.tags[1], ['i', 'twitter:bob', 'proof2']);
    });

    test('toEvent includes tags', () {
      final metadata = Metadata(
        pubKey: 'testPubKey',
        name: 'John',
        updatedAt: 1234567890,
        tags: [
          ['i', 'github:alice', 'proof'],
        ],
      );

      final event = metadata.toEvent();

      expect(event.tags.length, 1);
      expect(event.tags[0], ['i', 'github:alice', 'proof']);
    });

    test('roundtrip fromEvent toEvent preserves tags', () {
      final originalEvent = Nip01Event(
        pubKey: 'testPubKey',
        content: '{"name":"John","display_name":"John Doe"}',
        kind: Metadata.kKind,
        tags: [
          ['i', 'github:alice', 'proof'],
          ['i', 'twitter:bob', 'proof2'],
        ],
        createdAt: 1234567890,
      );

      final metadata = Metadata.fromEvent(originalEvent);
      final recreatedEvent = metadata.toEvent();

      expect(recreatedEvent.tags.length, 2);
      expect(recreatedEvent.tags[0], ['i', 'github:alice', 'proof']);
      expect(recreatedEvent.tags[1], ['i', 'twitter:bob', 'proof2']);
    });

    test('copyWith copies tags', () {
      final metadata = Metadata(
        pubKey: 'testPubKey',
        tags: [
          ['i', 'github:alice', 'proof'],
        ],
      );

      final copied = metadata.copyWith();

      expect(copied.tags.length, 1);
      expect(copied.tags[0], ['i', 'github:alice', 'proof']);
    });

    test('copyWith updates tags', () {
      final metadata = Metadata(
        pubKey: 'testPubKey',
        tags: [
          ['i', 'github:alice', 'proof'],
        ],
      );

      final copied = metadata.copyWith(
        tags: [
          ['i', 'twitter:bob', 'proof2'],
        ],
      );

      expect(copied.tags.length, 1);
      expect(copied.tags[0], ['i', 'twitter:bob', 'proof2']);
    });

    test('fromEvent preserves content', () {
      final event = Nip01Event(
        pubKey: 'testPubKey',
        content: '{"name":"John","custom_field":"custom_value"}',
        kind: Metadata.kKind,
        tags: [],
        createdAt: 1234567890,
      );

      final metadata = Metadata.fromEvent(event);

      expect(metadata.content, isNotNull);
      expect(metadata.content['custom_field'], 'custom_value');
      expect(metadata.content['name'], 'John');
    });

    test('toEvent preserves custom fields from content', () {
      final metadata = Metadata(
        pubKey: 'testPubKey',
        name: 'John',
        updatedAt: 1234567890,
        content: {
          'name': 'OldName',
          'custom_field': 'custom_value',
          'another_custom': 123,
        },
      );

      final event = metadata.toEvent();
      final content = jsonDecode(event.content);

      // Known fields should be updated
      expect(content['name'], 'John');
      // Custom fields should be preserved
      expect(content['custom_field'], 'custom_value');
      expect(content['another_custom'], 123);
    });

    test('roundtrip preserves custom fields and tags', () {
      final originalEvent = Nip01Event(
        pubKey: 'testPubKey',
        content: '{"name":"John","display_name":"John Doe","custom":"value"}',
        kind: Metadata.kKind,
        tags: [
          ['i', 'github:alice', 'proof'],
        ],
        createdAt: 1234567890,
      );

      final metadata = Metadata.fromEvent(originalEvent);
      final recreatedEvent = metadata.toEvent();
      final content = jsonDecode(recreatedEvent.content);

      // Known fields preserved
      expect(content['name'], 'John');
      expect(content['display_name'], 'John Doe');
      // Custom fields preserved
      expect(content['custom'], 'value');
      // Tags preserved
      expect(recreatedEvent.tags.length, 1);
      expect(recreatedEvent.tags[0], ['i', 'github:alice', 'proof']);
    });

    test('modifying known fields keeps custom fields intact', () {
      final metadata = Metadata.fromEvent(Nip01Event(
        pubKey: 'testPubKey',
        content: '{"name":"John","custom_field":"custom_value","another":456}',
        kind: Metadata.kKind,
        tags: [],
        createdAt: 1234567890,
      ));

      // Modify a known field
      metadata.name = 'Jane';
      metadata.updatedAt = 9999999999;

      final event = metadata.toEvent();
      final content = jsonDecode(event.content);

      // Modified field updated
      expect(content['name'], 'Jane');
      // Custom fields still there
      expect(content['custom_field'], 'custom_value');
      expect(content['another'], 456);
    });

    test('copyWith copies content', () {
      final metadata = Metadata(
        pubKey: 'testPubKey',
        content: {'custom': 'value'},
      );

      final copied = metadata.copyWith();

      expect(copied.content, isNotNull);
      expect(copied.content['custom'], 'value');
    });

    test('copyWith updates content', () {
      final metadata = Metadata(
        pubKey: 'testPubKey',
        content: {'custom': 'old'},
      );

      final copied = metadata.copyWith(
        content: {'custom': 'new', 'added': 'field'},
      );

      expect(copied.content['custom'], 'new');
      expect(copied.content['added'], 'field');
    });

    test('empty content does not break toEvent', () {
      final metadata = Metadata(
        pubKey: 'testPubKey',
        name: 'John',
        updatedAt: 1234567890,
      );

      final event = metadata.toEvent();
      final content = jsonDecode(event.content);

      expect(content['name'], 'John');
      expect(content.containsKey('custom'), false);
    });

    test('should be able to add a tag when the list is empty', () {
      final metadata = Metadata();
      metadata.tags.add([]);
      expect(metadata.tags, isNotEmpty);
    });

    test('setCustomField creates content and sets value', () {
      final metadata = Metadata(pubKey: 'testPubKey');

      metadata.setCustomField('badges', ['A', 'B']);

      expect(metadata.content, isNotNull);
      expect(metadata.getCustomField('badges'), ['A', 'B']);
    });

    test('setCustomField updates existing content', () {
      final metadata = Metadata(
        pubKey: 'testPubKey',
        content: {'existing': 'value'},
      );

      metadata.setCustomField('new_field', 'new_value');

      expect(metadata.getCustomField('existing'), 'value');
      expect(metadata.getCustomField('new_field'), 'new_value');
    });

    test('getCustomField returns null for non-existent key', () {
      final metadata = Metadata(pubKey: 'testPubKey');

      expect(metadata.getCustomField('nonexistent'), null);
    });

    test('getCustomField returns value for existing key', () {
      final metadata = Metadata(
        pubKey: 'testPubKey',
        content: {'custom': 'value'},
      );

      expect(metadata.getCustomField('custom'), 'value');
    });

    test('setCustomField is reflected in toEvent output', () {
      final metadata = Metadata(
        pubKey: 'testPubKey',
        name: 'John',
        updatedAt: 1234567890,
      );

      metadata.setCustomField('badges', ['A', 'B']);

      final event = metadata.toEvent();
      final content = jsonDecode(event.content);

      expect(content['name'], 'John');
      expect(content['badges'], ['A', 'B']);
    });

    test('set custom field update known field', () {
      final metadata = Metadata(name: 'John');
      metadata.setCustomField('name', "Alice");

      expect(metadata.name, equals("Alice"));
    });

    test('helper setter update content', () {
      final metadata = Metadata(name: 'John');
      metadata.name = "Alice";

      expect(metadata.content["name"], equals("Alice"));
      expect(metadata.getCustomField("name"), equals("Alice"));
    });
  });

  test("complete metadata workflow preserves all data", () async {
    final keypair = Bip340.generatePrivateKey();

    final signer = Bip340EventSigner(
      privateKey: keypair.privateKey,
      publicKey: keypair.publicKey,
    );

    final cache = MemCacheManager();

    final metadataEvent = Nip01Event(
      pubKey: keypair.publicKey,
      kind: 0,
      tags: [
        ["i", "badge"]
      ],
      content: '{"name":"Alice","badges":["A","B"]}',
    );

    final signedMetadataEvent = await signer.sign(metadataEvent);

    final metadata = Metadata.fromEvent(signedMetadataEvent);

    await cache.saveMetadata(metadata);

    final savedMetadata = await cache.loadMetadata(keypair.publicKey);

    expect(savedMetadata, isNotNull);

    savedMetadata!.tags.add(["i", "test"]);

    final newMetadataEvent = savedMetadata.toEvent();

    final newMetadataSignedEvent = await signer.sign(newMetadataEvent);

    expect(newMetadataSignedEvent.tags.length, equals(2));
    expect(
      List.from(jsonDecode(newMetadataSignedEvent.content)["badges"]).length,
      equals(2),
    );
  });
}
