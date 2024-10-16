import '../../entities/broadcast_response.dart';
import '../../entities/global_state.dart';
import '../../entities/nip_01_event.dart';
import '../../repositories/event_signer.dart';
import '../cache_read/cache_read.dart';
import '../engines/network_engine.dart';

/// class for low level nostr broadcasts / publish
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

  /// low level nostr broadcast using inbox/outbox (gossip)
  /// [specificRelays] disables inbox/outbox (gossip) and broadcasts to the relays specified. Useful for NostrWalletConnect
  /// [customSigner] if you want to use a different signer than the default specified in [NdkConfig]
  /// [returns] a [NdkBroadcastResponse] object containing the result => success per relay
  NdkBroadcastResponse broadcast({
    required Nip01Event nostrEvent,
    List<String>? specificRelays,
    EventSigner? customSigner,
  }) {
    if (_signer == null) {
      throw "cannot broadcast without a signer!";
    }

    return _engine.handleEventBroadcast(
      nostrEvent: nostrEvent,
      mySigner: customSigner ?? _signer,
      specificRelays: specificRelays,
    );
  }
}
