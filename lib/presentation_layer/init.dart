import 'package:http/http.dart' as http;

import '../data_layer/data_sources/http_request.dart';
import '../domain_layer/usecases/cache_read/cache_read.dart';
import '../domain_layer/usecases/cache_write/cache_write.dart';
import '../domain_layer/usecases/contact_lists.dart';
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

  /// state obj

  /// use cases
  late RelayManager relayManager;
  late CacheWrite cacheWrite;
  late CacheRead cacheRead;
  late Requests requests;
  late ContactLists contactLists;

  RelaySetsEngine? relaySetsEngine;
  JitEngine? jitEngine;

  Initialization({
    required this.config,
    required this.globalState,
  }) {
    relayManager = RelayManager(
        eventVerifier: config.eventVerifier,
        bootstrapRelays: config.bootstrapRelays,
        globalState: globalState);
    switch (config.engine) {
      case NdkEngine.RELAY_SETS:
        relaySetsEngine = RelaySetsEngine(
          cacheManager: config.cache,
          eventVerifier: config.eventVerifier,
          globalState: globalState,
          relayManager: relayManager,
        );
      case NdkEngine.JIT:
        jitEngine = JitEngine(
          eventVerifier: config.eventVerifier,
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
        requestManager: relaySetsEngine,
        jitEngine: jitEngine);

    contactLists = ContactLists(
        requests: requests,
        cacheManager: config.cache,
        relayManager: relayManager);
  }
}
