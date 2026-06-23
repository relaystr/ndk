import 'dart:async';

import '../../entities/broadcast_state.dart';
import '../../entities/event_cache_records.dart';
import '../../entities/nip_01_event.dart';
import '../../repositories/cache_manager.dart';
import '../../../shared/logger/logger.dart';
import '../../../shared/nips/nip01/event_kind_classification.dart';
import 'broadcast.dart';
import 'delivery_policy.dart';

class PendingBroadcastDelivery {
  static const Duration defaultRetryInterval = Duration(seconds: 15);
  final CacheManager _cacheManager;
  final Broadcast _broadcast;
  final Set<String> _flushInProgress = {};
  Timer? _retryTimer;

  PendingBroadcastDelivery({
    required CacheManager cacheManager,
    required Broadcast broadcast,
  })  : _cacheManager = cacheManager,
        _broadcast = broadcast;

  void startPeriodicRetry({
    required Iterable<String> Function() connectedRelayUrls,
    required Future<bool> Function(String relayUrl) reconnectRelay,
    Duration retryInterval = defaultRetryInterval,
  }) {
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

  Future<void> enqueueSpecificRelayBroadcast({
    required Nip01Event event,
    required Iterable<String> relayUrls,
    required bool requiresNetworkSigner,
  }) async {
    final relayUrlList = relayUrls.toSet().toList()..sort();
    Logger.log.d(() => 'enqueue pending delivery ${event.id} -> $relayUrlList');
    final existing = await _cacheManager.loadEventDeliveryRecord(event.id);
    final now = Nip01Event.secondsSinceEpoch();

    await _cacheManager.saveEventDeliveryRecord(
      EventDeliveryRecord(
        eventId: event.id,
        status: existing?.status ?? EventDeliveryStatus.pending,
        createdAt: existing?.createdAt ?? event.createdAt,
        updatedAt: now,
        signedAt: existing?.signedAt,
        completedAt: existing?.completedAt,
        requiresNetworkSigner: requiresNetworkSigner,
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
            RelayDeliveryTargetRecord(
              eventId: event.id,
              target: RelayDeliveryTarget(
                relayUrl: relayUrl,
                reason: RelayDeliveryReason.explicit,
              ),
            );
      }).toList(),
    );
  }

  Future<void> persistSpecificRelayBroadcastResult(BroadcastState state) async {
    final event = state.event;
    if (event == null) {
      return;
    }
    Logger.log.d(() =>
        'persist broadcast result ${event.id} -> ${state.broadcasts.keys.toList()}');

    final existing = await _cacheManager.loadEventDeliveryRecord(event.id);
    if (existing == null) {
      return;
    }

    final existingTargets =
        await _cacheManager.loadRelayDeliveryTargets(eventId: event.id);
    final targetsByRelay = {
      for (final target in existingTargets) target.relayUrl: target,
    };

    final updatedTargets = <RelayDeliveryTargetRecord>[];
    final policy = DeliveryPolicy.forEvent(event);
    for (final response in state.broadcasts.values) {
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
          target: current.target.copyWith(
            state: nextState,
            attemptCount: current.attemptCount + 1,
            lastAttemptAt: attemptTimestamp,
            nextRetryAt: nextRetryAt,
            lastOkMessage: isAcked ? response.msg : current.lastOkMessage,
            lastError: isAcked ? null : response.msg,
          ),
        ),
      );
    }

    if (updatedTargets.isNotEmpty) {
      await _cacheManager.saveRelayDeliveryTargets(updatedTargets);
    }

    final allTargets =
        await _cacheManager.loadRelayDeliveryTargets(eventId: event.id);
    final deliveryStatus = _resolveDeliveryStatus(allTargets);

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
        if (_broadcast.isEventInFlight(target.eventId)) {
          continue;
        }

        final event = await _cacheManager.loadEvent(target.eventId);
        if (event == null) {
          await _cacheManager.removeRelayDeliveryTarget(
            eventId: target.eventId,
            relayUrl: relayUrl,
          );
          continue;
        }

        if (await _isObsoleteReplaceableOrAddressableEvent(event)) {
          Logger.log.d(
              () => 'drop obsolete pending delivery ${event.id} for $relayUrl');
          await _discardEventDelivery(event.id);
          continue;
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

        await _broadcast.broadcast(
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

  bool _isAddressableKind(int kind) {
    return EventKindClassification.isAddressableKind(kind);
  }

  EventDeliveryStatus _resolveDeliveryStatus(
    List<RelayDeliveryTargetRecord> targets,
  ) {
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
