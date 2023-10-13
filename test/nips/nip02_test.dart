import 'package:dart_ndk/nips/nip01/event.dart';
import 'package:dart_ndk/nips/nip02/metadata.dart';
import 'package:dart_ndk/nips/nip65/read_write_marker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Nip02', () {
    test('fromEvent', () {
      final event = Nip01Event(
        publishAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        pubKey: 'pubkeyUser1',
        kind: Nip02ContactList.kind,
        content: "{\"wss://nos.lol\":{\"read\":true,\"write\":true},\"wss://relay.damus.io\":{\"read\":true,\"write\":true}}",
        tags: [
          ['p', 'contact1'],
          ['p', 'contact2'],
          ['p', 'contact3'],
          ['p', 'contact4','wss://relay.com','petname'],
          ['invalid'],
        ],
      );
      final nip02 = Nip02ContactList.fromEvent(event);
      expect(nip02.contacts, [
        'contact1',
        'contact2',
        'contact3',
        'contact4',
      ]);
      expect(nip02.relaysInContent, {
        "wss://nos.lol": ReadWriteMarker.readWrite,
        "wss://relay.damus.io": ReadWriteMarker.readWrite,
      });
    });

    test('toEvent', () {
      final nip02 = Nip02ContactList([
        'contact1',
        'contact2',
        'contact3',
      ]);
      final myEvent = nip02.toEvent('pubkey123');
      expect(myEvent.pubKey, equals('pubkey123'));
      expect(myEvent.kind, equals(Nip02ContactList.kind));
      expect(
          myEvent.tags,
          equals([
            ['p','contact1','',''],
            ['p','contact2','',''],
            ['p','contact3','',''],
          ]));
      expect(myEvent.content, equals(''));
      expect(myEvent.createdAt, equals(nip02.createdAt));
    });
  });
}
