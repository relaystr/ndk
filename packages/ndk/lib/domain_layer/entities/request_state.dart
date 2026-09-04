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

  /// called by the owning [RequestState] whenever a field the outcome is
  /// derived from changes, so the outcome never has to be derived on read
  void Function()? onOutcomeChanged;

  bool _receivedEOSE = false;

  /// did the relay give everything it stored
  bool get receivedEOSE => _receivedEOSE;

  set receivedEOSE(bool value) {
    if (_receivedEOSE == value) return;
    _receivedEOSE = value;
    onOutcomeChanged?.call();
  }

  bool _receivedClosed = false;

  /// did the relay end the request itself
  bool get receivedClosed => _receivedClosed;

  set receivedClosed(bool value) {
    if (_receivedClosed == value) return;
    _receivedClosed = value;
    onOutcomeChanged?.call();
  }

  String? _closedMessage;

  /// message the relay sent with its CLOSED, null when it sent none
  String? get closedMessage => _closedMessage;

  set closedMessage(String? value) {
    if (_closedMessage == value) return;
    _closedMessage = value;
    onOutcomeChanged?.call();
  }

  bool _connectionGone = false;

  /// set when the connection was gone before the relay ended the request
  bool get connectionGone => _connectionGone;

  set connectionGone(bool value) {
    if (_connectionGone == value) return;
    _connectionGone = value;
    onOutcomeChanged?.call();
  }

  bool _retryingAuth = false;

  /// set while this connection authenticates to satisfy the request: the relay
  /// closed it, but it is on its way back and must not count as finished
  bool get retryingAuth => _retryingAuth;

  set retryingAuth(bool value) {
    if (_retryingAuth == value) return;
    _retryingAuth = value;
    onOutcomeChanged?.call();
  }

  List<Filter> filters;

  /// default const
  RelayRequestState(this.key, this.filters);

  /// The relay ended the request with a CLOSED carrying [message].
  ///
  /// Both at once, so the outcome is never observed as a CLOSED stripped of
  /// the reason the relay gave for it.
  void markClosed(String? message) {
    if (_receivedClosed && _closedMessage == message) return;
    _receivedClosed = true;
    _closedMessage = message;
    onOutcomeChanged?.call();
  }

  /// The request is on its way to the relay again, so whatever ended it the
  /// last time no longer holds.
  void markSent() {
    if (!_receivedClosed &&
        _closedMessage == null &&
        !_connectionGone &&
        !_retryingAuth) {
      return;
    }
    _receivedClosed = false;
    _closedMessage = null;
    _connectionGone = false;
    _retryingAuth = false;
    onOutcomeChanged?.call();
  }
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

  bool _timedOut = false;

  /// set when the request ended on its timeout instead of on the relays
  bool get timedOut => _timedOut;

  set timedOut(bool value) {
    if (_timedOut == value) return;
    _timedOut = value;
    _refreshRelayOutcomes();
  }

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
        // a query ends here rather than on close(), its controller is closed
        // by the response cleaner once every relay is done
        _relayOutcomesDone = true;
        _relayOutcomesSubject?.close();
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

  final Map<String, RelayRequestOutcome> _relayOutcomes = {};

  Map<String, RelayRequestOutcome> _relayOutcomesSnapshot = const {};

  BehaviorSubject<Map<String, RelayRequestOutcome>>? _relayOutcomesSubject;

  bool _relayOutcomesDone = false;

  /// What the request ended with on each relay it was sent to, as it stands now
  ///
  /// Keyed by relay url: several connections to one relay collapse into the
  /// outcome that comes first in [RelayRequestStatus].
  Map<String, RelayRequestOutcome> get relayOutcomes =>
      servedBy?.relayOutcomes ?? _relayOutcomesSnapshot;

  /// [relayOutcomes] on every change, starting with what it holds right now,
  /// and closed once the request is over.
  ///
  /// Late subscribers get the current outcomes instead of missing everything
  /// the relays answered before they listened.
  Stream<Map<String, RelayRequestOutcome>> get relayOutcomesStream {
    final served = servedBy;
    if (served != null) {
      return served.relayOutcomesStream;
    }
    final subject = _relayOutcomesSubject ??=
        BehaviorSubject.seeded(_relayOutcomesSnapshot);
    // asked for once the request is over: nothing is left to close a subject
    // created this late, and a closed one still replays what it ended on
    if (_relayOutcomesDone) {
      subject.close();
    }
    return subject.stream;
  }

  /// Recomputes every relay, for a change that reaches all of them at once.
  void _refreshRelayOutcomes() {
    var changed = false;
    for (final url in requests.values.map((request) => request.url).toSet()) {
      changed = _recomputeRelayOutcome(url) || changed;
    }
    if (changed) {
      _publishRelayOutcomes();
    }
  }

  void _onRelayRequestChanged(String url) {
    if (_recomputeRelayOutcome(url)) {
      _publishRelayOutcomes();
    }
  }

  /// Collapses the connections to [url] into its outcome, returning whether
  /// that outcome moved.
  bool _recomputeRelayOutcome(String url) {
    RelayRequestOutcome? collapsed;
    for (final request in requests.values) {
      if (request.url != url) continue;
      final outcome = _outcomeOf(request);
      if (collapsed == null || outcome.status.index < collapsed.status.index) {
        collapsed = outcome;
      }
    }
    if (collapsed == null) {
      return _relayOutcomes.remove(url) != null;
    }
    if (_relayOutcomes[url] == collapsed) {
      return false;
    }
    _relayOutcomes[url] = collapsed;
    return true;
  }

  void _publishRelayOutcomes() {
    _relayOutcomesSnapshot = Map.unmodifiable(_relayOutcomes);
    final subject = _relayOutcomesSubject;
    if (subject != null && !subject.isClosed) {
      subject.add(_relayOutcomesSnapshot);
    }
  }

  RelayRequestOutcome _outcomeOf(RelayRequestState request) {
    if (request.retryingAuth) {
      return const RelayRequestOutcome(RelayRequestStatus.pending);
    }
    if (request.receivedEOSE) {
      return const RelayRequestOutcome(RelayRequestStatus.eose);
    }
    if (request.receivedClosed) {
      return RelayRequestOutcome(
        RelayRequestStatus.closed,
        message: request.closedMessage,
      );
    }
    if (request.connectionGone) {
      return const RelayRequestOutcome(RelayRequestStatus.disconnected);
    }
    if (timedOut) {
      return const RelayRequestOutcome(RelayRequestStatus.timedOut);
    }
    return const RelayRequestOutcome(RelayRequestStatus.pending);
  }

  /// Adds single relay request to the state
  void addRequest(RelayConnectionKey key, List<Filter> filters) {
    if (requests.containsKey(key)) return;
    _trackRequest(RelayRequestState(key, filters));
  }

  /// Adds single relay request to the state, merging [filters] into the one
  /// already tracked on the same connection
  void registerRequest(RelayConnectionKey key, List<Filter> filters) {
    final tracked = requests[key];
    if (tracked != null) {
      tracked.filters.addAll(filters);
      return;
    }
    _trackRequest(RelayRequestState(key, filters));
  }

  /// Drops a relay request, for a relay the request could not be sent to
  void removeRequest(RelayConnectionKey key) {
    final dropped = requests.remove(key);
    if (dropped == null) return;
    dropped.onOutcomeChanged = null;
    _onRelayRequestChanged(dropped.url);
  }

  void _trackRequest(RelayRequestState request) {
    request.onOutcomeChanged = () => _onRelayRequestChanged(request.url);
    requests[request.key] = request;
    _onRelayRequestChanged(request.url);
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
