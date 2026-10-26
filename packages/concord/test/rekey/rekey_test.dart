import 'dart:convert';
import 'dart:typed_data';

import 'package:concord/src/core/concord_constants.dart';
import 'package:concord/src/core/derivations.dart';
import 'package:concord/src/core/encoding.dart';
import 'package:concord/src/rekey/rekey_blob.dart';
import 'package:concord/src/stream/stream_envelope.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import '../support/concord_test_support.dart';

void main() {
  final rotator = LocalSecretSigner(privateKey: bytesToHex(bytes32(0x11)));
  final alice = LocalSecretSigner(privateKey: bytesToHex(bytes32(0x22)));
  final bob = LocalSecretSigner(privateKey: bytesToHex(bytes32(0x33)));
  final staff = LocalSecretSigner(privateKey: bytesToHex(bytes32(0x44)));
  final outsider = LocalSecretSigner(privateKey: bytesToHex(bytes32(0x55)));

  group('channel rotation (CORD-06 §1)', () {
    final scopeId = bytes32(0x70);
    final prevKey = bytes32(0x01);
    final newKey = bytes32(0x02);

    test('a member opens their 72-byte blob and gets the new key', () async {
      final events = await Rekeys.buildChannelRotation(
        rotator: rotator,
        scopeId: scopeId,
        newEpoch: 1,
        prevEpoch: 0,
        prevKey: prevKey,
        newKey: newKey,
        recipients: [alice.getPublicKey(), bob.getPublicKey()],
        createdAt: 1700000000,
      );
      expect(events, hasLength(1));
      final event = events.single;
      expect(event.isBase, isFalse);
      expect(event.newEpoch, 1);
      expect(event.prevEpoch, 0);
      expect(event.blobs, hasLength(2));

      final blob = Rekeys.findMyBlob(
        event: event,
        recipientXonly: alice.getPublicKey(),
      );
      expect(blob, isNotNull);
      final material = await Rekeys.decryptBlob(
        event: event,
        blob: blob!,
        recipient: alice,
      );
      expect(material, isA<ChannelRekeyKey>());
      expect((material as ChannelRekeyKey).newKey, newKey);
      expect(material.epoch, 1);
    });

    test('the continuity commitment matches the held key', () async {
      final event = (await Rekeys.buildChannelRotation(
        rotator: rotator,
        scopeId: scopeId,
        newEpoch: 1,
        prevEpoch: 0,
        prevKey: prevKey,
        newKey: newKey,
        recipients: [alice.getPublicKey()],
        createdAt: 1700000000,
      )).single;
      expect(Rekeys.continuityHolds(event: event, heldKey: prevKey), isTrue);
      expect(
        Rekeys.continuityHolds(event: event, heldKey: bytes32(0x09)),
        isFalse,
      );
    });

    test('a foreign recipient finds no blob', () async {
      final event = (await Rekeys.buildChannelRotation(
        rotator: rotator,
        scopeId: scopeId,
        newEpoch: 1,
        prevEpoch: 0,
        prevKey: prevKey,
        newKey: newKey,
        recipients: [alice.getPublicKey()],
        createdAt: 1700000000,
      )).single;
      expect(
        Rekeys.findMyBlob(
          event: event,
          recipientXonly: outsider.getPublicKey(),
        ),
        isNull,
      );
    });

    test('a spliced blob whose scope disagrees is refused', () async {
      // Build a blob for scope A, then present it under an event for scope B.
      final scopeB = bytes32(0x71);
      final built = (await Rekeys.buildChannelRotation(
        rotator: rotator,
        scopeId: scopeId,
        newEpoch: 1,
        prevEpoch: 0,
        prevKey: prevKey,
        newKey: newKey,
        recipients: [alice.getPublicKey()],
        createdAt: 1700000000,
      )).single;
      final forged = RekeyEvent(
        rumor: built.rumor,
        scopeId: scopeB,
        newEpoch: 1,
        prevEpoch: 0,
        prevCommit: built.prevCommit,
        chunkIndex: 0,
        chunkCount: 1,
        blobs: built.blobs,
      );
      final blob = Rekeys.findMyBlob(
        event: built,
        recipientXonly: alice.getPublicKey(),
      );
      expect(
        await Rekeys.decryptBlob(event: forged, blob: blob!, recipient: alice),
        isNull,
      );
    });

    test('more than 120 recipients splits into chunks', () async {
      final many = [
        for (var i = 0; i < 121; i++) Bip340.getPublicKey(bytesToHex(_seed(i))),
      ];
      final events = await Rekeys.buildChannelRotation(
        rotator: rotator,
        scopeId: scopeId,
        newEpoch: 1,
        prevEpoch: 0,
        prevKey: prevKey,
        newKey: newKey,
        recipients: many,
        createdAt: 1700000000,
      );
      expect(events, hasLength(2));
      expect(events[0].chunkCount, 2);
      expect(events[0].chunkIndex, 0);
      expect(events[1].chunkIndex, 1);
      expect(events[0].blobs, hasLength(Caps.rekeyBlobRecipients));
    });
  });

  group('base rotation (CORD-06 §3, Refounding)', () {
    final prevRoot = bytes32(0x61);
    final newRoot = bytes32(0x62);
    final newControlRoot = bytes32(0x63);
    final communityId = hexToBytes(hex32(0x99));
    final newControlPk = groupKey(
      secret: newControlRoot,
      label: Labels.controlSigner,
      id: communityId,
      epoch: 1,
    );
    final newControlPkBytes = hexToBytes(newControlPk.pk);

    test('a member gets a 104-byte blob carrying the new control_pk', () async {
      final event = (await Rekeys.buildBaseRotation(
        rotator: rotator,
        newEpoch: 1,
        prevEpoch: 0,
        prevRoot: prevRoot,
        newRoot: newRoot,
        newControlPk: newControlPkBytes,
        members: [alice.getPublicKey()],
        createdAt: 1700000000,
      )).single;
      expect(event.isBase, isTrue);

      final blob = Rekeys.findMyBlob(
        event: event,
        recipientXonly: alice.getPublicKey(),
      );
      final material = await Rekeys.decryptBlob(
        event: event,
        blob: blob!,
        recipient: alice,
      );
      expect(material, isA<BaseRekeyKey>());
      final base = material as BaseRekeyKey;
      expect(base.legacy, isFalse);
      expect(base.newRoot, newRoot);
      expect(base.newControlPk, newControlPkBytes);
      expect(base.newControlRoot, isNull);
    });

    test(
      'staff get a 136-byte blob with the control_root and a consistent pair',
      () async {
        final event = (await Rekeys.buildBaseRotation(
          rotator: rotator,
          newEpoch: 1,
          prevEpoch: 0,
          prevRoot: prevRoot,
          newRoot: newRoot,
          newControlPk: newControlPkBytes,
          newControlRoot: newControlRoot,
          members: [alice.getPublicKey(), staff.getPublicKey()],
          staffRecipients: {staff.getPublicKey()},
          createdAt: 1700000000,
        )).single;

        final staffBlob = Rekeys.findMyBlob(
          event: event,
          recipientXonly: staff.getPublicKey(),
        );
        final material = await Rekeys.decryptBlob(
          event: event,
          blob: staffBlob!,
          recipient: staff,
        );
        final base = material as BaseRekeyKey;
        expect(base.newControlRoot, newControlRoot);
        expect(base.controlPairConsistent(communityId: hex32(0x99)), isTrue);

        // A member blob stays 104 bytes (no control_root).
        final memberBlob = Rekeys.findMyBlob(
          event: event,
          recipientXonly: alice.getPublicKey(),
        );
        final memberMaterial = await Rekeys.decryptBlob(
          event: event,
          blob: memberBlob!,
          recipient: alice,
        );
        expect((memberMaterial as BaseRekeyKey).newControlRoot, isNull);
      },
    );

    test('a staff blob with a mismatched control pair is detected', () async {
      final wrongPk = hexToBytes(hex32(0xee));
      final event = (await Rekeys.buildBaseRotation(
        rotator: rotator,
        newEpoch: 1,
        prevEpoch: 0,
        prevRoot: prevRoot,
        newRoot: newRoot,
        newControlPk: wrongPk,
        newControlRoot: newControlRoot,
        members: [staff.getPublicKey()],
        staffRecipients: {staff.getPublicKey()},
        createdAt: 1700000000,
      )).single;
      final blob = Rekeys.findMyBlob(
        event: event,
        recipientXonly: staff.getPublicKey(),
      );
      final material = await Rekeys.decryptBlob(
        event: event,
        blob: blob!,
        recipient: staff,
      );
      expect(
        (material as BaseRekeyKey).controlPairConsistent(
          communityId: hex32(0x99),
        ),
        isFalse,
      );
    });
  });

  group('legacy base blob (pre-split epoch)', () {
    test('a 72-byte base blob reads as a legacy root', () async {
      // Hand-craft a legacy 72-byte base blob.
      final scopeId = baseScopeId();
      final plain = concatBytes([scopeId, u64Be(4), bytes32(0x77)]);
      expect(plain.length, Caps.channelBlobBytes);

      final rotatorPk = rotator.getPublicKey();
      final locator = recipientLocator(
        rotatorXonly: rotatorPk,
        recipientXonly: alice.getPublicKey(),
        scopeId: scopeId,
        epoch: 4,
      );
      final wrapped = await rotator.encryptNip44(
        plaintext: base64.encode(plain),
        recipientPubKey: alice.getPublicKey(),
      );
      final wrappedField = base64.encode(utf8.encode(wrapped!));
      final event = RekeyEvent(
        rumor: RekeyEvent.buildRumor(
          rotator: rotatorPk,
          scopeId: scopeId,
          newEpoch: 4,
          prevEpoch: 3,
          prevCommit: hex32(0x12),
          chunkIndex: 0,
          chunkCount: 1,
          blobs: [RekeyBlob(locator: locator, wrapped: wrappedField)],
          createdAt: 1700000000,
        ),
        scopeId: scopeId,
        newEpoch: 4,
        prevEpoch: 3,
        prevCommit: hex32(0x12),
        chunkIndex: 0,
        chunkCount: 1,
        blobs: [RekeyBlob(locator: locator, wrapped: wrappedField)],
      );
      final material = await Rekeys.decryptBlob(
        event: event,
        blob: event.blobs.single,
        recipient: alice,
      );
      expect(material, isA<BaseRekeyKey>());
      final base = material as BaseRekeyKey;
      expect(base.legacy, isTrue);
      expect(base.newRoot, bytes32(0x77));
      expect(base.newControlPk, isNull);
    });
  });

  group('parsing', () {
    test('a rumor missing required tags is refused', () {
      final rumor = StreamEnvelope.makeRumor(
        pubkey: rotator.getPublicKey(),
        kind: RumorKinds.rekey,
        content: '[]',
        createdAt: 1700000000,
        tags: const [
          ['scope', ''],
        ],
      );
      expect(RekeyEvent.tryParse(rumor), isNull);
    });

    test('a non-chunked event defaults to one chunk', () async {
      final event = (await Rekeys.buildChannelRotation(
        rotator: rotator,
        scopeId: bytes32(0x70),
        newEpoch: 1,
        prevEpoch: 0,
        prevKey: bytes32(0x01),
        newKey: bytes32(0x02),
        recipients: const [],
        createdAt: 1700000000,
      )).single;
      expect(event.chunkCount, 1);
      expect(event.blobs, isEmpty);
    });
  });
}

Uint8List _seed(int i) =>
    Uint8List.fromList(List.generate(32, (j) => (i * 31 + j * 7 + 1) & 0xff));
