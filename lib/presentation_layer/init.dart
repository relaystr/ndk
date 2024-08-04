import 'package:http/http.dart' as http;

import '../data_layer/data_sources/http_request.dart';
import '../domain_layer/usecases/relay_jit_manager.dart';
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

  final relayManger = RelayManager();

  final RelayJitManager relayJitManager;

  Initialization({
    required this.ndkConfig,
    required this.globalState,
  }) : relayJitManager = RelayJitManager(
          eventVerifier: ndkConfig.eventVerifier,
          eventSigner: ndkConfig.eventSigner,
          cache: ndkConfig.cache,
          ignoreRelays: ndkConfig.ignoreRelays,
          seedRelays: ndkConfig.bootstrapRelays,
          globalState: globalState,
        );
}
