import 'package:http/http.dart' as http;

import '../data_layer/data_sources/http_request.dart';
import '../domain_layer/usecases/cache_read/cache_read.dart';
import '../domain_layer/usecases/cache_write/cache_write.dart';
import '../domain_layer/usecases/jit_engine.dart';
import '../domain_layer/usecases/relay_manager.dart';
import '../domain_layer/usecases/request_manager.dart';
import 'global_state.dart';
import 'ndk_config.dart';

class Initialization {
  final NdkConfig ndkConfig;
  final GlobalState globalState;

  /// data sources

  final HttpRequestDS _httpRequestDS = HttpRequestDS(http.Client());

  /// repositories

  /// state obj

  /// use cases

  RequestManager? requestManager;

  JitEngine? jitEngine;

  late RelayManager relayManager;

  late CacheWrite cacheWrite;

  late CacheRead cacheRead;

  Initialization({
    required this.ndkConfig,
    required this.globalState,
  }) {
    relayManager = RelayManager(
      eventVerifier: ndkConfig.eventVerifier,
      bootstrapRelays: ndkConfig.bootstrapRelays,
      globalState: globalState
    );
    switch (ndkConfig.engine) {
      case NdkEngine.LISTS:
        requestManager = RequestManager(
          cacheManager: ndkConfig.cache,
          eventVerifier: ndkConfig.eventVerifier,
          globalState: globalState,
          relayManager: relayManager,
        );
      case NdkEngine.JIT:
        jitEngine = JitEngine(
          eventVerifier: ndkConfig.eventVerifier,
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
  }
}
