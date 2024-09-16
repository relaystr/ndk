import 'package:http/http.dart' as http;

import '../data_layer/data_sources/http_request.dart';
import '../data_layer/repositories/nostr_transport/websocket_nostr_transport_factory.dart';
import '../domain_layer/usecases/cache_read/cache_read.dart';
import '../domain_layer/usecases/cache_write/cache_write.dart';
import '../domain_layer/usecases/engines/network_engine.dart';
import '../domain_layer/usecases/follows/follows.dart';
import '../domain_layer/usecases/jit_engine.dart';
import '../domain_layer/usecases/relay_manager.dart';
import '../domain_layer/usecases/relay_sets_engine.dart';
import '../domain_layer/usecases/requests/requests.dart';
import '../domain_layer/entities/global_state.dart';
import 'ndk_config.dart';

class Initialization {
  final NdkConfig config;
  final GlobalState globalState;

  /// data sources

  final HttpRequestDS _httpRequestDS = HttpRequestDS(http.Client());

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

  late final NetworkEngine engine;

  Initialization({
    required this.config,
    required this.globalState,
  }) {
    relayManager = RelayManager(
      nostrTransportFactory: _webSocketNostrTransportFactory,
      eventVerifier: config.eventVerifier,
      bootstrapRelays: config.bootstrapRelays,
      globalState: globalState,
    );
    switch (config.engine) {
      case NdkEngine.RELAY_SETS:
        engine = RelaySetsEngine(
          cacheManager: config.cache,
          globalState: globalState,
          relayManager: relayManager,
        );
        break;
      case NdkEngine.JIT:
        engine = JitEngine(
          eventSigner: config.eventSigner,
          cache: config.cache,
          ignoreRelays: config.ignoreRelays,
          seedRelays: config.bootstrapRelays,
          globalState: globalState,
        );
        break;
      default:
        throw UnimplementedError("Unknown engine");
    }
    cacheWrite = CacheWrite(config.cache);
    cacheRead = CacheRead(config.cache);

    requests = Requests(
      globalState: globalState,
      cacheRead: cacheRead,
      cacheWrite: cacheWrite,
      networkEngine: engine,
      eventVerifier: config.eventVerifier,
    );

    follows = Follows(
      requests: requests,
      cacheManager: config.cache,
      relayManager: relayManager,
    );
  }
}
