import 'nip_01_event.dart';

enum EventDeliveryStatus {
  pending,
  inProgress,
  partiallyDelivered,
  delivered,
  needsAction,
  failed,
}

enum RelayDeliveryState {
  pending,
  attempting,
  acked,
  transientFailure,
  permanentFailure,
  authRequired,
}

enum RelayDeliveryReason {
  authorWrite,
  authorRead,
  replyAuthorRead,
  mentionRead,
  explicit,
  hint,
}

class RelayDeliveryTarget {
  final String relayUrl;
  final RelayDeliveryReason reason;
  final RelayDeliveryState state;
  final int attemptCount;
  final int? lastAttemptAt;
  final int? nextRetryAt;
  final String? lastError;
  final String? lastOkMessage;

  const RelayDeliveryTarget({
    required this.relayUrl,
    required this.reason,
    this.state = RelayDeliveryState.pending,
    this.attemptCount = 0,
    this.lastAttemptAt,
    this.nextRetryAt,
    this.lastError,
    this.lastOkMessage,
  });

  RelayDeliveryTarget copyWith({
    String? relayUrl,
    RelayDeliveryReason? reason,
    RelayDeliveryState? state,
    int? attemptCount,
    int? lastAttemptAt,
    int? nextRetryAt,
    String? lastError,
    String? lastOkMessage,
  }) {
    return RelayDeliveryTarget(
      relayUrl: relayUrl ?? this.relayUrl,
      reason: reason ?? this.reason,
      state: state ?? this.state,
      attemptCount: attemptCount ?? this.attemptCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      lastError: lastError ?? this.lastError,
      lastOkMessage: lastOkMessage ?? this.lastOkMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'relayUrl': relayUrl,
      'reason': reason.name,
      'state': state.name,
      'attemptCount': attemptCount,
      'lastAttemptAt': lastAttemptAt,
      'nextRetryAt': nextRetryAt,
      'lastError': lastError,
      'lastOkMessage': lastOkMessage,
    };
  }

  factory RelayDeliveryTarget.fromJson(Map<String, dynamic> json) {
    return RelayDeliveryTarget(
      relayUrl: json['relayUrl'] as String,
      reason: RelayDeliveryReason.values.byName(json['reason'] as String),
      state: RelayDeliveryState.values.byName(json['state'] as String),
      attemptCount: json['attemptCount'] as int? ?? 0,
      lastAttemptAt: json['lastAttemptAt'] as int?,
      nextRetryAt: json['nextRetryAt'] as int?,
      lastError: json['lastError'] as String?,
      lastOkMessage: json['lastOkMessage'] as String?,
    );
  }
}

class EventDeliveryRecord {
  final String eventId;
  final EventDeliveryStatus status;
  final int createdAt;
  final int updatedAt;
  final int? signedAt;
  final int? completedAt;
  final bool requiresNetworkSigner;
  final List<RelayDeliveryTarget> targets;

  const EventDeliveryRecord({
    required this.eventId,
    this.status = EventDeliveryStatus.pending,
    required this.createdAt,
    required this.updatedAt,
    this.signedAt,
    this.completedAt,
    this.requiresNetworkSigner = false,
    this.targets = const [],
  });

  bool get isComplete => status == EventDeliveryStatus.delivered;

  bool get hasPendingTargets =>
      targets.any((target) => target.state != RelayDeliveryState.acked);

  EventDeliveryRecord copyWith({
    String? eventId,
    EventDeliveryStatus? status,
    int? createdAt,
    int? updatedAt,
    int? signedAt,
    int? completedAt,
    bool? requiresNetworkSigner,
    List<RelayDeliveryTarget>? targets,
  }) {
    return EventDeliveryRecord(
      eventId: eventId ?? this.eventId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      signedAt: signedAt ?? this.signedAt,
      completedAt: completedAt ?? this.completedAt,
      requiresNetworkSigner:
          requiresNetworkSigner ?? this.requiresNetworkSigner,
      targets: targets ?? this.targets,
    );
  }

  EventDeliveryRecord updateTarget(
    String relayUrl,
    RelayDeliveryTarget Function(RelayDeliveryTarget current) update, {
    int? updatedAt,
  }) {
    final newTargets = targets
        .map((target) => target.relayUrl == relayUrl ? update(target) : target)
        .toList();
    return copyWith(
      updatedAt: updatedAt ?? this.updatedAt,
      targets: newTargets,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'status': status.name,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'signedAt': signedAt,
      'completedAt': completedAt,
      'requiresNetworkSigner': requiresNetworkSigner,
      'targets': targets.map((target) => target.toJson()).toList(),
    };
  }

  factory EventDeliveryRecord.fromJson(Map<String, dynamic> json) {
    return EventDeliveryRecord(
      eventId: json['eventId'] as String,
      status: EventDeliveryStatus.values.byName(json['status'] as String),
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
      signedAt: json['signedAt'] as int?,
      completedAt: json['completedAt'] as int?,
      requiresNetworkSigner: json['requiresNetworkSigner'] as bool? ?? false,
      targets: ((json['targets'] as List?) ?? [])
          .map((target) => RelayDeliveryTarget.fromJson(
              Map<String, dynamic>.from(target as Map)))
          .toList(),
    );
  }
}

class CachedEventRecord {
  final String eventId;
  final Nip01Event event;
  final String? dTag;
  final String? coordinateKey;
  final bool isReplaceable;
  final bool isAddressable;
  final bool isCurrent;
  final String? supersededByEventId;
  final int? expirationAt;
  final String? deletedByEventId;
  final int? deletedAt;
  final List<String> sourceRelays;
  final int firstSeenAt;
  final int lastSeenAt;
  final bool localOrigin;
  final int? localCreatedAt;

  const CachedEventRecord({
    required this.eventId,
    required this.event,
    this.dTag,
    this.coordinateKey,
    required this.isReplaceable,
    required this.isAddressable,
    this.isCurrent = true,
    this.supersededByEventId,
    this.expirationAt,
    this.deletedByEventId,
    this.deletedAt,
    this.sourceRelays = const [],
    required this.firstSeenAt,
    required this.lastSeenAt,
    this.localOrigin = false,
    this.localCreatedAt,
  });

  String get pubKey => event.pubKey;

  int get kind => event.kind;

  int get createdAt => event.createdAt;

  bool get isDeleted => deletedByEventId != null;

  bool isExpiredAt(int timestamp) =>
      expirationAt != null && expirationAt! <= timestamp;

  CachedEventRecord copyWith({
    String? eventId,
    Nip01Event? event,
    String? dTag,
    String? coordinateKey,
    bool? isReplaceable,
    bool? isAddressable,
    bool? isCurrent,
    String? supersededByEventId,
    int? expirationAt,
    String? deletedByEventId,
    int? deletedAt,
    List<String>? sourceRelays,
    int? firstSeenAt,
    int? lastSeenAt,
    bool? localOrigin,
    int? localCreatedAt,
  }) {
    return CachedEventRecord(
      eventId: eventId ?? this.eventId,
      event: event ?? this.event,
      dTag: dTag ?? this.dTag,
      coordinateKey: coordinateKey ?? this.coordinateKey,
      isReplaceable: isReplaceable ?? this.isReplaceable,
      isAddressable: isAddressable ?? this.isAddressable,
      isCurrent: isCurrent ?? this.isCurrent,
      supersededByEventId: supersededByEventId ?? this.supersededByEventId,
      expirationAt: expirationAt ?? this.expirationAt,
      deletedByEventId: deletedByEventId ?? this.deletedByEventId,
      deletedAt: deletedAt ?? this.deletedAt,
      sourceRelays: sourceRelays ?? this.sourceRelays,
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      localOrigin: localOrigin ?? this.localOrigin,
      localCreatedAt: localCreatedAt ?? this.localCreatedAt,
    );
  }

  factory CachedEventRecord.fromEvent(
    Nip01Event event, {
    List<String>? sourceRelays,
    int? seenAt,
    bool localOrigin = false,
    int? localCreatedAt,
  }) {
    final normalizedSources = _dedupeRelays(sourceRelays ?? event.sources);
    final derivedSeenAt = seenAt ?? Nip01Event.secondsSinceEpoch();
    final dTag = event.getDtag();
    final isAddressable = _isAddressableKind(event.kind);
    final isReplaceable = _isReplaceableKind(event.kind);

    return CachedEventRecord(
      eventId: event.id,
      event: event,
      dTag: dTag,
      coordinateKey: _buildCoordinateKey(event, dTag, isAddressable),
      isReplaceable: isReplaceable,
      isAddressable: isAddressable,
      expirationAt: _extractExpirationAt(event),
      sourceRelays: normalizedSources,
      firstSeenAt: derivedSeenAt,
      lastSeenAt: derivedSeenAt,
      localOrigin: localOrigin,
      localCreatedAt: localCreatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'event': _eventToJson(event),
      'dTag': dTag,
      'coordinateKey': coordinateKey,
      'isReplaceable': isReplaceable,
      'isAddressable': isAddressable,
      'isCurrent': isCurrent,
      'supersededByEventId': supersededByEventId,
      'expirationAt': expirationAt,
      'deletedByEventId': deletedByEventId,
      'deletedAt': deletedAt,
      'sourceRelays': sourceRelays,
      'firstSeenAt': firstSeenAt,
      'lastSeenAt': lastSeenAt,
      'localOrigin': localOrigin,
      'localCreatedAt': localCreatedAt,
    };
  }

  factory CachedEventRecord.fromJson(Map<String, dynamic> json) {
    return CachedEventRecord(
      eventId: json['eventId'] as String,
      event: _eventFromJson(
        Map<String, dynamic>.from(json['event'] as Map),
      ),
      dTag: json['dTag'] as String?,
      coordinateKey: json['coordinateKey'] as String?,
      isReplaceable: json['isReplaceable'] as bool? ?? false,
      isAddressable: json['isAddressable'] as bool? ?? false,
      isCurrent: json['isCurrent'] as bool? ?? true,
      supersededByEventId: json['supersededByEventId'] as String?,
      expirationAt: json['expirationAt'] as int?,
      deletedByEventId: json['deletedByEventId'] as String?,
      deletedAt: json['deletedAt'] as int?,
      sourceRelays: ((json['sourceRelays'] as List?) ?? [])
          .map((relay) => relay as String)
          .toList(),
      firstSeenAt: json['firstSeenAt'] as int,
      lastSeenAt: json['lastSeenAt'] as int,
      localOrigin: json['localOrigin'] as bool? ?? false,
      localCreatedAt: json['localCreatedAt'] as int?,
    );
  }

  static bool isMoreRecentThan(
    CachedEventRecord candidate,
    CachedEventRecord current,
  ) {
    if (candidate.createdAt != current.createdAt) {
      return candidate.createdAt > current.createdAt;
    }

    return candidate.eventId.compareTo(current.eventId) < 0;
  }

  static List<String> _dedupeRelays(List<String> relays) {
    return relays.toSet().toList()..sort();
  }

  static int? _extractExpirationAt(Nip01Event event) {
    final rawValue = event.getFirstTag('expiration');
    if (rawValue == null) return null;
    return int.tryParse(rawValue);
  }

  static String? _buildCoordinateKey(
    Nip01Event event,
    String? dTag,
    bool isAddressable,
  ) {
    if (!isAddressable) return null;
    return '${event.kind}:${event.pubKey}:${dTag ?? ''}';
  }

  static bool _isAddressableKind(int kind) {
    if (kind == 0 || kind == 3 || kind == 41) {
      return true;
    }

    return (kind >= 10000 && kind <= 19999) || (kind >= 30000 && kind <= 39999);
  }

  static bool _isReplaceableKind(int kind) {
    if (kind == 0 || kind == 3 || kind == 41) {
      return true;
    }

    return (kind >= 10000 && kind <= 19999) || (kind >= 30000 && kind <= 39999);
  }

  static Map<String, dynamic> _eventToJson(Nip01Event event) {
    return {
      'id': event.id,
      'pubkey': event.pubKey,
      'created_at': event.createdAt,
      'kind': event.kind,
      'tags': event.tags,
      'content': event.content,
      'sig': event.sig,
      'sources': event.sources,
      'validSig': event.validSig,
    };
  }

  static Nip01Event _eventFromJson(Map<String, dynamic> json) {
    return Nip01Event(
      id: json['id'] as String?,
      pubKey: json['pubkey'] as String,
      createdAt: json['created_at'] as int,
      kind: json['kind'] as int,
      tags: ((json['tags'] as List?) ?? [])
          .map((tag) => (tag as List).map((item) => item as String).toList())
          .toList(),
      content: json['content'] as String? ?? '',
      sig: json['sig'] as String?,
      validSig: json['validSig'] as bool?,
      sources: ((json['sources'] as List?) ?? [])
          .map((item) => item as String)
          .toList(),
    );
  }
}
