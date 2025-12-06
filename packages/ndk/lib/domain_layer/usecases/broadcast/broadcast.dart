import 'package:ndk/ndk.dart';

import '../../../shared/helpers/relay_helper.dart';
import '../../../shared/nips/nip09/deletion.dart';
import '../../../shared/nips/nip25/reactions.dart';
import '../../entities/broadcast_state.dart';
import '../../entities/global_state.dart';
import '../engines/network_engine.dart';

/// class for low level nostr broadcasts / publish \
/// wraps the engines to inject singer
class Broadcast {
  final NetworkEngine _engine;
  final Accounts _accounts;
  final CacheManager _cacheManager;
  final GlobalState _globalState;
  final double _considerDonePercent;
  final Duration _timeout;

  /// creates a new [Broadcast] instance
  ///
  Broadcast({
    required GlobalState globalState,
    required CacheManager cacheManager,
    required NetworkEngine networkEngine,
    required Accounts accounts,
    required double considerDonePercent,
    required Duration timeout,
  })  : _accounts = accounts,
        _cacheManager = cacheManager,
        _engine = networkEngine,
        _globalState = globalState,
        _considerDonePercent = considerDonePercent,
        _timeout = timeout;

  /// [throws] if the default signer and the custom signer are null \
  /// [returns] the signer that is not null, if both are provided returns [customSigner]
  EventSigner _checkSinger({EventSigner? customSigner}) {
    if (_accounts.isNotLoggedIn && customSigner == null) {
      throw "cannot broadcast without a signer!";
    }
    return customSigner ?? _accounts.getLoggedAccount()!.signer;
  }

  /// low level nostr broadcast using inbox/outbox (gossip) \
  /// [specificRelays] disables inbox/outbox (gossip) and broadcasts to the relays specified. Useful for NostrWalletConnect \
  /// [customSigner] if you want to use a different signer than the one from currently logged in user in [Accounts] \
  /// [considerDonePercent] the percentage (0.0, 1.0) of relays that need to respond with "OK" for the broadcast to be considered done (overrides the default value) \
  /// [timeout] the timeout for the broadcast (overrides the default timeout) \
  /// [returns] a [NdkBroadcastResponse] object containing the result => success per relay
  NdkBroadcastResponse broadcast({
    required Nip01Event nostrEvent,
    Iterable<String>? specificRelays,
    EventSigner? customSigner,
    double? considerDonePercent,
    Duration? timeout,
  }) {
    final myConsiderDonePercent = considerDonePercent ?? _considerDonePercent;
    final myTimeout = timeout ?? _timeout;

    final broadcastState = BroadcastState(
      considerDonePercent: myConsiderDonePercent,
      timeout: myTimeout,
    );
    // register broadcast state
    _globalState.inFlightBroadcasts[nostrEvent.id] = broadcastState;

    final signer = nostrEvent.sig == null
        ? _checkSinger(customSigner: customSigner)
        : null;

    final cleanedSpecificRelays =
        specificRelays != null ? cleanRelayUrls(specificRelays.toList()) : null;

    return _engine.handleEventBroadcast(
      nostrEvent: nostrEvent,
      signer: signer,
      specificRelays: cleanedSpecificRelays,
      doneStream: broadcastState.stateUpdates
          .map((state) => state.broadcasts.values.toList()),
    );
  }

  /// **********************************************************************************************************
  /// convenience methods
  /// **********************************************************************************************************

  /// broadcast a reaction to an event \
  /// [eventId] the event you want to react to \
  /// [customRelays] relay URls to send the deletion request to specific relays \
  /// [reaction] the reaction, default + (like) can be 🤔 (emoji)
  NdkBroadcastResponse broadcastReaction({
    required String eventId,
    Iterable<String>? customRelays,
    String reaction = "+",
  }) {
    final signer = _checkSinger();
    Nip01Event event = Nip01EventService.createEventCalculateId(
        pubKey: signer.getPublicKey(),
        kind: Reaction.kKind,
        tags: [
          ["e", eventId]
        ],
        content: reaction,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000);
    return broadcast(nostrEvent: event, specificRelays: customRelays);
  }

  /// request a deletion of an event \
  /// [eventId] event you want to delete \
  /// [eventIds] events you want to delete \
  /// [customRelays] relay URls to send the deletion request to specific relays \
  /// [customSigner] if you want to use a different signer than the default specified in [NdkConfig]
  NdkBroadcastResponse broadcastDeletion({
    String? eventId,
    List<String>? eventIds,
    Iterable<String>? customRelays,
    EventSigner? customSigner,
    String reason = "delete",
  }) {
    final EventSigner mySigner = _checkSinger(customSigner: customSigner);

    List<String> idsToDelete = [];
    if (eventId != null) {
      idsToDelete.add(eventId);
    }
    if (eventIds != null) {
      idsToDelete.addAll(eventIds);
    }

    if (idsToDelete.isEmpty) {
      throw ArgumentError(
          "At least one eventId must be provided for deletion.");
    }

    Nip01Event event = Nip01EventService.createEventCalculateId(
        pubKey: mySigner.getPublicKey(),
        kind: Deletion.kKind,
        tags: idsToDelete.map((e) => ["e", e]).toList(),
        content: reason,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000);
    // TODO not bulletproof, think of better way
    for (final id in idsToDelete) {
      _cacheManager.removeEvent(id);
    }
    return broadcast(
      nostrEvent: event,
      specificRelays: customRelays,
      customSigner: mySigner,
    );
  }
}
