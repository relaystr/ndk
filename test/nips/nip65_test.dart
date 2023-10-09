import 'package:dart_ndk/nips/nip65.dart';
import 'package:dart_ndk/nips/nip01.dart';
import 'package:dart_ndk/pubkey_mapping.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Nip65.fromEvent', () {
    final event = Nip01Event(
      publishAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      pubKey: 'pubkeyUser1',
      kind: Nip65.kind,
      content: "",
      tags: [
        ['r', 'https://example.com', 'read'],
        ['r', 'https://example.org', 'write'],
        ['r', 'https://example.net'],
        ['invalid'],
      ],
    );
    final nip65 = Nip65.fromEvent(event);
    expect(nip65.relays, {
      'https://example.com': ReadWriteMarker(read: true),
      'https://example.org': ReadWriteMarker(write: true),
      'https://example.net': null,
    });
  });
}
