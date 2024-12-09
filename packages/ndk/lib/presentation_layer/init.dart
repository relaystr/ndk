import 'package:http/http.dart' as http;

import '../data_layer/data_sources/http_request.dart';
import '../data_layer/repositories/nip_05_http_impl.dart';
import '../data_layer/repositories/nostr_transport/websocket_nostr_transport_factory.dart';
import '../domain_layer/entities/global_state.dart';
import '../domain_layer/entities/jit_engine_relay_connectivity_data.dart';
import '../domain_layer/repositories/nip_05_repo.dart';
import '../domain_layer/usecases/broadcast/broadcast.dart';
import '../domain_layer/usecases/cache_read/cache_read.dart';
import '../domain_layer/usecases/cache_write/cache_write.dart';
import '../domain_layer/usecases/engines/network_engine.dart';
import '../domain_layer/usecases/follows/follows.dart';
import '../domain_layer/usecases/jit_engine.dart';
import '../domain_layer/usecases/lists/lists.dart';
import '../domain_layer/usecases/metadatas/metadatas.dart';
import '../domain_layer/usecases/nip05/verify_nip_05.dart';
import '../domain_layer/usecases/relay_manager_light.dart';
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

  final HttpRequestDS _httpRequestDS = HttpRequestDS(http.Client());

  /// repositories with no dependencies

  final WebSocketNostrTransportFactory _webSocketNostrTransportFactory =
      WebSocketNostrTransportFactory();

  /// state obj

  /// use cases

  late RelayManagerLight relayManagerLight;
  late CacheWrite cacheWrite;
  late CacheRead cacheRead;
  late Requests requests;
  late Follows follows;
  late Metadatas metadatas;
  late UserRelayLists userRelayLists;
  late Lists lists;
  late RelaySets relaySets;
  late Broadcast broadcast;

  late VerifyNip05 verifyNip05;

  late final NetworkEngine engine;

  /// [NdkConfig] is user defined
  /// [GlobalState] global state object that schuld stay in memory
  Initialization({
    required this.ndkConfig,
    required this.globalState,
  }) {
    switch (ndkConfig.engine) {
      case NdkEngine.RELAY_SETS:
        relayManagerLight = RelayManagerLight(
          globalState: globalState,
          nostrTransportFactory: _webSocketNostrTransportFactory,
          bootstrapRelays: ndkConfig.bootstrapRelays,
        );

        engine = RelaySetsEngine(
          cacheManager: ndkConfig.cache,
          globalState: globalState,
          relayManager: relayManagerLight,
          bootstrapRelays: ndkConfig.bootstrapRelays,
        );
        break;
      case NdkEngine.JIT:
        relayManagerLight = RelayManagerLight<JitEngineRelayConnectivityData>(
          globalState: globalState,
          nostrTransportFactory: _webSocketNostrTransportFactory,
          bootstrapRelays: ndkConfig.bootstrapRelays,
          engineAdditionalDataFactory: JitEngineRelayConnectivityDataFactory(),
        );

        engine = JitEngine(
          eventSigner: ndkConfig.eventSigner,
          cache: ndkConfig.cache,
          ignoreRelays: ndkConfig.ignoreRelays,
          relayManagerLight: relayManagerLight,
          globalState: globalState,
        );
        break;
      default:
        throw UnimplementedError("Unknown engine");
    }

    /// repositories
    final Nip05Repository nip05repository =
        Nip05HttpRepositoryImpl(httpDS: _httpRequestDS);

    ///   use cases
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
      broadcast: broadcast,
      signer: ndkConfig.eventSigner,
    );

    metadatas = Metadatas(
      requests: requests,
      cacheManager: ndkConfig.cache,
      broadcast: broadcast,
      signer: ndkConfig.eventSigner,
    );

    userRelayLists = UserRelayLists(
      requests: requests,
      cacheManager: ndkConfig.cache,
      broadcast: broadcast,
      signer: ndkConfig.eventSigner,
    );

    lists = Lists(
      requests: requests,
      cacheManager: ndkConfig.cache,
      broadcast: broadcast,
      eventSigner: ndkConfig.eventSigner,
    );

    relaySets = RelaySets(
      cacheManager: ndkConfig.cache,
      userRelayLists: userRelayLists,
      relayManager: relayManagerLight,
      blockedRelays: globalState.blockedRelays,
    );

    verifyNip05 = VerifyNip05(
      database: ndkConfig.cache,
      nip05Repository: nip05repository,
    );
  }
}
