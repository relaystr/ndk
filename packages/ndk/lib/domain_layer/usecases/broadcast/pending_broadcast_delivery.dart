import 'dart:async';

import '../../entities/broadcast_state.dart';
import '../../entities/event_cache_records.dart';
import '../../entities/nip_01_event.dart';
import '../../entities/pending_signer_request.dart';
import '../../entities/signer_request_cancelled_exception.dart';
import '../../entities/signer_request_rejected_exception.dart';
import '../../repositories/cache_manager.dart';
import '../../repositories/event_signer.dart';
import '../accounts/accounts.dart';
import '../../../shared/logger/logger.dart';
import '../../../shared/nips/nip01/event_kind_classification.dart';
import 'broadcast_sender.dart';
import 'delivery_policy.dart';

/// Background manager for persisted broadcast delivery.
///
/// This usecase persists relay-specific delivery targets, retries due targets,
/// and converges replaceable delivery so only the latest visible version keeps
/// being retried.
///
/// Conceptually:
/// - [Broadcast] decides that an event should be sent
/// - [PendingBroadcastDelivery] remembers where it still needs to go and when
///   it should be retried
class PendingBroadcastDelivery {
  static const Duration defaultRetryInterval = Duration(seconds: 15);
  static const Duration defaultSignAttemptTimeout = Duration(seconds: 15);
  final CacheManager _cacheManager;
  final BroadcastSender _sender;
  final Accounts _accounts;
  final Duration _signAttemptTimeout;
  final Set<String> _flushInProgress = {};
  final Map<String, int> _activeSignAttemptIds = {};
  final Map<String, int> _latestSignAttemptIds = {};
  Iterable<String> Function()? _connectedRelayUrlsProvider;
  Timer? _retryTimer;

  PendingBroadcastDelivery({
    required CacheManager cacheManager,
    required BroadcastSender broadcastSender,
    required Accounts accounts,
    Duration signAttemptTimeout = defaultSignAttemptTimeout,
  })  : _cacheManager = cacheManager,
        _sender = broadcastSender,
        _accounts = accounts,
        _signAttemptTimeout = signAttemptTimeout;

  /// Starts periodic due-retry processing.
  ///
  /// The callbacks are injected so this class can stay storage-focused and not
  /// depend directly on relay manager internals.
  void startPeriodicRetry({
    required Iterable<String> Function() connectedRelayUrls,
    required Future<bool> Function(String relayUrl) reconnectRelay,
    Duration retryInterval = defaultRetryInterval,
  }) {
    _connectedRelayUrlsProvider = connectedRelayUrls;
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(
      retryInterval,
      (_) => unawaited(
        retryDueDeliveries(
          connectedRelayUrls: connectedRelayUrls,
          reconnectRelay: reconnectRelay,
        ),
      ),
    );
    unawaited(
      retryDueDeliveries(
        connectedRelayUrls: connectedRelayUrls,
        reconnectRelay: reconnectRelay,
      ),
    );
  }

  Future<void> stop() async {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  Future<void> retryDueDeliveries({
    required Iterable<String> Function() connectedRelayUrls,
    required Future<bool> Function(String relayUrl) reconnectRelay,
  }) async {
    await _retryDueSigning();

    final connectedRelayUrlSet = connectedRelayUrls().toSet();
    final dueRelayUrlSet = await _relayUrlsWithDuePendingTargets();
    final relayUrls = dueRelayUrlSet.toList()..sort();

    for (final relayUrl in relayUrls) {
      if (connectedRelayUrlSet.contains(relayUrl)) {
        await flushForRelay(
          relayUrl,
          onlyDue: true,
        );
        continue;
      }

      final connected = await reconnectRelay(relayUrl);
      if (!connected) {
        continue;
      }

      await flushForRelay(
        relayUrl,
        onlyDue: true,
      );
    }
  }

  /// Trigger immediate processing of due signing and delivery work.
  ///
  /// Useful as an accelerator when the host app detects network restoration,
  /// foreground resume, or other conditions that may unblock pending signer
  /// approval/completion paths.
  Future<void> retryDueNow({
    required Iterable<String> Function() connectedRelayUrls,
    required Future<bool> Function(String relayUrl) reconnectRelay,
  }) async {
    await retryDueDeliveries(
      connectedRelayUrls: connectedRelayUrls,
      reconnectRelay: reconnectRelay,
    );
  }

  /// Retry unsigned interactive-signing work associated with a signer
  /// transport relay that just became reachable.
  Future<void> retryInteractiveSigningForTransportRelay(String relayUrl) async {
    final records = await _cacheManager.loadEventDeliveryRecords();
    records.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    for (final record in records) {
      if (!record.requiresInteractiveSigning) {
        continue;
      }
      if (record.signingState == EventSigningState.permanentFailure ||
          record.signingState == EventSigningState.needsAction ||
          record.signingState == EventSigningState.signed ||
          record.signedAt != null) {
        continue;
      }

      final event = await _cacheManager.loadEvent(record.eventId);
      if (event == null) {
        await _discardEventDelivery(record.eventId);
        continue;
      }

      final signer = _resolveSignerForEvent(event);
      if (signer == null ||
          !signer.requiresSignerNetwork ||
          !signer.signerTransportRelayUrls.contains(relayUrl)) {
        continue;
      }

      await _ensureEventSigned(record, event: event);
    }
  }

  Future<void> enqueueSpecificRelayBroadcast({
    required Nip01Event event,
    required Iterable<String> relayUrls,
    required bool requiresInteractiveSigning,
  }) async {
    // One durable aggregate record plus one durable target per relay gives NDK
    // enough state to recover delivery after restart without mutating a shared
    // in-memory list.
    final relayUrlList = relayUrls.toSet().toList()..sort();
    Logger.log.d(() => 'enqueue pending delivery ${event.id} -> $relayUrlList');
    final existing = await _cacheManager.loadEventDeliveryRecord(event.id);
    final now = Nip01Event.secondsSinceEpoch();

    await _cacheManager.saveEventDeliveryRecord(
      EventDeliveryRecord(
        eventId: event.id,
        status: existing?.status ?? EventDeliveryStatus.pending,
        signingState: existing?.signingState ??
            (requiresInteractiveSigning
                ? EventSigningState.pending
                : EventSigningState.notNeeded),
        createdAt: existing?.createdAt ?? event.createdAt,
        updatedAt: now,
        signedAt: existing?.signedAt ?? (event.sig != null ? now : null),
        completedAt: existing?.completedAt,
        requiresInteractiveSigning: requiresInteractiveSigning,
        signAttemptCount: existing?.signAttemptCount ?? 0,
        lastSignAttemptAt: existing?.lastSignAttemptAt,
        nextSignRetryAt: existing?.nextSignRetryAt,
        lastSignError: existing?.lastSignError,
      ),
    );

    final existingTargets =
        await _cacheManager.loadRelayDeliveryTargets(eventId: event.id);
    final existingByRelay = {
      for (final target in existingTargets) target.relayUrl: target,
    };

    await _cacheManager.saveRelayDeliveryTargets(
      relayUrlList.map((relayUrl) {
        final existingTarget = existingByRelay[relayUrl];
        return existingTarget ??
            RelayDeliveryTarget(
              eventId: event.id,
              relayUrl: relayUrl,
              reason: RelayDeliveryReason.explicit,
            );
      }).toList(),
    );
  }

  Future<void> persistSpecificRelayBroadcastResult(
    Nip01Event event,
    List<RelayBroadcastResponse> responses,
  ) async {
    Logger.log.d(() =>
        'persist broadcast result ${event.id} -> ${responses.map((r) => r.relayUrl).toList()}');

    final existing = await _cacheManager.loadEventDeliveryRecord(event.id);
    if (existing == null) {
      return;
    }

    final existingTargets =
        await _cacheManager.loadRelayDeliveryTargets(eventId: event.id);
    final targetsByRelay = {
      for (final target in existingTargets) target.relayUrl: target,
    };

    final updatedTargets = <RelayDeliveryTarget>[];
    final policy = DeliveryPolicy.forEvent(event);
    for (final response in responses) {
      final current = targetsByRelay[response.relayUrl];
      if (current == null) {
        continue;
      }

      final isAcked = response.okReceived && response.broadcastSuccessful;
      final attemptTimestamp = Nip01Event.secondsSinceEpoch();
      final nextState = policy.resolveNextState(response);
      final nextRetryAt = policy.shouldRetryState(nextState)
          ? attemptTimestamp +
              policy
                  .retryDelayFor(
                    state: nextState,
                    attemptCount: current.attemptCount + 1,
                  )
                  .inSeconds
          : null;

      updatedTargets.add(
        current.copyWith(
          state: nextState,
          attemptCount: current.attemptCount + 1,
          lastAttemptAt: attemptTimestamp,
          nextRetryAt: nextRetryAt,
          lastOkMessage: isAcked ? response.msg : current.lastOkMessage,
          lastError: isAcked ? null : response.msg,
        ),
      );
    }

    if (updatedTargets.isNotEmpty) {
      await _cacheManager.saveRelayDeliveryTargets(updatedTargets);
    }

    final allTargets =
        await _cacheManager.loadRelayDeliveryTargets(eventId: event.id);
    final deliveryStatus = _resolveDeliveryStatus(existing, allTargets);

    await _cacheManager.saveEventDeliveryRecord(
      existing.copyWith(
        status: deliveryStatus,
        updatedAt: Nip01Event.secondsSinceEpoch(),
        completedAt: deliveryStatus == EventDeliveryStatus.delivered
            ? Nip01Event.secondsSinceEpoch()
            : null,
      ),
    );
  }

  Future<void> flushForRelay(
    String relayUrl, {
    bool onlyDue = false,
  }) async {
    // Per-relay flush serialization avoids two concurrent retry paths trying to
    // re-send the same relay targets at once.
    if (!_flushInProgress.add(relayUrl)) {
      return;
    }

    try {
      final persistedTargets = await _cacheManager.loadRelayDeliveryTargets(
        relayUrl: relayUrl,
        excludeAcked: true,
      );
      final now = Nip01Event.secondsSinceEpoch();
      final targets = persistedTargets.where((target) {
        if (target.state == RelayDeliveryState.permanentFailure) {
          return false;
        }

        if (!onlyDue) {
          return true;
        }

        return target.nextRetryAt == null || target.nextRetryAt! <= now;
      }).toList();
      Logger.log.d(() =>
          'flush pending delivery for $relayUrl${onlyDue ? " (due only)" : ""} -> ${targets.map((t) => t.eventId).toList()}');

      for (final target in targets) {
        if (_sender.isEventInFlight(target.eventId)) {
          continue;
        }

        final deliveryRecord =
            await _cacheManager.loadEventDeliveryRecord(target.eventId);
        if (deliveryRecord == null) {
          await _cacheManager.removeRelayDeliveryTarget(
            eventId: target.eventId,
            relayUrl: relayUrl,
          );
          continue;
        }

        final loadedEvent = await _cacheManager.loadEvent(target.eventId);
        if (loadedEvent == null) {
          await _cacheManager.removeRelayDeliveryTarget(
            eventId: target.eventId,
            relayUrl: relayUrl,
          );
          continue;
        }
        var event = loadedEvent;

        if (await _isObsoleteReplaceableOrAddressableEvent(event)) {
          Logger.log.d(
              () => 'drop obsolete pending delivery ${event.id} for $relayUrl');
          await _discardEventDelivery(event.id);
          continue;
        }

        if (deliveryRecord.requiresInteractiveSigning && event.sig == null) {
          final signed = await _ensureEventSigned(
            deliveryRecord,
            event: event,
          );
          if (!signed) {
            continue;
          }
          final signedEvent = await _cacheManager.loadEvent(target.eventId);
          if (signedEvent == null || signedEvent.sig == null) {
            continue;
          }
          event = signedEvent;
        }

        final policy = DeliveryPolicy.forEvent(event);
        if (!policy.shouldRetryState(target.state)) {
          continue;
        }

        if (target.state == RelayDeliveryState.attempting &&
            policy.retainsOnlyLatest) {
          Logger.log.d(() =>
              'skip retry for in-flight replaceable delivery ${event.id} on $relayUrl');
          continue;
        }

        await _sender.broadcast(
          nostrEvent: event,
          specificRelays: [relayUrl],
        ).broadcastDoneFuture;
      }
    } finally {
      _flushInProgress.remove(relayUrl);
    }
  }

  Future<bool> _isObsoleteReplaceableOrAddressableEvent(
      Nip01Event event) async {
    // Replaceable/addressable retries should follow the currently visible cache
    // winner, not historical offline versions that were later superseded.
    final policy = DeliveryPolicy.forEvent(event);
    if (!policy.retainsOnlyLatest) {
      return false;
    }

    final visibleEvents = await _cacheManager.loadEvents(
      pubKeys: [event.pubKey],
      kinds: [event.kind],
      tags: _isAddressableKind(event.kind) && event.getDtag() != null
          ? {
              'd': [event.getDtag()!],
            }
          : null,
      limit: 1,
    );

    if (visibleEvents.isEmpty) {
      return true;
    }

    return visibleEvents.single.id != event.id;
  }

  Future<void> _discardEventDelivery(String eventId) async {
    await _cacheManager.removeRelayDeliveryTargets(eventId);
    await _cacheManager.removeEventDeliveryRecord(eventId);
  }

  Future<Set<String>> _relayUrlsWithDuePendingTargets() async {
    final now = Nip01Event.secondsSinceEpoch();
    final targets = await _cacheManager.loadRelayDeliveryTargets(
      excludeAcked: true,
    );

    final relayUrls = <String>{};
    for (final target in targets) {
      if (target.state == RelayDeliveryState.permanentFailure) {
        continue;
      }
      if (target.nextRetryAt != null && target.nextRetryAt! > now) {
        continue;
      }
      relayUrls.add(target.relayUrl);
    }

    return relayUrls;
  }

  Future<void> _retryDueSigning() async {
    final now = Nip01Event.secondsSinceEpoch();
    final records = await _cacheManager.loadEventDeliveryRecords();
    records.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    for (final record in records) {
      if (!record.requiresInteractiveSigning) {
        continue;
      }
      if (record.signingState == EventSigningState.permanentFailure ||
          record.signingState == EventSigningState.needsAction) {
        continue;
      }
      if (record.signedAt != null &&
          record.signingState == EventSigningState.signed) {
        continue;
      }
      if (record.nextSignRetryAt != null && record.nextSignRetryAt! > now) {
        continue;
      }

      final event = await _cacheManager.loadEvent(record.eventId);
      if (event == null) {
        await _discardEventDelivery(record.eventId);
        continue;
      }

      if (await _isObsoleteReplaceableOrAddressableEvent(event)) {
        await _discardEventDelivery(record.eventId);
        continue;
      }

      await _ensureEventSigned(record, event: event);
    }
  }

  Future<bool> _ensureEventSigned(
    EventDeliveryRecord record, {
    required Nip01Event event,
  }) async {
    if (!record.requiresInteractiveSigning) {
      return true;
    }
    if (event.sig != null) {
      await _markEventSigned(record);
      return true;
    }

    final signer = _resolveSignerForEvent(event);
    if (signer != null &&
        signer.requiresSignerNetwork &&
        !_isSignerTransportReachable(signer)) {
      return false;
    }

    if (_activeSignAttemptIds.containsKey(event.id)) {
      return false;
    }
    final now = Nip01Event.secondsSinceEpoch();
    final attemptId = (_latestSignAttemptIds[event.id] ?? 0) + 1;
    _latestSignAttemptIds[event.id] = attemptId;
    _activeSignAttemptIds[event.id] = attemptId;
    if (signer == null ||
        !signer.requiresInteractiveSigning ||
        !signer.canSign()) {
      await _saveSigningOutcome(
        record.copyWith(
          signingState: EventSigningState.needsAction,
          updatedAt: now,
          lastSignError:
              'No matching available remote signer account for ${event.pubKey}',
          nextSignRetryAt: null,
        ),
      );
      _activeSignAttemptIds.remove(event.id);
      return false;
    }

    final attemptingRecord = record.copyWith(
      signingState: EventSigningState.attempting,
      updatedAt: now,
      signAttemptCount: record.signAttemptCount + 1,
      lastSignAttemptAt: now,
      lastSignError: null,
    );
    await _saveSigningOutcome(attemptingRecord);

    final signFuture = signer.sign(event);
    try {
      final signedEvent = await signFuture.timeout(_signAttemptTimeout);
      await _handleSignSuccess(
        attemptId: attemptId,
        record: attemptingRecord,
        event: event,
        signedEvent: signedEvent,
      );
      _clearActiveSignAttempt(event.id, attemptId: attemptId);
      return true;
    } on TimeoutException catch (_) {
      _clearActiveSignAttempt(event.id, attemptId: attemptId);
      _trackLateSigningCompletion(
        attemptId: attemptId,
        event: event,
        record: attemptingRecord,
        future: signFuture,
      );

      final waitingForApproval = _hasPendingSignerRequest(signer, event.id);
      await _saveSigningOutcome(
        attemptingRecord.copyWith(
          signingState: waitingForApproval
              ? EventSigningState.needsAction
              : EventSigningState.transientFailure,
          updatedAt: Nip01Event.secondsSinceEpoch(),
          nextSignRetryAt: waitingForApproval
              ? null
              : Nip01Event.secondsSinceEpoch() +
                  _signRetryDelayFor(
                    attemptCount: attemptingRecord.signAttemptCount,
                    requiresSignerNetwork: signer.requiresSignerNetwork,
                  ).inSeconds,
          lastSignError: waitingForApproval
              ? 'Waiting for signer approval'
              : 'Timed out waiting for signer',
        ),
      );
      return false;
    } catch (error, stackTrace) {
      await _handleSignFailure(
        attemptId: attemptId,
        record: attemptingRecord,
        event: event,
        signer: signer,
        error: error,
        stackTrace: stackTrace,
      );
      _clearActiveSignAttempt(event.id, attemptId: attemptId);
      return false;
    }
  }

  void _trackLateSigningCompletion({
    required int attemptId,
    required Nip01Event event,
    required EventDeliveryRecord record,
    required Future<Nip01Event> future,
  }) {
    unawaited(
      future.then((signedEvent) async {
        await _handleSignSuccess(
          attemptId: attemptId,
          record: record,
          event: event,
          signedEvent: signedEvent,
        );
      }, onError: (Object error, StackTrace stackTrace) async {
        await _handleSignFailure(
          attemptId: attemptId,
          record: record,
          event: event,
          signer: _resolveSignerForEvent(event),
          error: error,
          stackTrace: stackTrace,
        );
      }).whenComplete(() {
        _clearActiveSignAttempt(event.id, attemptId: attemptId);
      }),
    );
  }

  Future<void> _handleSignSuccess({
    required int attemptId,
    required EventDeliveryRecord record,
    required Nip01Event event,
    required Nip01Event signedEvent,
  }) async {
    if (!_isLatestSignAttempt(event.id, attemptId)) {
      return;
    }
    if (await _isObsoleteReplaceableOrAddressableEvent(event)) {
      await _discardEventDelivery(event.id);
      return;
    }

    final now = Nip01Event.secondsSinceEpoch();
    await _cacheManager.saveEvent(signedEvent);
    await _saveSigningOutcome(
      record.copyWith(
        signingState: EventSigningState.signed,
        updatedAt: now,
        signedAt: now,
        nextSignRetryAt: null,
        lastSignError: null,
      ),
    );

    await _flushConnectedTargetsForEvent(event.id);
  }

  Future<void> _handleSignFailure({
    required int attemptId,
    required EventDeliveryRecord record,
    required Nip01Event event,
    required EventSigner? signer,
    required Object error,
    required StackTrace stackTrace,
  }) async {
    if (!_isLatestSignAttempt(event.id, attemptId)) {
      return;
    }
    Logger.log.w(
      () => 'remote signing failed for ${event.id}',
      error: error,
      stackTrace: stackTrace,
    );

    final outcome = _classifySigningFailure(error);
    final now = Nip01Event.secondsSinceEpoch();
    final nextRetryAt = outcome == EventSigningState.transientFailure
        ? now +
            _signRetryDelayFor(
              attemptCount: record.signAttemptCount,
              requiresSignerNetwork: signer?.requiresSignerNetwork ?? false,
            ).inSeconds
        : null;

    await _saveSigningOutcome(
      record.copyWith(
        signingState: outcome,
        updatedAt: now,
        nextSignRetryAt: nextRetryAt,
        lastSignError: error.toString(),
      ),
    );
  }

  bool _isLatestSignAttempt(String eventId, int attemptId) {
    return _latestSignAttemptIds[eventId] == attemptId;
  }

  void _clearActiveSignAttempt(String eventId, {required int attemptId}) {
    if (_activeSignAttemptIds[eventId] == attemptId) {
      _activeSignAttemptIds.remove(eventId);
    }
  }

  EventSigningState _classifySigningFailure(Object error) {
    if (error is SignerRequestCancelledException ||
        error is SignerRequestRejectedException) {
      return EventSigningState.needsAction;
    }

    final normalized = error.toString().toLowerCase();
    if (normalized.contains('not available') ||
        normalized.contains('not installed') ||
        normalized.contains('requires action') ||
        normalized.contains('approval') ||
        normalized.contains('permission') ||
        normalized.contains('use getpublickeyasync') ||
        normalized.contains('cannot sign') ||
        normalized.contains('unknown account')) {
      return EventSigningState.needsAction;
    }

    if (normalized.contains('unsupported') ||
        normalized.contains('invalid event') ||
        normalized.contains('bad signature')) {
      return EventSigningState.permanentFailure;
    }

    return EventSigningState.transientFailure;
  }

  Duration _signRetryDelayFor({
    required int attemptCount,
    required bool requiresSignerNetwork,
  }) {
    final retrySeconds = requiresSignerNetwork
        ? switch (attemptCount) {
            <= 1 => 15,
            2 => 60,
            3 => 300,
            4 => 900,
            _ => 1800,
          }
        : switch (attemptCount) {
            <= 1 => 5,
            2 => 15,
            3 => 60,
            4 => 300,
            _ => 900,
          };
    return Duration(seconds: retrySeconds);
  }

  bool _hasPendingSignerRequest(EventSigner signer, String eventId) {
    return signer.pendingRequests.any(
      (request) =>
          request.method == SignerMethod.signEvent &&
          request.event?.id == eventId,
    );
  }

  EventSigner? _resolveSignerForEvent(Nip01Event event) {
    final account = _accounts.accounts[event.pubKey];
    return account?.signer;
  }

  bool _isSignerTransportReachable(EventSigner signer) {
    final transportRelayUrls = signer.signerTransportRelayUrls.toSet();
    if (transportRelayUrls.isEmpty) {
      return true;
    }

    final connectedRelayUrls =
        _connectedRelayUrlsProvider?.call().toSet() ?? {};
    return transportRelayUrls.any(connectedRelayUrls.contains);
  }

  Future<void> _flushConnectedTargetsForEvent(String eventId) async {
    final connectedRelayUrls = _connectedRelayUrlsProvider?.call().toSet();
    if (connectedRelayUrls == null || connectedRelayUrls.isEmpty) {
      return;
    }

    final targets =
        await _cacheManager.loadRelayDeliveryTargets(eventId: eventId);
    final targetRelayUrls = targets
        .where((target) => connectedRelayUrls.contains(target.relayUrl))
        .map((target) => target.relayUrl)
        .toSet()
        .toList()
      ..sort();

    for (final relayUrl in targetRelayUrls) {
      await flushForRelay(relayUrl);
    }
  }

  Future<void> _markEventSigned(EventDeliveryRecord record) async {
    final now = Nip01Event.secondsSinceEpoch();
    await _saveSigningOutcome(
      record.copyWith(
        signingState: EventSigningState.signed,
        updatedAt: now,
        signedAt: now,
        nextSignRetryAt: null,
        lastSignError: null,
      ),
    );
  }

  Future<void> _saveSigningOutcome(EventDeliveryRecord record) async {
    final targets =
        await _cacheManager.loadRelayDeliveryTargets(eventId: record.eventId);
    final resolvedStatus = _resolveDeliveryStatus(record, targets);
    final now = Nip01Event.secondsSinceEpoch();
    await _cacheManager.saveEventDeliveryRecord(
      record.copyWith(
        status: resolvedStatus,
        completedAt: resolvedStatus == EventDeliveryStatus.delivered
            ? (record.completedAt ?? now)
            : null,
      ),
    );
  }

  bool _isAddressableKind(int kind) {
    return EventKindClassification.isAddressableKind(kind);
  }

  EventDeliveryStatus _resolveDeliveryStatus(
    EventDeliveryRecord record,
    List<RelayDeliveryTarget> targets,
  ) {
    if (record.requiresInteractiveSigning &&
        record.signingState != EventSigningState.signed &&
        record.signedAt == null) {
      return switch (record.signingState) {
        EventSigningState.needsAction => EventDeliveryStatus.needsAction,
        EventSigningState.permanentFailure => EventDeliveryStatus.failed,
        EventSigningState.pending => EventDeliveryStatus.pending,
        EventSigningState.notNeeded => EventDeliveryStatus.pending,
        EventSigningState.attempting ||
        EventSigningState.transientFailure =>
          EventDeliveryStatus.inProgress,
        EventSigningState.signed => EventDeliveryStatus.inProgress,
      };
    }

    if (targets.isEmpty) {
      return EventDeliveryStatus.pending;
    }

    final allAcked = targets.every((t) => t.state == RelayDeliveryState.acked);
    if (allAcked) {
      return EventDeliveryStatus.delivered;
    }

    if (targets.any((t) => t.state == RelayDeliveryState.authRequired)) {
      return EventDeliveryStatus.needsAction;
    }

    final ackedCount =
        targets.where((t) => t.state == RelayDeliveryState.acked).length;
    final permanentFailureCount = targets
        .where((t) => t.state == RelayDeliveryState.permanentFailure)
        .length;

    final allTerminal = targets.every(
      (t) =>
          t.state == RelayDeliveryState.acked ||
          t.state == RelayDeliveryState.permanentFailure,
    );
    if (allTerminal) {
      return ackedCount > 0
          ? EventDeliveryStatus.partiallyDelivered
          : EventDeliveryStatus.failed;
    }

    if (ackedCount > 0 || permanentFailureCount > 0) {
      return EventDeliveryStatus.partiallyDelivered;
    }

    return EventDeliveryStatus.inProgress;
  }
}
