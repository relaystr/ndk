/// Concord (CORD) — end-to-end encrypted communities and private channels
/// over Nostr.
///
/// This library implements the Concord protocol's durable planes:
/// private streams (CORD-01), communities (CORD-02), channels (CORD-03),
/// roles and permissions (CORD-04), invites (CORD-05) and rekeys (CORD-06),
/// plus Disappearing Messages (CORD-08).
///
/// Start with [ConcordClient] — it holds an `EventSigner` and a
/// [ConcordStore], and turns app-level actions into sealed, wrapped events
/// and back.
library;

// Core.
export 'src/core/concord_constants.dart';
export 'src/core/concord_time.dart';
export 'src/core/derivations.dart'
    show
        GroupKey,
        groupKey,
        scalarNormalize,
        communityId,
        epochKeyCommitment,
        recipientLocator,
        baseScopeId,
        Locators;
export 'src/core/encoding.dart';
export 'src/core/hkdf.dart';
export 'src/core/permissions.dart';

// Stream envelope (CORD-01).
export 'src/stream/stream_envelope.dart';

// Keys and planes (CORD-02 §2/§5, CORD-03).
export 'src/keys/concord_keys.dart';

// Models.
export 'src/model/metadata.dart';
export 'src/model/role.dart';

// Control Plane (CORD-04).
export 'src/control/control_edition.dart';
export 'src/control/control_fold.dart';
export 'src/control/entity_chain.dart';

// Roles and authority.
export 'src/roster/roster.dart';

// Chat Plane (CORD-02 §5, CORD-08).
export 'src/chat/chat.dart';

// Guestbook Plane (CORD-02 §5).
export 'src/guestbook/guestbook.dart';

// Rekeys (CORD-06).
export 'src/rekey/rekey_blob.dart';

// Invites (CORD-05).
export 'src/invite/community_invite.dart';
export 'src/invite/direct_invite.dart';

// Community List (CORD-02 §8).
export 'src/list/community_list.dart';

// Storage.
export 'src/store/concord_store.dart';

// The client facade.
export 'src/client/concord_client.dart';
