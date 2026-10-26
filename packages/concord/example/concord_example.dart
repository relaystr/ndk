// ignore_for_file: avoid_print
//
// A complete Concord round-trip, entirely in-process: Alice creates a private
// community with a private channel, invites Bob with a Direct Invite, Bob
// joins the guestbook, Alice sends an encrypted message, and both fold the
// same picture.
//
// `ConcordClient` does no relay I/O. The `deliver` helper below stands in for
// a relay: it copies a client's outbox wraps into the recipient's store by
// trying every plane the recipient can read. In a real app you would
// subscribe with NDK and hand each incoming event to `openAndStore`.
//
// Run with: dart run example/concord_example.dart

import 'dart:typed_data';

import 'package:concord/concord.dart';

/// A throwaway in-memory signer, for the example only. Real apps pass their
/// own [EventSigner] (e.g. an Amber / NIP-46 signer).
LocalSecretSigner _signer(int byte) => LocalSecretSigner(
  privateKey: List.filled(32, byte.toRadixString(16).padLeft(2, '0')).join(),
);

Uint8List _bytes32(int fill) => Uint8List.fromList(List.filled(32, fill));

/// Plays relay for one direction: hands each of [from]'s queued wraps to
/// [to], trying the Control Plane, the Guestbook and each held channel.
Future<void> _deliver(
  ConcordClient from,
  CommunityKeys fromKeys,
  ConcordClient to,
  CommunityKeys toKeys,
) async {
  if (fromKeys.communityId != toKeys.communityId) return;
  for (final wrap in await from.store.outbox(fromKeys.communityId)) {
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

    final guestbook = Planes.guestbookKey(toKeys);
    final atGuestbook = await to.openAndStore(
      keys: toKeys,
      wrap: wrap,
      streamAddress: guestbook.pk,
      convKey: guestbook.convKey,
      form: SealForm.encrypted,
    );
    if (atGuestbook != null) continue;

    for (final channelId in toKeys.channels.keys) {
      final plane = PlaneKeys.fromGroupKey(
        Planes.channelKey(toKeys, channelId),
      );
      final atChannel = await to.openAndStore(
        keys: toKeys,
        wrap: wrap,
        streamAddress: plane.signerPk,
        convKey: plane.convKey,
        form: SealForm.encrypted,
      );
      if (atChannel != null) break;
    }
  }
  await from.store.clearOutbox(fromKeys.communityId);
}

Future<void> main() async {
  const now = 1700000000;

  final alice = _signer(0x0a);
  final bob = _signer(0x0b);
  final clientA = ConcordClient(signer: alice);
  final clientB = ConcordClient(signer: bob);

  // --- Alice creates the community and a private channel.
  final channelId = List.filled(32, '70').join();
  final channelKey = _bytes32(0x71);

  var aKeys = await clientA.createCommunity(
    name: 'Vector',
    relays: const ['wss://relay.example'],
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

  // --- Alice invites Bob; Bob accepts and joins the guestbook.
  final inviteWrap = await clientA.createDirectInvite(
    aKeys,
    recipient: bob.getPublicKey(),
    createdAt: now,
  );
  final bKeys = await clientB.acceptDirectInvite(inviteWrap);
  if (bKeys == null) {
    print('Bob refused the invite.');
    return;
  }

  await clientB.sendGuestbookVerb(
    keys: bKeys,
    verb: 'join',
    createdAt: now,
    ms: 0,
  );

  // --- Crank the "relay" both ways, then Alice speaks.
  await _deliver(clientA, aKeys, clientB, bKeys);
  await _deliver(clientB, bKeys, clientA, aKeys);

  await clientA.sendChat(
    keys: aKeys,
    channelId: channelId,
    content: 'Hello, private world',
    createdAt: now,
    ms: 5,
  );
  await _deliver(clientA, aKeys, clientB, bKeys);

  // --- Both members fold the same picture.
  final viewA = await clientA.openCommunity(aKeys, nowSeconds: now);
  final viewB = await clientB.openCommunity(bKeys, nowSeconds: now);

  print('community:  ${viewA.communityId}');
  print('name:       ${viewA.control.metadata?.name}');
  print('channel:    ${viewA.control.channels[channelId]?.name}');
  print('members:    ${viewB.guestbook.members.length}');
  print('messages:   ${viewB.messagesIn(channelId).single.content}');

  // Alice's and Bob's folds agree.
  assert(
    viewA.messagesIn(channelId).length == viewB.messagesIn(channelId).length,
  );
}
