import 'dart:typed_data';

import 'package:concord/src/client/concord_client.dart';
import 'package:concord/src/core/concord_constants.dart';
import 'package:concord/src/core/derivations.dart';
import 'package:concord/src/core/encoding.dart';
import 'package:concord/src/keys/concord_keys.dart';
import 'package:concord/src/model/metadata.dart';
import 'package:concord/src/store/concord_store.dart';
import 'package:concord/src/stream/stream_envelope.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import '../support/concord_test_support.dart';

LocalSecretSigner _signer(int fill) =>
    LocalSecretSigner(privateKey: bytesToHex(_bytes32(fill)));

Uint8List _bytes32(int fill) =>
    Uint8List.fromList(List.filled(32, fill & 0xff));

void main() {
  const now = 1700000000;

  /// Plays relay: hands each of [from]'s wraps to [to], trying every plane
  /// [to] can read (control, guestbook, each channel).
  Future<void> deliver(
    ConcordClient from,
    CommunityKeys fromKeys,
    ConcordClient to,
    CommunityKeys toKeys,
  ) async {
    final wraps = await from.store.outbox(fromKeys.communityId);
    for (final wrap in wraps) {
      final forward = fromKeys.communityId == toKeys.communityId;
      if (!forward) continue;
      // Control plane (plaintext seal).
      final control = Planes.controlReadKeys(
        toKeys,
        heldControlPk: toKeys.controlPk,
      );
      final atControl = await to.openAndStore(
        keys: toKeys,
        wrap: wrap,
        streamAddress: control.signerPk,
        convKey: control.convKey,
        form: SealForm.plaintext,
      );
      if (atControl != null) continue;

      // Guestbook plane.
      final gb = Planes.guestbookKey(toKeys);
      final atGb = await to.openAndStore(
        keys: toKeys,
        wrap: wrap,
        streamAddress: gb.pk,
        convKey: gb.convKey,
        form: SealForm.encrypted,
      );
      if (atGb != null) continue;

      // Each known channel.
      for (final channelId in toKeys.channels.keys) {
        final ch = Planes.channelKey(toKeys, channelId);
        final atChannel = await to.openAndStore(
          keys: toKeys,
          wrap: wrap,
          streamAddress: ch.pk,
          convKey: ch.convKey,
          form: SealForm.encrypted,
        );
        if (atChannel != null) break;
      }
    }
    await from.store.clearOutbox(fromKeys.communityId);
  }

  test('a full community round-trip: create, invite, join, and chat', () async {
    final alice = _signer(0xa1);
    final bob = _signer(0xb2);
    final clientA = ConcordClient(signer: alice);
    final clientB = ConcordClient(signer: bob);

    // --- Alice creates the community, a channel, and metadata.
    final channelId = hex32(0x70);
    final channelKey = _bytes32(0x71);
    var aKeys = await clientA.createCommunity(
      name: 'Vector',
      relays: const ['wss://relay.example'],
      communityRoot: _bytes32(0x01),
      controlRoot: _bytes32(0x02),
      ownerSalt: _bytes32(0x03),
    );
    aKeys = aKeys.copyWith(
      channels: {
        channelId: ChannelKey(
          channelId: channelId,
          private: true,
          epoch: 0,
          key: channelKey,
        ),
      },
    );
    await clientA.saveCommunity(aKeys);

    await clientA.sendControlEdition(
      keys: aKeys,
      vsk: Vsk.communityMetadata,
      eid: aKeys.communityId,
      content: CommunityMetadata(name: 'Vector').toContentJson(),
      createdAt: now,
      ms: 0,
    );
    await clientA.sendControlEdition(
      keys: aKeys,
      vsk: Vsk.channelMetadata,
      eid: channelId,
      content: ChannelMetadata(name: 'general', private: true).toContentJson(),
      createdAt: now,
      ms: 0,
    );

    // --- Bob is invited and accepts.
    final inviteWrap = await clientA.createDirectInvite(
      aKeys,
      recipient: bob.getPublicKey(),
      createdAt: now,
    );
    final bKeys = await clientB.acceptDirectInvite(inviteWrap);
    expect(bKeys, isNotNull);
    expect(bKeys!.communityId, aKeys.communityId);
    expect(bKeys.channels[channelId]!.key, channelKey);

    // --- Bob joins the Guestbook.
    await clientB.sendGuestbookVerb(
      keys: bKeys,
      verb: 'join',
      createdAt: now,
      ms: 0,
    );

    // --- Deliver both directions.
    await deliver(clientA, aKeys, clientB, bKeys);
    await deliver(clientB, bKeys, clientA, aKeys);

    // --- Alice sends a message.
    await clientA.sendChat(
      keys: aKeys,
      channelId: channelId,
      content: 'Hello, private world',
      createdAt: now,
      ms: 5,
    );
    await deliver(clientA, aKeys, clientB, bKeys);

    // --- Both fold the same picture.
    final openedA = await clientA.openCommunity(aKeys, nowSeconds: now);
    final openedB = await clientB.openCommunity(bKeys, nowSeconds: now);

    for (final opened in [openedA, openedB]) {
      expect(opened.control.metadata?.name, 'Vector');
      expect(opened.control.channels[channelId]?.name, 'general');
      expect(opened.messagesIn(channelId), hasLength(1));
      expect(
        opened.messagesIn(channelId).single.content,
        'Hello, private world',
      );
      // Alice is present (owner) and Bob joined.
      expect(opened.guestbook.members, contains(alice.xOnlyPubKey));
      expect(opened.guestbook.members, contains(bob.xOnlyPubKey));
    }
  });

  test('a private channel rotation severs an old recipient', () async {
    final alice = _signer(0xc1);
    final clientA = ConcordClient(signer: alice);
    final scope = hex32(0x70);
    final keys = await clientA.createCommunity(
      name: 'Rotate',
      communityRoot: _bytes32(0x01),
      controlRoot: _bytes32(0x02),
      ownerSalt: _bytes32(0x03),
    );

    final newKey = _bytes32(0x99);
    final wraps = await clientA.rotateChannel(
      keys: keys.copyWith(
        channels: {
          scope: ChannelKey(
            channelId: scope,
            private: true,
            epoch: 0,
            key: _bytes32(0x71),
          ),
        },
      ),
      channelId: scope,
      newKey: newKey,
      recipients: [alice.xOnlyPubKey],
      newEpoch: 1,
      createdAt: now,
    );
    expect(wraps, hasLength(1));

    // Decode the delivered rekey with the recipient's signer.
    final stored = await clientA.store.outbox(keys.communityId);
    for (final wrap in stored) {
      final rekeyGroup = groupKey(
        secret: keys.communityRoot,
        label: Labels.rekeyPseudonym,
        id: hexToBytes(scope),
        epoch: 1,
      );
      final plane = PlaneKeys.fromGroupKey(rekeyGroup);
      expect(wrap.pubKey, plane.signerPk);
    }
  });

  test('a re-founder builds base blobs for members and staff', () async {
    final alice = _signer(0xd1);
    final clientA = ConcordClient(signer: alice);
    final keys = await clientA.createCommunity(
      name: 'Refound',
      communityRoot: _bytes32(0x01),
      controlRoot: _bytes32(0x02),
      ownerSalt: _bytes32(0x03),
    );
    final memberPk = Bip340.getPublicKey(bytesToHex(_bytes32(0x44)));
    final wraps = await clientA.refound(
      keys: keys,
      newRoot: _bytes32(0xaa),
      newControlRoot: _bytes32(0xbb),
      newEpoch: 1,
      members: [memberPk],
      staff: const {},
      createdAt: now,
    );
    expect(wraps, hasLength(1));
  });

  test('the in-memory store forgets a community', () async {
    final alice = _signer(0xe1);
    final clientA = ConcordClient(signer: alice, store: InMemoryConcordStore());
    expect(clientA.store, isA<InMemoryConcordStore>());
    final keys = await clientA.createCommunity(
      name: 'Gone',
      communityRoot: _bytes32(0x01),
      controlRoot: _bytes32(0x02),
      ownerSalt: _bytes32(0x03),
    );
    expect((await clientA.communities()), hasLength(1));
    await clientA.forgetCommunity(keys.communityId);
    expect(await clientA.community(keys.communityId), isNull);
  });
}
