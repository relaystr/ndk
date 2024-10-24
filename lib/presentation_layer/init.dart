import '../data_layer/repositories/nostr_transport/websocket_nostr_transport_factory.dart';
import '../domain_layer/entities/global_state.dart';
import '../domain_layer/usecases/broadcast/broadcast.dart';
import '../domain_layer/usecases/cache_read/cache_read.dart';
import '../domain_layer/usecases/cache_write/cache_write.dart';
import '../domain_layer/usecases/engines/network_engine.dart';
import '../domain_layer/usecases/follows/follows.dart';
import '../domain_layer/usecases/jit_engine.dart';
import '../domain_layer/usecases/lists/lists.dart';
import '../domain_layer/usecases/metadatas/metadatas.dart';
import '../domain_layer/usecases/relay_manager.dart';
import '../domain_layer/usecases/relay_sets/relay_sets.dart';
import '../domain_layer/usecases/relay_sets_engine.dart';
import '../domain_layer/usecases/requests/requests.dart';
import '../domain_layer/usecases/user_relay_lists/user_relay_lists.dart';
import 'ndk_config.dart';

/// this class is used to inject all the dependencies \
/// its like playing lego ;)
class Initialization {
  final NdkConfig ndkConfig;
  final GlobalState globalState;

  /// data sources

  // final HttpRequestDS _httpRequestDS = HttpRequestDS(http.Client());

  /// repositories

  final WebSocketNostrTransportFactory _webSocketNostrTransportFactory =
      WebSocketNostrTransportFactory();

  /// state obj

  /// use cases
  late RelayManager relayManager;
  late CacheWrite cacheWrite;
  late CacheRead cacheRead;
  late Requests requests;
  late Follows follows;
  late Metadatas metadatas;
  late UserRelayLists userRelayLists;
  late Lists lists;
  late RelaySets relaySets;
  late Broadcast broadcast;

  late final NetworkEngine engine;

  /// [NdkConfig] is user defined
  /// [GlobalState] global state object that schuld stay in memory
  Initialization({
    required this.ndkConfig,
    required this.globalState,
  }) {
    relayManager = RelayManager(
      nostrTransportFactory: _webSocketNostrTransportFactory,
      bootstrapRelays: ndkConfig.bootstrapRelays,
      globalState: globalState,
    );
    switch (ndkConfig.engine) {
      case NdkEngine.RELAY_SETS:
        engine = RelaySetsEngine(
          cacheManager: ndkConfig.cache,
          globalState: globalState,
          relayManager: relayManager,
          signer: ndkConfig.eventSigner,
        );
        break;
      case NdkEngine.JIT:
        engine = JitEngine(
          eventSigner: ndkConfig.eventSigner,
          cache: ndkConfig.cache,
          ignoreRelays: ndkConfig.ignoreRelays,
          seedRelays: ndkConfig.bootstrapRelays,
          globalState: globalState,
        );
        break;
      default:
        throw UnimplementedError("Unknown engine");
    }
    cacheWrite = CacheWrite(ndkConfig.cache);
    cacheRead = CacheRead(ndkConfig.cache);

    requests = Requests(
      globalState: globalState,
      cacheRead: cacheRead,
      cacheWrite: cacheWrite,
      networkEngine: engine,
      eventVerifier: ndkConfig.eventVerifier,
    );

    broadcast = Broadcast(
      globalState: globalState,
      cacheRead: cacheRead,
      networkEngine: engine,
      signer: ndkConfig.eventSigner,
    );

    follows = Follows(
      requests: requests,
      cacheManager: ndkConfig.cache,
      relayManager: relayManager,
      broadcast: broadcast,
      signer: ndkConfig.eventSigner,
    );

    metadatas = Metadatas(
      requests: requests,
      cacheManager: ndkConfig.cache,
      relayManager: relayManager,
      broadcast: broadcast,
      signer: ndkConfig.eventSigner,
    );

    userRelayLists = UserRelayLists(
      requests: requests,
      cacheManager: ndkConfig.cache,
      relayManager: relayManager,
    );

    lists = Lists(
      requests: requests,
      cacheManager: ndkConfig.cache,
      relayManager: relayManager,
    );

    relaySets = RelaySets(
      cacheManager: ndkConfig.cache,
      relayManager: relayManager,
      userRelayLists: userRelayLists,
    );
  }
}
