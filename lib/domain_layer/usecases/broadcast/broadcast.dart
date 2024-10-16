import '../../entities/broadcast_response.dart';
import '../../entities/global_state.dart';
import '../../entities/nip_01_event.dart';
import '../cache_read/cache_read.dart';
import '../engines/network_engine.dart';

/// class for low level nostr broadcasts / publish
class Broadcast {
  final GlobalState _globalState;
  final CacheRead _cacheRead;
  final NetworkEngine _engine;

  /// creates a new [Broadcast] instance
  ///
  Broadcast({
    required GlobalState globalState,
    required CacheRead cacheRead,
    required NetworkEngine networkEngine,
  })  : _engine = networkEngine,
        _cacheRead = cacheRead,
        _globalState = globalState;

  NdkBroadcastResponse broadcast({
    required Nip01Event nostrEvent,
    required String privateKey,
    List<String>? specificRelays,
  }) {
    return _engine.handleEventBroadcast(
      nostrEvent: nostrEvent,
      privateKey: privateKey,
      specificRelays: specificRelays,
    );
  }
}
