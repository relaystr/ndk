# concord

A Dart implementation of the [Concord protocol](https://concordprotocol.org/spec/) —
end-to-end encrypted communities and **private channels** over Nostr, with
owner-rooted roles and permissions.

Concord gives a small group of people a shared private space that no relay can
read and no single member can silently rewrite: membership, roles, channels and
messages all live in append-only, cryptographically chained logs that every
member folds into the same picture.

This package builds on [`ndk`](https://pub.dev/packages/ndk) for low-level
primitives (BIP-340 signing/verification, NIP-44 v2, `Nip01Event`, `EventSigner`,
pending signer requests), but is otherwise **self-contained**: it does not touch
NDK's `Ndk`/`Accounts`/cache layers, and it does not modify NDK.

## What's implemented

| Area | Spec | Notes |
| --- | --- | --- |
| Private streams (seal / wrap / encrypt) | CORD-01 | Local implementation of the Concord stream envelope. |
| Communities, identity, channels | CORD-02 | `community_id`, epoch keys, per-channel keys, guestbook. |
| Channels (public + private) | CORD-03 | Both derived from `community_root`; private keys rotate. |
| Roles & permissions | CORD-04 | Owner-rooted roster, u64 permission bits, authority rules. |
| Invites | CORD-05 | Direct Invites (standard NIP-59 kind 1059). Invite Links/Bundles/Registry reserved. |
| Rekeys & Refounding | CORD-06 | Channel rotation (72-byte blobs), base rotation (104/136-byte blobs). |
| Disappearing Messages | CORD-08 | `Millis` timestamps and timer notices. |
| Community List | CORD-02 §8 | Local, encrypted kind 13302 list. |

## Install

```yaml
dependencies:
  concord: ^0.1.0-dev.1
```

## Concepts

- **Community keys** (`CommunityKeys`) are what a member holds: the
  `community_id`, the owner's pubkey and salt (so anyone can confirm the
  founder), the rotating `community_root` access key, the current Control Plane
  address `control_pk`, and — for staff only — the `control_root` write secret.
- **Planes** are separate, purpose-scoped streams derived from those keys:
  the Control Plane (metadata, roles, channels, bans), the Guestbook Plane
  (join/leave/kick, the complete memberlist) and one Chat Plane per
  channel-epoch.
- A **rumor** is a signed but unwrapped Nostr event. It is sealed (signed again
  by the plane's *stream author*) and wrapped into a kind 20013 event. Only the
  seal/wrap outer metadata is public; everything inside is NIP-44 encrypted
  under the plane's conversation key.
- The **Control Plane** is the authority: its editions form a hash-chained log
  (`prev` → `edition_hash`) that folds into metadata, the roster, the channel
  list and the banlist. Chat and guestbook events are only accepted if the
  Control fold (and the guestbook) allow them.

## Quick start

```dart
import 'dart:typed_data';

import 'package:concord/concord.dart';

Future<void> main() async {
  final alice = LocalSecretSigner(privateKey: '<hex-secret-key>');
  final client = ConcordClient(signer: alice);

  // 1. Create a community (the signer's key is the owner).
  var keys = await client.createCommunity(
    name: 'Vector',
    relays: const ['wss://relay.example'],
  );

  // 2. Add a private channel (kept in the member's own key material).
  final channelId = '<32-byte-hex-scope-id>';
  keys = keys.copyWith(channels: {
    channelId: ChannelKey(
      channelId: channelId,
      private: true,
      epoch: 0,
      key: Uint8List.fromList(List.filled(32, 0x71)), // 32 random bytes
    ),
  });
  await client.saveCommunity(keys);

  // 3. Publish metadata for the community and the channel.
  await client.sendControlEdition(
    keys: keys,
    vsk: Vsk.communityMetadata,
    eid: keys.communityId,
    content: CommunityMetadata(name: 'Vector').toContentJson(),
  );
  await client.sendControlEdition(
    keys: keys,
    vsk: Vsk.channelMetadata,
    eid: channelId,
    content: ChannelMetadata(name: 'general', private: true).toContentJson(),
  );

  // 4. Invite Bob. Publish the returned wrap to Alice's relays (kind 1059).
  final invite = await client.createDirectInvite(
    keys,
    recipient: '<bobs-x-only-pubkey-hex>',
  );
  // ... relay.broadcast(invite);

  // 5. Send an encrypted message.
  final wrap = await client.sendChat(
    keys: keys,
    channelId: channelId,
    content: 'Hello, private world',
  );
  // ... relay.broadcast(wrap);

  // 6. Fold everything the store has seen into one picture.
  final view = await client.openCommunity(keys);
  print(view.control.metadata?.name);          // Vector
  print(view.messagesIn(channelId).single.content); // Hello, private world
}
```

### Receiving

`ConcordClient` does **no relay I/O**. Your app subscribes, then hands each
incoming event to `openAndStore`, trying the planes the member can read:

```dart
// The Control Plane (plaintext seal — authorities must be public).
final control = Planes.controlReadKeys(keys, heldControlPk: keys.controlPk);
await client.openAndStore(
  keys: keys,
  wrap: event,
  streamAddress: control.signerPk,
  convKey: control.convKey,
  form: SealForm.plaintext,
);

// A channel (encrypted seal).
final plane = PlaneKeys.fromGroupKey(Planes.channelKey(keys, channelId));
await client.openAndStore(
  keys: keys,
  wrap: event,
  streamAddress: plane.signerPk,
  convKey: plane.convKey,
  form: SealForm.encrypted,
);
```

Broadcast the wraps from `store.outbox(communityId)`, then
`store.clearOutbox(communityId)`.

### Accepting an invite

```dart
final keys = await client.acceptDirectInvite(incomingKind1059);
if (keys != null) {
  await client.sendGuestbookVerb(keys: keys, verb: 'join');
}
```

## Storage

`ConcordClient` takes a `ConcordStore`. The package ships an
`InMemoryConcordStore`; apps that need durability implement the interface over
their own database (it is object-based: communities, rumors, wraps/outbox).

```dart
class MyStore implements ConcordStore { /* ... */ }
final client = ConcordClient(signer: alice, store: MyStore());
```

## ⚠️ Relay requirement for private streams

The Concord stream wrapper uses a **fixed stream author** and a random ephemeral
`p` tag: members subscribe *by the stream author*, not by their own pubkey.
Because of that, private streams only work on relays that **do not enforce
NIP-59's `p`-tag recipient guard**. Relays that require the wrap's `p` tag to
equal the recipient will drop these events.

Direct Invites (kind 1059) and Control Plane editions (kind 20014, plaintext
seal) are standards-compliant and work anywhere; it is the kind 20013 private
stream wraps that need a permissive relay.

## Security model in one paragraph

The Control Plane is a hash-chained, signed log folded by a fixpoint over the
highest intact version; roles outrank each other strictly (a role may never act
on a peer or superior, and never on the owner), retired permission bits are
burned rather than reused, and a member who falls behind a Refounding is
*suspended* (fail-closed) rather than allowed to act on stale state. Every
private plane is NIP-44 encrypted under a conversation key derived from a
`community_root` that rotates at each Refounding, so removing a member and
rolling the root cryptographically severs their future access.

## Status

Early development (`0.1.0-dev.1`). The implemented surface is covered by tests
(`dart test`); Invite Links/Bundles/Registry (CORD-05 §2–5), Pins (vsk 11) and
Dissolution tombstones are reserved but not yet implemented.

## License

MIT — see [`LICENSE`](LICENSE).
