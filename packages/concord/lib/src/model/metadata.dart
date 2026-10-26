import '../core/encoding.dart';

/// A Community's metadata (CORD-02 §6, vsk 0).
///
/// Unknown fields are preserved (round-trip discipline) — client-specific
/// keys belong in `custom`, and top-level fields outside `custom` are
/// reserved for the protocol.
class CommunityMetadata {
  final String name;
  final String? description;
  final List<String> relays;

  /// Encrypted-blob pointer `{url, key, nonce, hash}`.
  final Map<String, Object?>? icon;
  final Map<String, Object?>? banner;

  /// The disappearing-messages timer in seconds (CORD-08 §1). Absent, 0 or
  /// malformed means off.
  final int? messageExpiration;

  /// Client-extensible object; round-tripped atomically with the entity.
  final Map<String, Object?>? custom;

  /// Unknown top-level fields, preserved.
  final Map<String, Object?> extra;

  CommunityMetadata({
    required this.name,
    this.description,
    this.relays = const [],
    this.icon,
    this.banner,
    this.messageExpiration,
    this.custom,
    this.extra = const {},
  });

  bool get hasDisappearingMessages =>
      messageExpiration != null && messageExpiration! > 0;

  static const Set<String> _knownKeys = {
    'name',
    'description',
    'relays',
    'icon',
    'banner',
    'message_expiration',
    'custom',
  };

  static CommunityMetadata? tryParse(Object? content) {
    if (content is! Map) return null;
    final name = content['name'];
    if (name is! String) return null;
    final description = content['description'];
    final relaysRaw = content['relays'];
    final expirationRaw = content['message_expiration'];

    // Absent, 0, or malformed means off — never guess a default (CORD-08).
    int? expiration;
    if (expirationRaw is int && expirationRaw > 0) {
      expiration = expirationRaw;
    }

    return CommunityMetadata(
      name: name,
      description: description is String ? description : null,
      relays: relaysRaw is List
          ? relaysRaw.whereType<String>().toList(growable: false)
          : const [],
      icon: content['icon'] is Map
          ? Map<String, Object?>.from(content['icon'] as Map)
          : null,
      banner: content['banner'] is Map
          ? Map<String, Object?>.from(content['banner'] as Map)
          : null,
      messageExpiration: expiration,
      custom: content['custom'] is Map
          ? Map<String, Object?>.from(content['custom'] as Map)
          : null,
      extra: {
        for (final entry in content.entries)
          if (!_knownKeys.contains(entry.key)) '${entry.key}': entry.value,
      },
    );
  }

  CommunityMetadata copyWith({
    String? name,
    String? description,
    List<String>? relays,
    int? messageExpiration,
    bool clearMessageExpiration = false,
    Map<String, Object?>? custom,
    Map<String, Object?>? extra,
  }) => CommunityMetadata(
    name: name ?? this.name,
    description: description ?? this.description,
    relays: relays ?? this.relays,
    icon: icon,
    banner: banner,
    messageExpiration: clearMessageExpiration
        ? null
        : (messageExpiration ?? this.messageExpiration),
    custom: custom ?? this.custom,
    extra: extra ?? this.extra,
  );

  String toContentJson() => encodeJson({
    'name': name,
    if (description != null) 'description': description,
    'relays': relays,
    if (icon != null) 'icon': icon,
    if (banner != null) 'banner': banner,
    if (messageExpiration != null) 'message_expiration': messageExpiration,
    if (custom != null) 'custom': custom,
    ...extra,
  });
}

/// A Channel's metadata (CORD-03 §2, vsk 2). The `channel_id` is the
/// edition's `eid`.
class ChannelMetadata {
  final String name;
  final bool private;
  final bool deleted;
  final Map<String, Object?>? custom;
  final Map<String, Object?> extra;

  ChannelMetadata({
    required this.name,
    required this.private,
    this.deleted = false,
    this.custom,
    this.extra = const {},
  });

  static const Set<String> _knownKeys = {
    'name',
    'private',
    'deleted',
    'custom',
  };

  static ChannelMetadata? tryParse(Object? content) {
    if (content is! Map) return null;
    final name = content['name'];
    if (name is! String) return null;
    final isPrivate = content['private'];
    return ChannelMetadata(
      name: name,
      private: isPrivate is bool ? isPrivate : false,
      deleted: content['deleted'] == true,
      custom: content['custom'] is Map
          ? Map<String, Object?>.from(content['custom'] as Map)
          : null,
      extra: {
        for (final entry in content.entries)
          if (!_knownKeys.contains(entry.key)) '${entry.key}': entry.value,
      },
    );
  }

  String toContentJson() => encodeJson({
    'name': name,
    'private': private,
    if (deleted) 'deleted': true,
    if (custom != null) 'custom': custom,
    ...extra,
  });
}
