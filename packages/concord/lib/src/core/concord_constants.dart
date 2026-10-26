/// Frozen protocol constants (CORD-02 Appendix B, CORD-04 §3, CORD-06 §1).
///
/// Nothing here may change: a retired kind or permission bit is burned,
/// never reused.
library;

/// Envelope kinds (CORD-01).
class Kinds {
  /// Durable stream giftwrap (every plane event rides one).
  static const int streamWrap = 1059;

  /// Ephemeral stream giftwrap (typing, voice presence). Relays must not
  /// store it.
  static const int ephemeralStreamWrap = 21059;

  /// Encrypted seal (Chat, Guestbook, rekey planes).
  static const int encryptedSeal = 20013;

  /// Plaintext seal (Control Plane only).
  static const int plaintextSeal = 20014;

  /// Standard NIP-59 seal (only the Direct Invite uses it).
  static const int nip59Seal = 13;
}

/// Rumor kinds by plane (CORD-02 Appendix B).
class RumorKinds {
  /// Message (NIP-C7 shape), Chat plane.
  static const int message = 9;

  /// Threaded reply (NIP-22 shape), Chat plane.
  static const int threadedReply = 1111;

  /// Reaction (NIP-25 shape), Chat plane.
  static const int reaction = 7;

  /// Delete (NIP-09 shape), Chat plane.
  static const int delete = 5;

  /// Timer notice (CORD-08 §4), Chat plane.
  static const int timerNotice = 1740;

  /// WebXDC peer signal, Chat plane.
  static const int webxdc = 3310;

  /// Edit, Chat plane.
  static const int edit = 3302;

  /// Rekey blobs (CORD-06).
  static const int rekey = 3303;

  /// Join / Leave, Guestbook plane.
  static const int joinLeave = 3306;

  /// Control edition (sub-kinded by `vsk`), Control Plane.
  static const int controlEdition = 3308;

  /// Kick, Guestbook plane.
  static const int kick = 3309;

  /// Guestbook snapshot, Guestbook plane.
  static const int snapshot = 3312;

  /// Direct invite (standard NIP-59 wrap, person-to-person).
  static const int directInvite = 3313;

  /// Public invite bundle (reserved, CORD-05 §2 — not implemented).
  static const int inviteBundle = 33301;

  /// Community List (CORD-02 §8), signed by the member's real key.
  static const int communityList = 13302;

  /// Invite List (reserved, CORD-05 §4 — not implemented).
  static const int inviteList = 13303;
}

/// Sub-kinds (`vsk`) of the Control edition (CORD-02 Appendix B).
class Vsk {
  static const int communityMetadata = 0;
  static const int role = 1;
  static const int channelMetadata = 2;
  static const int grant = 3;
  static const int banlist = 4;
  // 5 reserved (role ordering).
  static const int inviteLinkMarker = 6; // claimed by the addressable invite
  static const int inviteRegistry = 8;
  static const int inviteTombstoneMarker =
      9; // claimed by the addressable invite
  static const int dissolved = 10;
  static const int pinList = 11;
}

/// HKDF info labels (CORD-02 Appendix A.6). Frozen byte-for-byte.
class Labels {
  static const String channel = 'concord/channel';
  static const String control = 'concord/control';
  static const String controlSigner = 'concord/control-signer';
  static const String rekeyPseudonym = 'concord/rekey-pseudonym';
  static const String baseRekeyPseudonym = 'concord/base-rekey-pseudonym';
  static const String recipientPseudonym = 'concord/recipient-pseudonym';
  static const String guestbook = 'concord/guestbook';
  // Reserved (CORD-07): voice-signer / voice-media / voice-sender.
  static const String voiceSigner = 'concord/voice-signer';
  static const String voiceMedia = 'concord/voice-media';
  static const String voiceSender = 'concord/voice-sender';
  static const String dissolved = 'concord/dissolved';
  static const String grant = 'concord/grant';
  static const String banlist = 'concord/banlist';
  static const String pins = 'concord/pins';
  static const String inviteLinks = 'concord/invite-links';
  static const String inviteKey = 'concord/invite-key';

  /// Domain separator for the community_id commitment (CORD-02 §1).
  static const String community = 'concord/community';

  /// Domain separator for the edition hash (CORD-04 §1).
  static const String editionHash = 'vector-community/v1/edition';

  /// Domain separator for the epoch-key commitment (CORD-02 A.5).
  static const String epochKeyCommitment = 'concord/epoch-key-commitment';
}

/// Protocol sizes and caps.
class Caps {
  /// NIP-44 plaintext hard cap; enforced by us at every nesting layer
  /// (implementer checklist: "Encryption and size").
  static const int nip44Plaintext = 65535;

  /// Channels accepted in one invite bundle before refusal (CORD-05 §1).
  static const int inviteBundleChannels = 256;

  /// Recommended relay cap; longer sets are truncated (CORD-02 §6).
  static const int communityRelays = 5;

  /// Memberships in one Community List (CORD-02 §8).
  static const int communityListMemberships = 50;

  /// Roles per Community — a client folds the 100 lowest role_ids
  /// and ignores the rest (CORD-04 §2).
  static const int communityRoles = 100;

  /// Roles one member may hold (CORD-04 §2).
  static const int memberRoles = 64;

  /// Participants per rekey blob event (CORD-06 §1).
  static const int rekeyBlobRecipients = 120;

  /// Members per guestbook snapshot chunk (CORD-02 §5).
  static const int snapshotChunk = 400;

  /// Banlist practical ceiling (CORD-04 §4).
  static const int banlistNpubs = 500;

  /// Name cap in bytes (UTF-8), uniform across the protocol (CORD-02 §6).
  static const int nameBytes = 64;

  /// Description cap in bytes (UTF-8) (CORD-02 §6).
  static const int descriptionBytes = 10000;

  /// Rekey blob widths in bytes (CORD-06 §1).
  static const int channelBlobBytes = 72;
  static const int baseBlobBytes = 104;
  static const int baseBlobStaffBytes = 136;

  /// `control_wrap` plaintext: `epoch_be[8] ‖ control_root[32]`
  /// (CORD-04 §3).
  static const int controlWrapBytes = 40;
}
