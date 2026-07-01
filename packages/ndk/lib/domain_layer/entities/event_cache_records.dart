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
  final String? serializedEventJson;
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
    this.serializedEventJson,
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
    Object? serializedEventJson = _noChange,
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
      serializedEventJson: identical(serializedEventJson, _noChange)
          ? this.serializedEventJson
          : serializedEventJson as String?,
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
      'serializedEventJson': serializedEventJson,
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
      serializedEventJson: json['serializedEventJson'] as String?,
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

int? _extractExpirationAt(Nip01Event event) {
  final rawValue = event.getFirstTag('expiration');
  if (rawValue == null) return null;
  return int.tryParse(rawValue);
}

String? _buildCoordinateKey(
  Nip01Event event,
  String? dTag,
  bool isAddressable,
) {
  // Coordinate keys identify the conflict domain for replaceable events.
  // For addressable kinds this becomes `kind:pubkey:d-tag`.
  if (!isAddressable) return null;
  return '${event.kind}:${event.pubKey}:${dTag ?? ''}';
}

bool _isAddressableKind(int kind) {
  return EventKindClassification.isAddressableKind(kind);
}

bool _isMoreRecentEventThan(Nip01Event candidate, Nip01Event current) {
  // Replaceable tie-breaker:
  // 1. newer created_at wins
  // 2. stable event id ordering breaks same-timestamp ties deterministically
  if (candidate.createdAt != current.createdAt) {
    return candidate.createdAt > current.createdAt;
  }

  return candidate.id.compareTo(current.id) < 0;
}

/// Lean derived cache metadata for one event.
///
/// This intentionally does not embed the full [Nip01Event]. It persists only
/// the extra state useful for cache maintenance tasks such as eviction
/// planning.
class EventCacheStateRecord {
  final String eventId;
  final String pubKey;
  final int kind;
  final int createdAt;
  final String? coordinateKey;
  final bool isCurrent;
  final int? expirationAt;
  final String? deletedByEventId;

  const EventCacheStateRecord({
    required this.eventId,
    required this.pubKey,
    required this.kind,
    required this.createdAt,
    this.coordinateKey,
    required this.isCurrent,
    this.expirationAt,
    this.deletedByEventId,
  });

  bool get isDeleted => deletedByEventId != null;

  bool isExpiredAt(int timestamp) =>
      expirationAt != null && expirationAt! <= timestamp;

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'pubKey': pubKey,
      'kind': kind,
      'createdAt': createdAt,
      'coordinateKey': coordinateKey,
      'isCurrent': isCurrent,
      'expirationAt': expirationAt,
      'deletedByEventId': deletedByEventId,
    };
  }

  factory EventCacheStateRecord.fromJson(Map<String, dynamic> json) {
    return EventCacheStateRecord(
      eventId: json['eventId'] as String,
      pubKey: json['pubKey'] as String,
      kind: json['kind'] as int,
      createdAt: json['createdAt'] as int,
      coordinateKey: json['coordinateKey'] as String?,
      isCurrent: json['isCurrent'] as bool? ?? true,
      expirationAt: json['expirationAt'] as int?,
      deletedByEventId: json['deletedByEventId'] as String?,
    );
  }

  /// Builds derived state records from raw events using the same visibility
  /// semantics as cache reads and eviction planning.
  static List<EventCacheStateRecord> buildForEvents(
    List<Nip01Event> rawEvents, {
    int? now,
  }) {
    final currentTime = now ?? Nip01Event.secondsSinceEpoch();
    final deletionEvents =
        rawEvents.where((event) => event.kind == 5).toList(growable: false);
    final visibleWinners = <String, Nip01Event>{};

    for (final event in rawEvents) {
      final coordinateKey = _buildCoordinateKey(
        event,
        event.getDtag(),
        _isAddressableKind(event.kind),
      );
      if (coordinateKey == null) {
        continue;
      }
      if (_extractExpirationAt(event) case final expirationAt?
          when expirationAt <= currentTime) {
        continue;
      }
      if (_findDeletingEvent(event, deletionEvents) != null) {
        continue;
      }

      final current = visibleWinners[coordinateKey];
      if (current == null || _isMoreRecentEventThan(event, current)) {
        visibleWinners[coordinateKey] = event;
      }
    }

    final records = <EventCacheStateRecord>[];
    for (final event in rawEvents) {
      final coordinateKey = _buildCoordinateKey(
        event,
        event.getDtag(),
        _isAddressableKind(event.kind),
      );
      final deletingEvent = _findDeletingEvent(event, deletionEvents);
      records.add(
        EventCacheStateRecord(
          eventId: event.id,
          pubKey: event.pubKey,
          kind: event.kind,
          createdAt: event.createdAt,
          coordinateKey: coordinateKey,
          isCurrent: coordinateKey == null ||
              visibleWinners[coordinateKey]?.id == event.id,
          expirationAt: _extractExpirationAt(event),
          deletedByEventId: deletingEvent?.id,
        ),
      );
    }

    return records;
  }

  static Nip01Event? _findDeletingEvent(
    Nip01Event target,
    List<Nip01Event> deletionEvents,
  ) {
    if (target.kind == 5) return null;
    final coordinate = _buildCoordinateKey(
      target,
      target.getDtag(),
      _isAddressableKind(target.kind),
    );

    for (final event in deletionEvents) {
      if (event.pubKey != target.pubKey) continue;
      if (event.getTags('e').contains(target.id.toLowerCase())) {
        return event;
      }
      if (coordinate != null &&
          event.createdAt >= target.createdAt &&
          event.getTags('a').contains(coordinate)) {
        return event;
      }
    }

    return null;
  }
}
