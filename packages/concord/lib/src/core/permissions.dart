import 'encoding.dart';

/// Frozen permission bits (CORD-04 §3).
///
/// One `u64`; bit positions never move — a new permission claims the next
/// free bit, a retired one is burned. On the wire `permissions` is a
/// **decimal string** (a JSON number would silently corrupt past 2^53 in
/// JavaScript); a reader accepts either form and always writes the string.
class Permissions {
  static const int manageRoles = 1 << 0;
  static const int manageChannels = 1 << 1;
  static const int manageMetadata = 1 << 2;
  static const int kick = 1 << 3;
  static const int ban = 1 << 4;
  static const int manageMessages = 1 << 5;
  static const int createInvite = 1 << 6;

  /// Retired (was MANAGE_INVITES) — burned, never reused.
  static const int retiredManageInvites = 1 << 7;

  static const int viewAuditLog = 1 << 8;
  static const int mentionEveryone = 1 << 9;

  /// Reserved (MANAGE_EMOJI, MANAGE_EVENTS).
  static const int reservedManageEmoji = 1 << 10;
  static const int pinMessages = 1 << 11;
  static const int reservedManageEvents = 1 << 12;

  /// The bits that gate actions landing as Control editions; a member
  /// holding any of them — plus always the owner — is **staff** and holds
  /// the `control_root` (CORD-04 §3, normative list).
  static const int staffBits =
      manageRoles |
      manageChannels |
      manageMetadata |
      ban |
      createInvite |
      pinMessages;

  /// Parses the wire form (decimal string or, from older editions, a
  /// number). Returns 0 for malformed input — permissions fail closed.
  static int parse(Object? raw) {
    int? value;
    if (raw is String) {
      value = tryParseDecimal(raw);
    } else if (raw is int) {
      value = raw;
    } else if (raw is double && raw == raw.roundToDouble()) {
      value = raw.toInt();
    }
    if (value == null || value < 0) return 0;
    return value;
  }

  /// Wire form: always the decimal string.
  static String serialize(int permissions) => '$permissions';

  static bool has(int permissions, int bit) => permissions & bit == bit;

  /// Union of the bits in [roles]' permission sets.
  static int union(Iterable<int> rolePermissions) =>
      rolePermissions.fold(0, (acc, p) => acc | p);

  static bool isStaff(int permissions) =>
      permissions & staffBits != 0 || permissions == ownerPermissions;

  /// The owner's effective permissions: every defined bit set
  /// (CORD-04 §3 — "an admin holds the union of the management bits").
  static const int ownerPermissions =
      manageRoles |
      manageChannels |
      manageMetadata |
      kick |
      ban |
      manageMessages |
      createInvite |
      viewAuditLog |
      mentionEveryone |
      pinMessages;
}
