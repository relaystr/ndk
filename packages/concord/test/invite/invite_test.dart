import 'dart:convert';
import 'dart:typed_data';

import 'package:concord/src/core/derivations.dart';
import 'package:concord/src/core/encoding.dart';
import 'package:concord/src/invite/community_invite.dart';
import 'package:concord/src/invite/direct_invite.dart';
import 'package:concord/src/stream/stream_envelope.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import '../support/concord_test_support.dart';

CommunityInvite _invite({
  String? owner,
  Uint8List? salt,
  List<InviteChannel> channels = const [],
  List<String> relays = const [],
}) {
  final o = owner ?? Bip340.getPublicKey(bytesToHex(bytes32(0x01)));
  final s = salt ?? bytes32(0x02);
  return CommunityInvite(
    communityId: communityId(ownerXonly: o, ownerSalt: s),
    owner: o,
    ownerSalt: s,
    communityRoot: bytes32(0x03),
    rootEpoch: 0,
    controlPk: hex32(0x04),
    channels: channels,
    relays: relays,
    name: 'Vector',
  );
}

void main() {
  group('the bundle (CORD-05 §1)', () {
    test('a bundle round-trips through JSON', () {
      final invite = _invite(
        channels: [
          InviteChannel(id: hex32(0x70), key: hex32(0x71), epoch: 2),
          InviteChannel(id: hex32(0x72), epoch: 0, name: 'general'),
        ],
        relays: const ['wss://relay.example'],
      );
      final back = CommunityInvite.tryParse(invite.toJsonString());
      expect(back, isNotNull);
      expect(back!.communityId, invite.communityId);
      expect(back.owner, invite.owner);
      expect(back.communityRoot, invite.communityRoot);
      expect(back.controlPk, invite.controlPk);
      expect(back.channels, hasLength(2));
      expect(back.channels[0].key, hex32(0x71));
      expect(back.channels[0].isPrivate, isTrue);
      expect(back.channels[1].isPrivate, isFalse);
      expect(back.relays, const ['wss://relay.example']);
    });

    test('a tampered community_id fails the owner self-check', () {
      final invite = _invite();
      final json = jsonDecode(invite.toJsonString()) as Map<String, dynamic>;
      json['community_id'] = hex32(0xff);
      expect(CommunityInvite.tryParse(jsonEncode(json)), isNull);
    });

    test('a bundle with more than 256 channels is refused', () {
      final channels = [
        for (var i = 0; i < 257; i++)
          InviteChannel(id: _hexFromInt(i), epoch: 0),
      ];
      final invite = _invite(channels: channels);
      expect(CommunityInvite.tryParse(invite.toJsonString()), isNull);
    });

    test('exactly 256 channels is allowed', () {
      final channels = [
        for (var i = 0; i < 256; i++)
          InviteChannel(id: _hexFromInt(i), epoch: 0),
      ];
      final invite = _invite(channels: channels);
      final back = CommunityInvite.tryParse(invite.toJsonString());
      expect(back, isNotNull);
      expect(back!.channels, hasLength(256));
    });

    test('relays are truncated to the Community cap', () {
      final invite = _invite(
        relays: const [
          'wss://a',
          'wss://b',
          'wss://c',
          'wss://d',
          'wss://e',
          'wss://f',
          'wss://g',
        ],
      );
      final back = CommunityInvite.tryParse(invite.toJsonString());
      expect(back!.relays, hasLength(5));
    });

    test('toKeys converts channels and control key', () {
      final invite = _invite(
        channels: [InviteChannel(id: hex32(0x70), key: hex32(0x71), epoch: 3)],
      );
      final keys = invite.toKeys();
      expect(keys.communityId, invite.communityId);
      expect(keys.controlPk, invite.controlPk);
      expect(keys.controlEpoch, invite.rootEpoch);
      expect(keys.channels[hex32(0x70)]!.key, hexToBytes(hex32(0x71)));
    });

    test('expiry is measured in milliseconds', () {
      final invite = CommunityInvite(
        communityId: _invite().communityId,
        owner: _invite().owner,
        ownerSalt: bytes32(0x02),
        communityRoot: bytes32(0x03),
        rootEpoch: 0,
        expiresAt: 1000,
      );
      expect(invite.isExpired(nowMillis: 999), isFalse);
      expect(invite.isExpired(nowMillis: 1000), isTrue);
    });
  });

  group('direct invites (CORD-05 §6)', () {
    final inviter = LocalSecretSigner(privateKey: bytesToHex(bytes32(0x05)));
    final recipient = LocalSecretSigner(privateKey: bytesToHex(bytes32(0x06)));
    final stranger = LocalSecretSigner(privateKey: bytesToHex(bytes32(0x07)));
    final invite = _invite(
      channels: [InviteChannel(id: hex32(0x70), key: hex32(0x71), epoch: 1)],
    );

    test('build then unwrap recovers the bundle', () async {
      final wrap = await DirectInvites.build(
        invite: invite,
        senderSigner: inviter,
        recipientPubkey: recipient.getPublicKey(),
        rumourCreatedAt: 1700000000,
        sealCreatedAt: 1699900000,
        wrapCreatedAt: 1699800000,
        ephemeralSk: bytesToHex(bytes32(0x08)),
      );
      expect(wrap.kind, 1059);
      expect(wrap.tags.any((t) => t[0] == 'k' && t[1] == '3313'), isTrue);
      expect(
        wrap.tags.any((t) => t[0] == 'p' && t[1] == recipient.getPublicKey()),
        isTrue,
      );

      final unwrapped = await DirectInvites.unwrap(
        wrap: wrap,
        recipientSigner: recipient,
      );
      expect(unwrapped.inviter, inviter.getPublicKey());
      expect(unwrapped.invite.communityId, invite.communityId);
      expect(unwrapped.invite.channels.single.key, hex32(0x71));
    });

    test('a bystander cannot open the wrap', () async {
      final wrap = await DirectInvites.build(
        invite: invite,
        senderSigner: inviter,
        recipientPubkey: recipient.getPublicKey(),
        rumourCreatedAt: 1700000000,
        sealCreatedAt: 1699900000,
        wrapCreatedAt: 1699800000,
        ephemeralSk: bytesToHex(bytes32(0x08)),
      );
      await expectLater(
        DirectInvites.unwrap(wrap: wrap, recipientSigner: stranger),
        throwsA(isA<FormatException>()),
      );
    });

    test('a tampered wrap signature is refused', () async {
      final wrap = await DirectInvites.build(
        invite: invite,
        senderSigner: inviter,
        recipientPubkey: recipient.getPublicKey(),
        rumourCreatedAt: 1700000000,
        sealCreatedAt: 1699900000,
        wrapCreatedAt: 1699800000,
        ephemeralSk: bytesToHex(bytes32(0x08)),
      );
      final broken = wrap.copyWith(sig: hex32(0x00) + hex32(0x00));
      await expectLater(
        DirectInvites.unwrap(wrap: broken, recipientSigner: recipient),
        throwsA(isA<FormatException>()),
      );
    });

    test('the seal signs with the inviter, not the ephemeral key', () async {
      final wrap = await DirectInvites.build(
        invite: invite,
        senderSigner: inviter,
        recipientPubkey: recipient.getPublicKey(),
        rumourCreatedAt: 1700000000,
        sealCreatedAt: 1699900000,
        wrapCreatedAt: 1699800000,
        ephemeralSk: bytesToHex(bytes32(0x08)),
      );
      // The wrap author is ephemeral; the inner seal signer is the inviter.
      expect(wrap.pubKey, isNot(inviter.getPublicKey()));
      final unwrapped = await DirectInvites.unwrap(
        wrap: wrap,
        recipientSigner: recipient,
      );
      expect(unwrapped.seal.pubKey, inviter.getPublicKey());
    });
  });
}

String _hexFromInt(int i) {
  final s = i.toRadixString(16).padLeft(64, '0');
  return s;
}
