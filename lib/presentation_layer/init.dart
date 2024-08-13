import 'package:http/http.dart' as http;

import '../data_layer/data_sources/http_request.dart';
import '../domain_layer/usecases/jit_engine.dart';
import '../domain_layer/usecases/relay_manager.dart';
import 'global_state.dart';
import 'ndk_config.dart';

class Initialization {
  final NdkConfig ndkConfig;
  final GlobalState globalState;

  /// data sources

  final HttpRequestDS _httpRequestDS = HttpRequestDS(http.Client());

  /// repositories

  /// state obj

  RelayManager? relayManager;

  JitEngine? jitEngine;

  Initialization({
    required this.ndkConfig,
    required this.globalState,
  }) {
    switch (ndkConfig.engine) {
      case NdkEngine.LISTS:
        relayManager = RelayManager(
          cacheManager: ndkConfig.cache,
          eventVerifier: ndkConfig.eventVerifier,
          bootstrapRelays: ndkConfig.bootstrapRelays,
          globalState: globalState,
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
  }
