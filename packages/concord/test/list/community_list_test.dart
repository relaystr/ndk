import 'package:concord/src/core/derivations.dart';
import 'package:concord/src/core/encoding.dart';
import 'package:concord/src/keys/concord_keys.dart';
import 'package:concord/src/list/community_list.dart';
import 'package:concord/src/stream/stream_envelope.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import '../support/concord_test_support.dart';

CommunityKeys _keysAt(int epoch, {int saltFill = 0x02}) {
  final owner = Bip340.getPublicKey(bytesToHex(bytes32(0x01)));
  final salt = bytes32(saltFill);
  return CommunityKeys(
    communityId: communityId(ownerXonly: owner, ownerSalt: salt),
    owner: owner,
    ownerSalt: salt,
    rootEpoch: epoch,
    communityRoot: bytes32(0x30 + epoch),
    controlPk: '',
    controlEpoch: epoch,
    name: 'Vector',
  );
}

void main() {
  final cid = _keysAt(0).communityId;

  group('merge (CORD-02 §8)', () {
    test('seed keeps the lower epoch, current the higher', () {
      final a = CommunityList(
        entries: [
          CommunityListEntry(
            communityId: cid,
            seed: _keysAt(3),
            current: _keysAt(3),
            addedAt: 100,
          ),
        ],
      );
      final b = CommunityList(
        entries: [
          CommunityListEntry(
            communityId: cid,
            seed: _keysAt(1),
            current: _keysAt(5),
            addedAt: 100,
          ),
        ],
      );
      final merged = a.merge(b);
      expect(merged.entries, hasLength(1));
      expect(merged.entries.single.seed.rootEpoch, 1);
      expect(merged.entries.single.current.rootEpoch, 5);
    });

    test('an epoch tie breaks deterministically and is commutative', () {
      final a = CommunityList(
        entries: [
          CommunityListEntry(
            communityId: cid,
            seed: _keysAt(2),
            current: _keysAt(2),
            addedAt: 100,
          ),
        ],
      );
      final b = CommunityList(
        entries: [
          CommunityListEntry(
            communityId: cid,
            seed: _keysAt(2),
            current: _keysAt(2),
            addedAt: 100,
          ),
        ],
      );
      final ab = a.merge(b).entries.single;
      final ba = b.merge(a).entries.single;
      expect(ab.current.communityRoot, ba.current.communityRoot);
    });

    test('tombstones union with the newest removed_at', () {
      final a = CommunityList(
        tombstones: [CommunityListTombstone(communityId: cid, removedAt: 100)],
      );
      final b = CommunityList(
        tombstones: [CommunityListTombstone(communityId: cid, removedAt: 200)],
      );
      final merged = a.merge(b);
      expect(merged.tombstones, hasLength(1));
      expect(merged.tombstones.single.removedAt, 200);
    });

    test('caps memberships at 50', () {
      final entries = [
        for (var i = 0; i < 60; i++)
          CommunityListEntry(
            communityId: hex32(i),
            seed: _keysAt(0, saltFill: i),
            current: _keysAt(0, saltFill: i),
            addedAt: i,
          ),
      ];
      final list = CommunityList(
        entries: entries,
      ).merge(CommunityList(entries: const []));
      expect(list.entries.length, lessThanOrEqualTo(50));
    });
  });

  group('presence and tombstones', () {
    test('a newer tombstone removes the membership', () {
      final list = CommunityList(
        entries: [
          CommunityListEntry(
            communityId: cid,
            seed: _keysAt(0),
            current: _keysAt(0),
            addedAt: 100,
          ),
        ],
        tombstones: [CommunityListTombstone(communityId: cid, removedAt: 200)],
      );
      expect(list.isMember(cid), isFalse);
    });

    test('a rejoin newer than the tombstone restores membership', () {
      final list = CommunityList(
        entries: [
          CommunityListEntry(
            communityId: cid,
            seed: _keysAt(0),
            current: _keysAt(0),
            addedAt: 300,
          ),
        ],
        tombstones: [CommunityListTombstone(communityId: cid, removedAt: 200)],
      );
      expect(list.isMember(cid), isTrue);
    });

    test('remove then add round-trips membership', () {
      var list = CommunityList().addOrUpdate(_keysAt(0), addedAt: 100);
      expect(list.isMember(cid), isTrue);
      list = list.remove(cid, removedAt: 150);
      expect(list.isMember(cid), isFalse);
      list = list.addOrUpdate(_keysAt(4), addedAt: 200);
      expect(list.isMember(cid), isTrue);
      expect(list.entryOf(cid)!.current.rootEpoch, 4);
    });
  });

  group('the document (kind 13302)', () {
    test('build then parse round-trips through self-encryption', () async {
      final signer = LocalSecretSigner(privateKey: bytesToHex(bytes32(0x09)));
      final list = CommunityList().addOrUpdate(_keysAt(0), addedAt: 100);
      final event = await CommunityListDocument.build(
        signer: signer,
        list: list,
        createdAt: 1700000000,
      );
      expect(event.kind, CommunityListDocument.kind);
      expect(event.pubKey, signer.getPublicKey());

      final parsed = await CommunityListDocument.parse(
        event: event,
        signer: signer,
      );
      expect(parsed, isNotNull);
      expect(parsed!.isMember(cid), isTrue);
    });

    test('another key cannot read the list', () async {
      final owner = LocalSecretSigner(privateKey: bytesToHex(bytes32(0x09)));
      final other = LocalSecretSigner(privateKey: bytesToHex(bytes32(0x0a)));
      final event = await CommunityListDocument.build(
        signer: owner,
        list: CommunityList().addOrUpdate(_keysAt(0), addedAt: 100),
        createdAt: 1700000000,
      );
      expect(
        await CommunityListDocument.parse(event: event, signer: other),
        isNull,
      );
    });
  });
}
