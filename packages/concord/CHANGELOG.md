## 0.1.0-dev.1

 - Initial release: Concord (CORD) protocol implementation for Dart.
 - Private streams (CORD-01): stream envelope, NIP-44 sealing and wrapping.
 - Communities and channels (CORD-02, CORD-03): identity, epoch keys, private
   channel keys, guestbook.
 - Roles and permissions (CORD-04): owner-rooted roster, u64 permission bits,
   authority rules.
 - Invites (CORD-05): Direct Invites (standard NIP-59).
 - Rekeys and Refounding (CORD-06): channel and base rotations.
 - Disappearing Messages (CORD-08): `Millis` timestamps and timer notices.
 - `ConcordClient` facade and an in-memory `ConcordStore`.
