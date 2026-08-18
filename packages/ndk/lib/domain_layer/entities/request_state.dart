import 'dart:async';

import 'package:rxdart/rxdart.dart';

import '../../config/rx_defaults.dart';
import 'filter.dart';
import 'ndk_request.dart';
import 'nip_01_event.dart';
import 'relay_connection_key.dart';
import 'relay_request_outcome.dart';

/// Single relay request state
class RelayRequestState {
  /// connection this request was sent on
  final RelayConnectionKey key;

  /// url of the relay this request was sent to
  String get url => key.url;

  bool receivedEOSE = false;
  bool receivedClosed = false;

  /// message the relay sent with its CLOSED, null when it sent none
  String? closedMessage;

  /// set when the connection was gone before the relay ended the request
  bool connectionGone = false;

  /// set while this connection authenticates to satisfy the request: the relay
  /// closed it, but it is on its way back and must not count as finished
  bool retryingAuth = false;

  List<Filter> filters;

  /// default const
  RelayRequestState(this.key, this.filters);
}

/// State per request for multiple relays
class RequestState {
  ReplaySubject<Nip01Event> controller = ReplaySubject<Nip01Event>(
    maxSize: RX_REPLAYSUBJECT_MAX_EVENTS,
  );

  /// [networkController] used by engines to write their response
  StreamController<Nip01Event> networkController =
      StreamController<Nip01Event>();

  /// [cacheController] is the controller cacheRead writes to
  StreamController<Nip01Event> cacheController = StreamController<Nip01Event>();

  /// ids that got already returned by this request
  Set<String> returnedIds = {};

  Timer? _timeout;
  DateTime? _timeoutStartedAt;
  Duration? _remainingTimeout;

  Stream<Nip01Event> get stream => controller.stream;

  /// request id
  String get id => request.id;

  /// is this a subscription?
  bool get isSubscription => !request.closeOnEOSE;

  ///! our requests tracking obj
  // key is the connection the request was sent on, value is RelayRequestState
  Map<RelayConnectionKey, RelayRequestState> requests = {};

  /// the original request
  NdkRequest request;

  /// this is the working filter obj, gets initialized with user provided filters.
  /// Then on each step (cache, network) resolved filters get removed/updated
  final List<Filter> unresolvedFilters;

  /// timeout duration, closes all streams
  Duration? timeoutDuration;

  /// set when the request ended on its timeout instead of on the relays
  bool timedOut = false;

  /// request this one was merged into by the concurrency check, when its stream
  /// got replaced by an identical request already in flight
  RequestState? servedBy;

  /// called when timeout is triggered
  Function(RequestState)? onTimeout;

  late StreamSubscription<Nip01Event> _streamSubscription;

  /// Cancels the timeout timer without closing streams.
  /// Used when a duplicate request is detected and this request's stream
  /// will be fed from another in-flight request.
  void cancelTimeout() {
    _timeout?.cancel();
    _timeout = null;
  }

  /// Creates a new [RequestState] instance
  RequestState(this.request) : unresolvedFilters = request.filters {
    // if we have a timeout set, we start it
    if (request.timeoutDuration != null) {
      timeoutDuration = request.timeoutDuration;
      _startTimeout(timeoutDuration!);
    }
    _streamSubscription = controller.listen(
      (e) {},
      onDone: () {
        if (_timeout != null) {
          _timeout!.cancel();
        }
        _streamSubscription.cancel();
      },
    );
  }

  void _startTimeout(Duration duration) {
    _timeoutStartedAt = DateTime.now();
    _timeout = Timer(duration, () {
      timedOut = true;
      onTimeout?.call(this);
      close();
    });
  }

  /// Pauses the timeout timer. Call this before signing starts.
  void pauseTimeout() {
    if (_timeout == null || timeoutDuration == null) return;

    final elapsed = DateTime.now().difference(_timeoutStartedAt!);
    _remainingTimeout = timeoutDuration! - elapsed;
    if (_remainingTimeout!.isNegative) {
      _remainingTimeout = Duration.zero;
    }
    _timeout!.cancel();
    _timeout = null;
  }

  /// Resumes the timeout timer. Call this after signing completes.
  void resumeTimeout() {
    if (_remainingTimeout == null) return;
    _startTimeout(_remainingTimeout!);
    _remainingTimeout = null;
  }

  /// checks if all requests finished (received EOSE or CLOSED)
  bool get didAllRequestsFinish => requests.values.every(
    (element) =>
        (element.receivedEOSE || element.receivedClosed) &&
        !element.retryingAuth,
  );

  /// What the request ended with on each relay it was sent to, as it stands now
  ///
  /// Keyed by relay url: several connections to one relay collapse into the
  /// outcome that comes first in [RelayRequestOutcomeType].
  Map<String, RelayRequestOutcome> get relayOutcomes {
    final served = servedBy;
    if (served != null) {
      return served.relayOutcomes;
    }

    final outcomes = <String, RelayRequestOutcome>{};
    for (final request in requests.values) {
      final outcome = _outcomeOf(request);
      final current = outcomes[request.url];
      if (current == null || outcome.type.index < current.type.index) {
        outcomes[request.url] = outcome;
      }
    }
    return outcomes;
  }

  RelayRequestOutcome _outcomeOf(RelayRequestState request) {
    if (request.retryingAuth) {
      return const RelayRequestOutcome(RelayRequestOutcomeType.pending);
    }
    if (request.receivedEOSE) {
      return const RelayRequestOutcome(RelayRequestOutcomeType.eose);
    }
    if (request.receivedClosed) {
      return RelayRequestOutcome(
        RelayRequestOutcomeType.closed,
        message: request.closedMessage,
      );
    }
    if (request.connectionGone) {
      return const RelayRequestOutcome(RelayRequestOutcomeType.disconnected);
    }
    if (timedOut) {
      return const RelayRequestOutcome(RelayRequestOutcomeType.timedOut);
    }
    return const RelayRequestOutcome(RelayRequestOutcomeType.pending);
  }

  /// Adds single relay request to the state
  void addRequest(RelayConnectionKey key, List<Filter> filters) {
    if (!requests.containsKey(key)) {
      requests[key] = RelayRequestState(key, filters);
    }
  }

  /// closes all streams
  Future<void> close() async {
    if (_timeout != null) {
      _timeout!.cancel();
    }
    await networkController.close();
    await cacheController.close();
    await controller.close();
  }
}
