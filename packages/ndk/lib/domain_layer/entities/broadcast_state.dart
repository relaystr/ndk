import 'dart:async';
import 'package:rxdart/rxdart.dart';

/// hols information about a individual relay broadcast response \
/// e.g. \
/// ["OK", "b1a649ebe8...", true, "duplicate: already have this event"]
/// ["OK", "b1a649ebe8...", false, "pow: difficulty 26 is less than 30"]
class RelayBroadcastResponse {
  /// the relay url
  final String relayUrl;

  /// true if the relay responded with "OK"
  bool okReceived;

  /// true if publishing was successful
  bool broadcastSuccessful;

  /// the response message usually an error message
  String msg;

  /// creates a new [RelayBroadcastResponse] instance
  RelayBroadcastResponse({
    required this.relayUrl,
    this.okReceived = false,
    this.broadcastSuccessful = false,
    this.msg = "",
  });

  @override
  operator ==(other) =>
      other is RelayBroadcastResponse && relayUrl == other.relayUrl;

  @override
  int get hashCode => relayUrl.hashCode;
}

/// hold state information for a broadcast
class BroadcastState {
  /// value between 0 and 1, 1 =>  all relays have responded with "OK" the broadcast is considered done
  final double considerDonePercent;

  final Duration timeout;

  /// stream controller for state updates
  final BehaviorSubject<BroadcastState> _stateUpdatesController =
      BehaviorSubject<BroadcastState>();

  /// [networkController] used by relay manger to write responses
  StreamController<RelayBroadcastResponse> networkController =
      StreamController<RelayBroadcastResponse>();

  /// stream of state updates \
  /// updates are sent when a relay responds, the whole state is sent \
  /// if you call .listen() the last state is sent immediately
  Stream<BroadcastState> get stateUpdates => _stateUpdatesController.stream;

  //! our broadcast tracking obj
  /// key is relay url, value is [RelayBroadcastResponse]
  Map<String, RelayBroadcastResponse> broadcasts = {};

  /// completes when all relays have responded or timed out
  /// first string is the relay url, second is the response
  bool get publishDone {
    final doneCount = broadcasts.values
        .where((element) => element.okReceived)
        .length
        .toDouble();
    final totalCount = broadcasts.length.toDouble();
    return doneCount / totalCount >= considerDonePercent;
  }

  /// completes when state update controller closes
  Future<BroadcastState> get publishDoneFuture => _stateUpdatesController.last;

  late final StreamSubscription _networkSubscription;

  /// creates a new [BroadcastState] instance
  BroadcastState({
    required this.timeout,
    this.considerDonePercent = 1,
  }) {
    _networkSubscription = networkController.stream.listen((response) {
      // got a response from a relay
      broadcasts[response.relayUrl] = response;
      // send state update
      _stateUpdatesController.add(this);
      // check if all relays responded
      _checkBroadcastDone();
    });

    Future.delayed(timeout, () {
      if (!publishDone) {
        _stateUpdatesController.add(this);
        _dispose();
      }
    });
  }

  void _checkBroadcastDone() {
    if (publishDone) {
      _dispose();
    }
  }

  /// dispose of the broadcast state => close all streams
  void _dispose() {
    _networkSubscription.cancel();
    _stateUpdatesController.close();
    networkController.close();
  }
}
