import 'dart:convert';
import 'dart:typed_data';

import 'package:concord/src/core/derivations.dart';
import 'package:concord/src/core/encoding.dart';
import 'package:concord/src/core/hkdf.dart';
import 'package:test/test.dart';

Uint8List _bytes32(int fill) => Uint8List.fromList(List.filled(32, fill));

void main() {
  group('encoding helpers', () {
    test('checkHex32 accepts 64 lowercase hex, rejects everything else', () {
      expect(checkHex32('a' * 64), 'a' * 64);
      expect(() => checkHex32('A' * 64), throwsFormatException);
      expect(() => checkHex32('a' * 63), throwsFormatException);
      expect(() => checkHex32('a' * 65), throwsFormatException);
      expect(() => checkHex32('z' * 64), throwsFormatException);
    });

    test('tryParseDecimal: canonical decimals only', () {
      expect(tryParseDecimal('0'), 0);
      expect(tryParseDecimal('999'), 999);
      expect(tryParseDecimal(''), isNull);
      expect(tryParseDecimal('01'), isNull); // leading zero: malformed
      expect(tryParseDecimal('-1'), isNull);
      expect(tryParseDecimal('1.5'), isNull);
      expect(tryParseDecimal('abc'), isNull);
      expect(tryParseDecimal('42 '), isNull);
    });

    test('decimalTag refuses negatives and has no leading zeros', () {
      expect(decimalTag(0), '0');
      expect(decimalTag(4), '4');
      expect(() => decimalTag(-1), throwsFormatException);
    });

    test('u64Be round-trips and uses 8 bytes', () {
      expect(u64Be(0).length, 8);
      expect(u64BeDecode(u64Be(0)), 0);
      expect(u64BeDecode(u64Be(1)), 1);
      expect(u64BeDecode(u64Be(0x0102030405060708)), 0x0102030405060708);
      expect(bytesToHex(u64Be(4)), '0000000000000004');
    });

    test('canonicalEventJson uses the fixed field order', () {
      final json = canonicalEventJson(
        id: 'a' * 64,
        kind: 9,
        pubkey: 'b' * 64,
        content: 'hi',
        tags: const [
          ['channel', 'c'],
        ],
        createdAt: 1686840217,
        sig: 'd' * 128,
      );
      expect(
        json,
        '{"id":"${'a' * 64}","kind":9,"pubkey":"${'b' * 64}","content":"hi",'
        '"tags":[["channel","c"]],"created_at":1686840217,"sig":"${'d' * 128}"}',
      );
    });

    test('canonicalEventId is sha256 over the NIP-01 serialization array', () {
      final pubkey = 'b' * 64;
      final expected = sha256Hex(
        utf8.encode(jsonEncode([0, pubkey, 1, 1, <List<String>>[], 'x'])),
      );
      final id = canonicalEventId(
        pubkey: pubkey,
        createdAt: 1,
        kind: 1,
        tags: const [],
        content: 'x',
      );
      expect(id, expected);
    });
  });

  group('scalar_normalize (CORD-02 A.3)', () {
    test('accepts a valid scalar on the first attempt', () {
      final sk = scalarNormalize(
        ikm: _bytes32(0x11),
        label: 'concord/test',
        id: _bytes32(0x22),
        epoch: 0,
      );
      expect(sk.length, 64);
    });

    test('retries with an incrementing counter when the seed is invalid', () {
      final invalid = _bytes32(0x00); // zero: not a valid scalar
      final valid = _bytes32(0x01);
      final seenInfos = <Uint8List>[];
      var call = 0;

      final sk = scalarNormalize(
        ikm: _bytes32(0x11),
        label: 'concord/test',
        id: _bytes32(0x22),
        epoch: 7,
        debugHkdf: (info) {
          seenInfos.add(Uint8List.fromList(info));
          return call++ == 0 ? invalid : valid;
        },
      );

      expect(sk, bytesToHex(valid));
      expect(seenInfos.length, 2);
      // First attempt has no counter byte.
      expect(
        seenInfos[0],
        derivationInfo(label: 'concord/test', id: _bytes32(0x22), epoch: 7),
      );
      // The retry appends counter byte 0x00.
      expect(seenInfos[1], [...seenInfos[0], 0x00]);
    });

    test('keeps retrying until the counter finds a valid scalar', () {
      final zero = _bytes32(0x00);
      final n = hexToBytes(
        'fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141',
      );
      final valid = _bytes32(0x02);
      var call = 0;

      final sk = scalarNormalize(
        ikm: _bytes32(0x33),
        label: 'concord/test',
        id: _bytes32(0x44),
        debugHkdf: (_) => switch (call++) {
          0 => zero, // invalid
          1 => n, // == n: invalid
          _ => valid,
        },
      );
      expect(sk, bytesToHex(valid));
      expect(call, 3);
    });

    test('gives up after 256 consecutive invalid seeds', () {
      expect(
        () => scalarNormalize(
          ikm: _bytes32(0x33),
          label: 'concord/test',
          id: _bytes32(0x44),
          debugHkdf: (_) => _bytes32(0x00),
        ),
        throwsStateError,
      );
    });
  });

  group('isValidScalar boundaries', () {
    test('0 is invalid, 1 is valid', () {
      expect(isValidScalar(_bytes32(0x00)), isFalse);
      expect(isValidScalar(_bytes32(0x01)), isTrue);
    });

    test('n - 1 is valid, n is invalid, above n is invalid', () {
      final n = hexToBytes(
        'fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141',
      );
      final nMinus1 = hexToBytes(
        'fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140',
      );
      expect(isValidScalar(nMinus1), isTrue);
      expect(isValidScalar(n), isFalse);
      final nPlus1 = hexToBytes(
        'fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364142',
      );
      expect(isValidScalar(nPlus1), isFalse);
    });
  });

  group('community_id (CORD-02 §1)', () {
    test('is sha256("concord/community" || owner || salt)', () {
      final owner = 'ab' * 32;
      final salt = _bytes32(0x77);
      final expected = sha256Hex([
        ...labelBytes('concord/community'),
        ...hexToBytes(owner),
        ...salt,
      ]);
      expect(communityId(ownerXonly: owner, ownerSalt: salt), expected);
    });

    test('rejects malformed owner or salt', () {
      expect(
        () => communityId(ownerXonly: 'nope', ownerSalt: _bytes32(0)),
        throwsFormatException,
      );
      expect(
        () => communityId(ownerXonly: 'ab' * 32, ownerSalt: Uint8List(31)),
        throwsArgumentError,
      );
    });

    test('different owners/salts give different communities', () {
      final a = communityId(ownerXonly: 'aa' * 32, ownerSalt: _bytes32(1));
      final b = communityId(ownerXonly: 'bb' * 32, ownerSalt: _bytes32(1));
      final c = communityId(ownerXonly: 'aa' * 32, ownerSalt: _bytes32(2));
      expect(a, isNot(b));
      expect(a, isNot(c));
    });
  });

  group('group_key (CORD-02 A.2)', () {
    test('is deterministic and yields sk, x-only pk and 32-byte conv key', () {
      final gk = groupKey(
        secret: _bytes32(0x42),
        label: 'concord/channel',
        id: _bytes32(0x07),
        epoch: 1,
      );
      final again = groupKey(
        secret: _bytes32(0x42),
        label: 'concord/channel',
        id: _bytes32(0x07),
        epoch: 1,
      );
      expect(gk.sk, again.sk);
      expect(gk.pk, again.pk);
      expect(bytesToHex(gk.convKey), bytesToHex(again.convKey));
      expect(gk.pk.length, 64);
      expect(gk.convKey.length, 32);
      // x-only pubkeys are lowercase hex.
      expect(gk.pk, isNot(contains(RegExp('[A-F]'))));
    });

    test('label, id and epoch each change the address', () {
      final base = groupKey(
        secret: _bytes32(1),
        label: 'concord/channel',
        id: _bytes32(2),
        epoch: 0,
      );
      final otherLabel = groupKey(
        secret: _bytes32(1),
        label: 'concord/control',
        id: _bytes32(2),
        epoch: 0,
      );
      final otherId = groupKey(
        secret: _bytes32(1),
        label: 'concord/channel',
        id: _bytes32(3),
        epoch: 0,
      );
      final otherEpoch = groupKey(
        secret: _bytes32(1),
        label: 'concord/channel',
        id: _bytes32(2),
        epoch: 1,
      );
      expect(base.pk, isNot(otherLabel.pk));
      expect(base.pk, isNot(otherId.pk));
      expect(base.pk, isNot(otherEpoch.pk));
    });
  });

  group('epoch-key commitment (CORD-02 A.5)', () {
    test('is sha256 over label, epoch and key', () {
      final key = 'cd' * 32;
      final expected = sha256Hex([
        ...labelBytes('concord/epoch-key-commitment'),
        ...u64Be(2),
        ...hexToBytes(key),
      ]);
      expect(epochKeyCommitment(prevEpoch: 2, prevKey: key), expected);
    });
  });

  group('recipient locator (CORD-06 §2)', () {
    test('differs per recipient, epoch and scope', () {
      final rotator = 'aa' * 32;
      final me = 'bb' * 32;
      final other = 'cc' * 32;
      final scope = _bytes32(9);

      final mine = recipientLocator(
        rotatorXonly: rotator,
        recipientXonly: me,
        scopeId: scope,
        epoch: 1,
      );
      final theirs = recipientLocator(
        rotatorXonly: rotator,
        recipientXonly: other,
        scopeId: scope,
        epoch: 1,
      );
      final otherEpoch = recipientLocator(
        rotatorXonly: rotator,
        recipientXonly: me,
        scopeId: scope,
        epoch: 2,
      );
      final otherScope = recipientLocator(
        rotatorXonly: rotator,
        recipientXonly: me,
        scopeId: _bytes32(10),
        epoch: 1,
      );

      expect(mine.length, 64);
      expect({mine, theirs, otherEpoch, otherScope}.length, 4);
    });
  });

  group('deterministic coordinates (CORD-02 A.6)', () {
    test('grant/banlist/pins derive from the community id alone', () {
      final cid = 'ee' * 32;
      final member = 'ab' * 32;
      expect(Locators.grant(cid, member), Locators.grant(cid, member));
      expect(
        Locators.grant(cid, member),
        isNot(Locators.grant(cid, 'cd' * 32)),
      );
      expect(Locators.banlist(cid), Locators.banlist(cid));
      expect(Locators.pins(cid, member), isNot(Locators.banlist(cid)));
      expect(Locators.dissolvedPk(cid).length, 64);
      // No secret is involved: anyone holding the id derives the same.
      expect(Locators.dissolvedPk(cid), Locators.dissolvedPk(cid));
    });
  });
}
