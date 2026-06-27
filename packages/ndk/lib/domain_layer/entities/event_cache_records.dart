import 'nip_01_event.dart';
import '../../shared/nips/nip01/event_kind_classification.dart';

const _noChange = Object();

/// Aggregate delivery state for one event across all of its relay targets.
enum EventDeliveryStatus {
  pending,
  inProgress,
  partiallyDelivered,
  delivered,
  needsAction,
  failed,
}

/// Persisted signing state for one event before relay delivery can proceed.
enum EventSigningState {
  notNeeded,
  pending,
  attempting,
  signed,
  transientFailure,
  needsAction,
  permanentFailure,
}

/// Per-relay delivery state for one `(eventId, relayUrl)` pair.
enum RelayDeliveryState {
  pending,
  attempting,
  acked,
  transientFailure,
  permanentFailure,
  authRequired,
}

/// Why a relay became a delivery target for an event.
enum RelayDeliveryReason {
  authorWrite,
  authorRead,
  replyAuthorRead,
  mentionRead,
  explicit,
  hint,
}

enum DecryptedPayloadScheme {
  nip04,
  nip44,
  giftWrap,
  seal,
  unknown,
}

/// Result of attempting to obtain plaintext for an encrypted payload sidecar.
enum DecryptedPayloadStatus {
  ready,
  transientFailure,
  permanentFailure,
}

/// Persisted relay-specific broadcast target.
///
/// NDK stores one record per `(eventId, relayUrl)` pair instead of keeping a
/// mutable list inside an event record. This makes concurrent updates safer and
/// allows retries, acknowledgements, and failures to be tracked independently.
class RelayDeliveryTarget {
  final String eventId;
  final String relayUrl;
  final RelayDeliveryReason reason;
  final RelayDeliveryState state;
  final int attemptCount;
  final int? lastAttemptAt;
  final int? nextRetryAt;
  final String? lastError;
  final String? lastOkMessage;

  const RelayDeliveryTarget({
    required this.eventId,
    required this.relayUrl,
    required this.reason,
    this.state = RelayDeliveryState.pending,
    this.attemptCount = 0,
    this.lastAttemptAt,
    this.nextRetryAt,
    this.lastError,
    this.lastOkMessage,
  });

  /// Stable primary key used by cache backends.
  String get key => '$eventId|$relayUrl';

  RelayDeliveryTarget copyWith({
    String? eventId,
    String? relayUrl,
    RelayDeliveryReason? reason,
    RelayDeliveryState? state,
    int? attemptCount,
    Object? lastAttemptAt = _noChange,
    Object? nextRetryAt = _noChange,
    Object? lastError = _noChange,
    Object? lastOkMessage = _noChange,
  }) {
    return RelayDeliveryTarget(
      eventId: eventId ?? this.eventId,
      relayUrl: relayUrl ?? this.relayUrl,
      reason: reason ?? this.reason,
      state: state ?? this.state,
      attemptCount: attemptCount ?? this.attemptCount,
      lastAttemptAt: identical(lastAttemptAt, _noChange)
          ? this.lastAttemptAt
          : lastAttemptAt as int?,
      nextRetryAt: identical(nextRetryAt, _noChange)
          ? this.nextRetryAt
          : nextRetryAt as int?,
      lastError: identical(lastError, _noChange)
          ? this.lastError
          : lastError as String?,
      lastOkMessage: identical(lastOkMessage, _noChange)
          ? this.lastOkMessage
          : lastOkMessage as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
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
      eventId: json['eventId'] as String,
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

/// Persisted aggregate delivery record for one event.
///
/// This record answers "what is the overall delivery state of this event?" and
/// survives process restarts. Detailed per-relay information lives separately in
/// [RelayDeliveryTarget].
class EventDeliveryRecord {
  final String eventId;
  final EventDeliveryStatus status;
  final EventSigningState signingState;
  final int createdAt;
  final int updatedAt;
  final int? signedAt;
  final int? completedAt;
  final bool requiresInteractiveSigning;
  final int signAttemptCount;
  final int? lastSignAttemptAt;
  final int? nextSignRetryAt;
  final String? lastSignError;

  const EventDeliveryRecord({
    required this.eventId,
    this.status = EventDeliveryStatus.pending,
    this.signingState = EventSigningState.notNeeded,
    required this.createdAt,
    required this.updatedAt,
    this.signedAt,
    this.completedAt,
    this.requiresInteractiveSigning = false,
    this.signAttemptCount = 0,
    this.lastSignAttemptAt,
    this.nextSignRetryAt,
    this.lastSignError,
  });

  /// True once all known targets have been acknowledged.
  bool get isComplete => status == EventDeliveryStatus.delivered;

  /// True once the event is signed or never required a remote signing phase.
  bool get isSigned =>
      signingState == EventSigningState.signed ||
      (!requiresInteractiveSigning && signedAt == null) ||
      signedAt != null;

  EventDeliveryRecord copyWith({
    String? eventId,
    EventDeliveryStatus? status,
    EventSigningState? signingState,
    int? createdAt,
    int? updatedAt,
    Object? signedAt = _noChange,
    Object? completedAt = _noChange,
    bool? requiresInteractiveSigning,
    int? signAttemptCount,
    Object? lastSignAttemptAt = _noChange,
    Object? nextSignRetryAt = _noChange,
    Object? lastSignError = _noChange,
  }) {
    return EventDeliveryRecord(
      eventId: eventId ?? this.eventId,
      status: status ?? this.status,
      signingState: signingState ?? this.signingState,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      signedAt:
          identical(signedAt, _noChange) ? this.signedAt : signedAt as int?,
      completedAt: identical(completedAt, _noChange)
          ? this.completedAt
          : completedAt as int?,
      requiresInteractiveSigning:
          requiresInteractiveSigning ?? this.requiresInteractiveSigning,
      signAttemptCount: signAttemptCount ?? this.signAttemptCount,
      lastSignAttemptAt: identical(lastSignAttemptAt, _noChange)
          ? this.lastSignAttemptAt
          : lastSignAttemptAt as int?,
      nextSignRetryAt: identical(nextSignRetryAt, _noChange)
          ? this.nextSignRetryAt
          : nextSignRetryAt as int?,
      lastSignError: identical(lastSignError, _noChange)
          ? this.lastSignError
          : lastSignError as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'status': status.name,
      'signingState': signingState.name,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'signedAt': signedAt,
      'completedAt': completedAt,
      'requiresInteractiveSigning': requiresInteractiveSigning,
      'signAttemptCount': signAttemptCount,
      'lastSignAttemptAt': lastSignAttemptAt,
      'nextSignRetryAt': nextSignRetryAt,
      'lastSignError': lastSignError,
    };
  }

  factory EventDeliveryRecord.fromJson(Map<String, dynamic> json) {
    final requiresInteractiveSigning =
        json['requiresInteractiveSigning'] as bool? ??
            json['requiresNetworkSigner'] as bool? ??
            false;
    return EventDeliveryRecord(
      eventId: json['eventId'] as String,
      status: EventDeliveryStatus.values.byName(json['status'] as String),
      signingState: json['signingState'] != null
          ? EventSigningState.values.byName(json['signingState'] as String)
          : (requiresInteractiveSigning
              ? EventSigningState.pending
              : EventSigningState.notNeeded),
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
      signedAt: json['signedAt'] as int?,
      completedAt: json['completedAt'] as int?,
      requiresInteractiveSigning: requiresInteractiveSigning,
      signAttemptCount: json['signAttemptCount'] as int? ?? 0,
      lastSignAttemptAt: json['lastSignAttemptAt'] as int?,
      nextSignRetryAt: json['nextSignRetryAt'] as int?,
      lastSignError: json['lastSignError'] as String?,
    );
  }
}

/// Sidecar cache record for decrypted event plaintext.
///
/// NDK intentionally does not mutate the original encrypted [Nip01Event] with
/// decrypted content. Instead it stores a separate plaintext sidecar keyed by
/// `(eventId, viewerPubKey)`.
class DecryptedEventPayloadRecord {
  final String eventId;
  final String viewerPubKey;
  final DecryptedPayloadScheme scheme;
  final DecryptedPayloadStatus status;
  final String? plaintextContent;
  final int createdAt;
  final int updatedAt;
  final int? decryptedAt;
  final String? failureReason;
  final String? sourceEventPubKey;
  final int? sourceEventKind;

  const DecryptedEventPayloadRecord({
    required this.eventId,
    required this.viewerPubKey,
    this.scheme = DecryptedPayloadScheme.unknown,
    this.status = DecryptedPayloadStatus.ready,
    this.plaintextContent,
    required this.createdAt,
    required this.updatedAt,
    this.decryptedAt,
    this.failureReason,
    this.sourceEventPubKey,
    this.sourceEventKind,
  });

  /// Stable primary key used by cache backends.
  String get key => '$eventId|$viewerPubKey';

  DecryptedEventPayloadRecord copyWith({
    String? eventId,
    String? viewerPubKey,
    DecryptedPayloadScheme? scheme,
    DecryptedPayloadStatus? status,
    Object? plaintextContent = _noChange,
    int? createdAt,
    int? updatedAt,
    Object? decryptedAt = _noChange,
    Object? failureReason = _noChange,
    Object? sourceEventPubKey = _noChange,
    Object? sourceEventKind = _noChange,
  }) {
    return DecryptedEventPayloadRecord(
      eventId: eventId ?? this.eventId,
      viewerPubKey: viewerPubKey ?? this.viewerPubKey,
      scheme: scheme ?? this.scheme,
      status: status ?? this.status,
      plaintextContent: identical(plaintextContent, _noChange)
          ? this.plaintextContent
          : plaintextContent as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      decryptedAt: identical(decryptedAt, _noChange)
          ? this.decryptedAt
          : decryptedAt as int?,
      failureReason: identical(failureReason, _noChange)
          ? this.failureReason
          : failureReason as String?,
      sourceEventPubKey: identical(sourceEventPubKey, _noChange)
          ? this.sourceEventPubKey
          : sourceEventPubKey as String?,
      sourceEventKind: identical(sourceEventKind, _noChange)
          ? this.sourceEventKind
          : sourceEventKind as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'viewerPubKey': viewerPubKey,
      'scheme': scheme.name,
      'status': status.name,
      'plaintextContent': plaintextContent,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'decryptedAt': decryptedAt,
      'failureReason': failureReason,
      'sourceEventPubKey': sourceEventPubKey,
      'sourceEventKind': sourceEventKind,
    };
  }

  factory DecryptedEventPayloadRecord.fromJson(Map<String, dynamic> json) {
    return DecryptedEventPayloadRecord(
      eventId: json['eventId'] as String,
      viewerPubKey: json['viewerPubKey'] as String,
      scheme: json['scheme'] != null
          ? DecryptedPayloadScheme.values.byName(json['scheme'] as String)
          : DecryptedPayloadScheme.unknown,
      status: json['status'] != null
          ? DecryptedPayloadStatus.values.byName(json['status'] as String)
          : DecryptedPayloadStatus.ready,
      plaintextContent: json['plaintextContent'] as String?,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
      decryptedAt: json['decryptedAt'] as int?,
      failureReason: json['failureReason'] as String?,
      sourceEventPubKey: json['sourceEventPubKey'] as String?,
      sourceEventKind: json['sourceEventKind'] as int?,
    );
  }
}

/// Normalized cache record describing one stored event and its derived state.
///
/// This model exists to make visibility and eviction decisions efficient across
/// backends. Some fields duplicate data derivable from [event] on purpose so
/// backends can index and query without reparsing tags every time.
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

  /// Convenience accessor for [event.pubKey].
  String get pubKey => event.pubKey;

  /// Convenience accessor for [event.kind].
  int get kind => event.kind;

  /// Convenience accessor for [event.createdAt].
  int get createdAt => event.createdAt;

  /// True if this event is currently tombstoned by a matching author delete.
  bool get isDeleted => deletedByEventId != null;

  /// Returns whether the event should be considered expired at [timestamp].
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
    // Source relays are normalized onto the cached record when the event is
    // materialized from event data plus optional explicit provenance input.
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
    // Replaceable tie-breaker:
    // 1. newer created_at wins
    // 2. stable event id ordering breaks same-timestamp ties deterministically
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
    // Coordinate keys identify the conflict domain for replaceable events.
    // For addressable kinds this becomes `kind:pubkey:d-tag`.
    if (!isAddressable) return null;
    return '${event.kind}:${event.pubKey}:${dTag ?? ''}';
  }

  static bool _isAddressableKind(int kind) {
    return EventKindClassification.isAddressableKind(kind);
  }

  static bool _isReplaceableKind(int kind) {
    return EventKindClassification.isReplaceableKind(kind);
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
