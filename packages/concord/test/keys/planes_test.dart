import 'dart:typed_data';

import 'package:concord/src/core/concord_constants.dart';
import 'package:concord/src/core/derivations.dart';
import 'package:concord/src/core/encoding.dart';
import 'package:concord/src/keys/concord_keys.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import '../support/concord_test_support.dart';

CommunityKeys _keys({
  required String owner,
  required Uint8List salt,
  required Uint8List root,
  required int epoch,
}) {
  final cid = communityId(ownerXonly: owner, ownerSalt: salt);
  return CommunityKeys(
    communityId: cid,
    owner: owner,
    ownerSalt: salt,
    rootEpoch: epoch,
    communityRoot: root,
    controlPk: '',
    controlEpoch: epoch,
  );
}

void main() {
  final owner = Bip340.getPublicKey(bytesToHex(bytes32(0x01)));
  final salt = bytes32(0x09);
  final root = bytes32(0x22);
  final controlRoot = bytes32(0x33);
  final keys = _keys(owner: owner, salt: salt, root: root, epoch: 3);

  group('community identity (CORD-02 §1)', () {
    test('the community id self-certifies the owner', () {
      expect(keys.verifiesOwner(), isTrue);
      final tampered = keys.copyWith(name: 'x');
      // name does not affect the id; a wrong owner would.
      final wrong = CommunityKeys(
        communityId: keys.communityId,
        owner: hex32(0xee),
        ownerSalt: salt,
        rootEpoch: 0,
        communityRoot: root,
        controlPk: '',
        controlEpoch: 0,
      );
      expect(wrong.verifiesOwner(), isFalse);
      expect(tampered.communityId, keys.communityId);
    });
  });

  group('plane derivations (CORD-02 §5, A.6)', () {
    test('the control signer derives from the staff control_root', () {
      final expected = groupKey(
        secret: controlRoot,
        label: Labels.controlSigner,
        id: hexToBytes(keys.communityId),
        epoch: 3,
      ).pk;
      expect(
        Planes.controlSignerPk(
          controlRoot: controlRoot,
          communityId: keys.communityId,
          epoch: 3,
        ),
        expected,
      );
    });

    test('the control read key derives from the member community_root', () {
      final read = Planes.controlReadKey(
        communityRoot: root,
        communityId: keys.communityId,
        epoch: 3,
      );
      final expected = groupKey(
        secret: root,
        label: Labels.control,
        id: hexToBytes(keys.communityId),
        epoch: 3,
      );
      expect(read.pk, expected.pk);
      expect(read.convKey, expected.convKey);
    });

    test(
      'a private channel derives from its own key; a public one from root',
      () {
        final privateId = hex32(0xaa);
        final publicId = hex32(0xbb);
        final withChannels = keys.copyWith(
          channels: {
            privateId: ChannelKey(
              channelId: privateId,
              private: true,
              epoch: 5,
              key: bytes32(0x44),
            ),
            publicId: const ChannelKey(
              channelId: '',
              private: false,
              epoch: 0,
            ).copyWithPublic(publicId, keys.rootEpoch),
          },
        );

        final priv = Planes.channelKey(withChannels, privateId);
        expect(
          priv.pk,
          groupKey(
            secret: bytes32(0x44),
            label: Labels.channel,
            id: hexToBytes(privateId),
            epoch: 5,
          ).pk,
        );

        final pub = Planes.channelKey(withChannels, publicId);
        expect(
          pub.pk,
          groupKey(
            secret: root,
            label: Labels.channel,
            id: hexToBytes(publicId),
            epoch: keys.rootEpoch,
          ).pk,
        );
      },
    );

    test('the guestbook key derives from the community_root', () {
      final gb = Planes.guestbookKey(keys, epoch: 3);
      expect(
        gb.pk,
        groupKey(
          secret: root,
          label: Labels.guestbook,
          id: hexToBytes(keys.communityId),
          epoch: 3,
        ).pk,
      );
    });

    test('the control write keys split signer (staff) from read (member)', () {
      final staff = keys.copyWith(controlRoot: controlRoot);
      final write = Planes.controlWriteKeys(staff, epoch: 3);
      expect(
        write.signerPk,
        Planes.controlSignerPk(
          controlRoot: controlRoot,
          communityId: keys.communityId,
          epoch: 3,
        ),
      );
      expect(
        write.convKey,
        Planes.controlReadKey(
          communityRoot: root,
          communityId: keys.communityId,
          epoch: 3,
        ).convKey,
      );
      expect(() => Planes.controlWriteKeys(keys), throwsStateError);
    });
  });

  group('join material round-trip (CORD-05 §1, CORD-02 §8)', () {
    test('keys survive serialization only with a valid owner self-check', () {
      final privateId = hex32(0xaa);
      final full = keys.copyWith(
        controlPk: Planes.controlSignerPk(
          controlRoot: controlRoot,
          communityId: keys.communityId,
          epoch: 3,
        ),
        controlRoot: null,
        channels: {
          privateId: ChannelKey(
            channelId: privateId,
            private: true,
            epoch: 2,
            key: bytes32(0x55),
          ),
        },
        relays: const ['wss://relay.example'],
        name: 'Vector',
      );

      final json = full.toJoinMaterial();
      final back = CommunityKeys.fromJoinMaterial(
        json,
        expectedCommunityId: keys.communityId,
      );
      expect(back, isNotNull);
      expect(back!.communityId, keys.communityId);
      expect(back.rootEpoch, 3);
      expect(back.communityRoot, root);
      expect(back.controlPk, full.controlPk);
      expect(back.channels[privateId]!.key, bytes32(0x55));
      expect(back.channels[privateId]!.epoch, 2);
      expect(back.relays, const ['wss://relay.example']);
      expect(back.name, 'Vector');
    });

    test('a staff snapshot carries control_root', () {
      final staff = keys.copyWith(controlRoot: controlRoot);
      final back = CommunityKeys.fromJoinMaterial(staff.toJoinMaterial());
      expect(back!.controlRoot, controlRoot);
      expect(back.isStaff, isTrue);
    });

    test('a tampered community id is refused', () {
      final json = keys.toJoinMaterial();
      final bad = Map<String, Object?>.from(json);
      bad['community_id'] = hex32(0xff);
      expect(CommunityKeys.fromJoinMaterial(bad), isNull);
    });
  });
}

extension on ChannelKey {
  /// Test convenience: rebuild a public ChannelKey with an id and epoch.
  ChannelKey copyWithPublic(String id, int epoch) =>
      ChannelKey(channelId: id, private: false, epoch: epoch);
}
