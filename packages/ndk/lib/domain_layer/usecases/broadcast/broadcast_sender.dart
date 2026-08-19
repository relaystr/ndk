import 'package:ndk/ndk.dart';

import '../../../shared/helpers/relay_helper.dart';
import '../../entities/broadcast_state.dart';
import '../../entities/global_state.dart';
import '../engines/network_engine.dart';

/// Low-level broadcaster that sends events to relays immediately. \
/// Has no queue, retry, or persistence logic. \
/// Both the public [Broadcast] facade and [PendingBroadcastDelivery] retry path
/// delegate here so the retry path never re-enters queue enrollment.
class BroadcastSender {
  final NetworkEngine _engine;
  final Accounts _accounts;
  final CacheManager _cacheManager;
  final GlobalState _globalState;
  final double _considerDonePercent;
  final Duration _timeout;
  final bool _saveToCache;

  BroadcastSender({
    required GlobalState globalState,
    required CacheManager cacheManager,
    required NetworkEngine networkEngine,
    required Accounts accounts,
    required double considerDonePercent,
    required Duration timeout,
    required bool saveToCache,
  })  : _accounts = accounts,
        _cacheManager = cacheManager,
        _engine = networkEngine,
        _globalState = globalState,
        _considerDonePercent = considerDonePercent,
        _timeout = timeout,
        _saveToCache = saveToCache;

  bool isEventInFlight(String eventId) {
    return _globalState.inFlightBroadcasts.containsKey(eventId);
  }

  /// [throws] if the default signer and the custom signer are null \
  /// [returns] the signer that is not null, if both are provided returns [customSigner]
  EventSigner _checkSinger({EventSigner? customSigner}) {
    if (_accounts.isNotLoggedIn && customSigner == null) {
      throw "cannot broadcast without a signer!";
    }
    return customSigner ?? _accounts.getLoggedAccount()!.signer;
  }

  /// Sends [nostrEvent] to relays now. No queue enrollment, no retry. \
  /// [specificRelays] disables inbox/outbox (gossip) and broadcasts to the relays specified \
  /// [customSigner] if you want to use a different signer than the one from currently logged in user in [Accounts] \
  /// [considerDonePercent] the percentage (0.0, 1.0) of relays that need to respond with "OK" for the broadcast to be considered done (overrides the default value) \
  /// [timeout] the timeout for the broadcast (overrides the default timeout) \
  /// [saveToCache] whether to save the event to cache (overrides the default value from config) \
  /// [returns] a [NdkBroadcastResponse] object containing the result => success per relay
  NdkBroadcastResponse broadcast({
    required Nip01Event nostrEvent,
    Iterable<String>? specificRelays,
    EventSigner? customSigner,
    double? considerDonePercent,
    Duration? timeout,
    bool? saveToCache,
  }) {
    final myConsiderDonePercent = considerDonePercent ?? _considerDonePercent;
    final myTimeout = timeout ?? _timeout;
    final mySaveToCache = saveToCache ?? _saveToCache;

    final broadcastState = BroadcastState(
      considerDonePercent: myConsiderDonePercent,
      timeout: myTimeout,
    );
    _globalState.inFlightBroadcasts[nostrEvent.id] = broadcastState;
    void cleanupInFlightBroadcastState() {
      if (identical(
        _globalState.inFlightBroadcasts[nostrEvent.id],
        broadcastState,
      )) {
        _globalState.inFlightBroadcasts.remove(nostrEvent.id);
      }
    }

    broadcastState.publishDoneFuture.then(
      (_) => cleanupInFlightBroadcastState(),
      onError: (_, __) => cleanupInFlightBroadcastState(),
    );

    if (mySaveToCache) {
      _cacheManager.saveEvent(nostrEvent);
    }

    final signer = nostrEvent.sig == null
        ? _checkSinger(customSigner: customSigner)
        : null;

    final cleanedSpecificRelays =
        specificRelays != null ? cleanRelayUrls(specificRelays.toList()) : null;

    return _engine.handleEventBroadcast(
      nostrEvent: nostrEvent,
      signer: signer,
      specificRelays: cleanedSpecificRelays,
      broadcastState: broadcastState,
    );
  }
}
