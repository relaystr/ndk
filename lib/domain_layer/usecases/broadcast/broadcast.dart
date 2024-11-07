import '../../../shared/nips/nip09/deletion.dart';
import '../../../shared/nips/nip25/reactions.dart';
import '../../entities/broadcast_response.dart';
import '../../entities/global_state.dart';
import '../../entities/nip_01_event.dart';
import '../../repositories/event_signer.dart';
import '../cache_read/cache_read.dart';
import '../engines/network_engine.dart';

/// class for low level nostr broadcasts / publish \
/// wraps the engines to inject singer
class Broadcast {
  final NetworkEngine _engine;
  final EventSigner? _signer;

  /// creates a new [Broadcast] instance
  ///
  Broadcast({
    required GlobalState globalState,
    required CacheRead cacheRead,
    required NetworkEngine networkEngine,
    required EventSigner? signer,
  })  : _signer = signer,
        _engine = networkEngine;

  /// [throws] if the default signer and the custom signer are null \
  /// [returns] the signer that is not null, if both are provided returns [customSigner]
  EventSigner _checkSinger({EventSigner? customSigner}) {
    if (_signer == null && customSigner == null) {
      throw "cannot broadcast without a signer!";
    }
    return customSigner ?? _signer!;
  }

  /// low level nostr broadcast using inbox/outbox (gossip) \
  /// [specificRelays] disables inbox/outbox (gossip) and broadcasts to the relays specified. Useful for NostrWalletConnect \
  /// [customSigner] if you want to use a different signer than the default specified in [NdkConfig] \
  /// [returns] a [NdkBroadcastResponse] object containing the result => success per relay
  NdkBroadcastResponse broadcast({
    required Nip01Event nostrEvent,
    Iterable<String>? specificRelays,
    EventSigner? customSigner,
  }) {
    final mySigner = _checkSinger(customSigner: customSigner);

    return _engine.handleEventBroadcast(
      nostrEvent: nostrEvent,
      mySigner: mySigner,
      specificRelays: specificRelays,
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
    Nip01Event event = Nip01Event(
        pubKey: signer.getPublicKey(),
        kind: Reaction.KIND,
        tags: [
          ["e", eventId]
        ],
        content: reaction,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000);
    return broadcast(nostrEvent: event, specificRelays: customRelays);
  }

  /// request a deletion of an event \
  /// [eventId] event you want to delete \
  /// [customRelays] relay URls to send the deletion request to specific relays \
  /// [customSigner] if you want to use a different signer than the default specified in [NdkConfig]
  NdkBroadcastResponse broadcastDeletion({
    required String eventId,
    Iterable<String>? customRelays,
    EventSigner? customSigner,
  }) {
    final EventSigner mySigner = _checkSinger(customSigner: customSigner);

    Nip01Event event = Nip01Event(
        pubKey: mySigner.getPublicKey(),
        kind: Deletion.KIND,
        tags: [
          ["e", eventId]
        ],
        content: "delete",
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000);
    return broadcast(
      nostrEvent: event,
      specificRelays: customRelays,
      customSigner: mySigner,
    );
  }
}
