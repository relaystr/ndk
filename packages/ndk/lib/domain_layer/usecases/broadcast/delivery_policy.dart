import '../../entities/broadcast_state.dart';
import '../../entities/event_cache_records.dart';
import '../../entities/nip_01_event.dart';
import '../../../shared/nips/nip01/event_kind_classification.dart';
import '../../../shared/nips/nip09/deletion.dart';

enum DeliveryPolicyKind {
  persistentEventual,
  latestStateOnly,
  highPriorityControl,
  doNotRetry,
}

class DeliveryPolicy {
  static const Set<String> _permanentFailurePrefixes = {
    'blocked',
    'duplicate',
    'invalid',
    'pow',
    'restricted',
  };

  static const Set<String> _transientFailurePrefixes = {
    'error',
    'rate-limited',
  };

  static const List<String> _permanentFailureMarkers = [
    'bad signature',
    'bad event id',
    'invalid signature',
    'invalid event',
    'invalid id',
    'invalid kind',
    'invalid expiration',
    'too many tags',
    'event too large',
    'event exceeded max size',
    'message too large',
    'too large',
    'forbidden',
    'policy violation',
  ];

  final DeliveryPolicyKind kind;

  const DeliveryPolicy._(this.kind);

  factory DeliveryPolicy.forEvent(Nip01Event event) {
    if (EventKindClassification.isEphemeralKind(event.kind)) {
      return const DeliveryPolicy._(DeliveryPolicyKind.doNotRetry);
    }
    if (event.kind == Deletion.kKind) {
      return const DeliveryPolicy._(DeliveryPolicyKind.highPriorityControl);
    }
    if (EventKindClassification.isReplaceableKind(event.kind)) {
      return const DeliveryPolicy._(DeliveryPolicyKind.latestStateOnly);
    }
    return const DeliveryPolicy._(DeliveryPolicyKind.persistentEventual);
  }

  bool get retainsOnlyLatest => kind == DeliveryPolicyKind.latestStateOnly;

  RelayDeliveryState resolveNextState(RelayBroadcastResponse response) {
    if (response.okReceived && response.broadcastSuccessful) {
      return RelayDeliveryState.acked;
    }

    if (response.msg.startsWith('auth-required')) {
      return RelayDeliveryState.authRequired;
    }

    if (_looksPermanent(response.msg)) {
      return RelayDeliveryState.permanentFailure;
    }

    if (kind == DeliveryPolicyKind.doNotRetry) {
      return RelayDeliveryState.permanentFailure;
    }

    if (response.msg.isNotEmpty) {
      return RelayDeliveryState.transientFailure;
    }

    return RelayDeliveryState.attempting;
  }

  bool shouldRetryState(RelayDeliveryState state) {
    if (state == RelayDeliveryState.acked ||
        state == RelayDeliveryState.permanentFailure) {
      return false;
    }
    if (kind == DeliveryPolicyKind.doNotRetry) {
      return false;
    }
    return true;
  }

  Duration retryDelayFor({
    required RelayDeliveryState state,
    required int attemptCount,
  }) {
    if (!shouldRetryState(state)) {
      return Duration.zero;
    }

    if (state == RelayDeliveryState.authRequired) {
      return const Duration(minutes: 1);
    }

    final retrySeconds = switch (kind) {
      DeliveryPolicyKind.highPriorityControl => switch (attemptCount) {
          <= 1 => 2,
          2 => 5,
          3 => 15,
          4 => 60,
          _ => 300,
        },
      DeliveryPolicyKind.persistentEventual => switch (attemptCount) {
          <= 1 => 5,
          2 => 15,
          3 => 60,
          4 => 300,
          _ => 900,
        },
      DeliveryPolicyKind.latestStateOnly => switch (attemptCount) {
          <= 1 => 5,
          2 => 15,
          3 => 60,
          4 => 300,
          _ => 900,
        },
      DeliveryPolicyKind.doNotRetry => 0,
    };
    return Duration(seconds: retrySeconds);
  }

  static bool _looksPermanent(String message) {
    final normalized = message.trim().toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }

    final prefix = _machineReadablePrefix(normalized);
    if (prefix != null) {
      if (_permanentFailurePrefixes.contains(prefix)) {
        return true;
      }
      if (_transientFailurePrefixes.contains(prefix)) {
        return false;
      }
    }

    return _permanentFailureMarkers.any(normalized.contains);
  }

  static String? _machineReadablePrefix(String normalizedMessage) {
    final separatorIndex = normalizedMessage.indexOf(':');
    if (separatorIndex <= 0) {
      return null;
    }

    return normalizedMessage.substring(0, separatorIndex).trim();
  }
}
