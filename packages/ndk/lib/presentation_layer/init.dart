import 'package:http/http.dart' as http;
import '../config/request_defaults.dart';
import '../data_layer/repositories/nostr_transport/websocket_nostr_transport_factory.dart';
import '../shared/net/user_agent.dart';

import '../data_layer/data_sources/http_request.dart';
import '../data_layer/repositories/blossom/blossom_impl.dart';
import '../data_layer/repositories/lnurl_http_impl.dart';
import '../data_layer/repositories/nip_05_http_impl.dart';
import '../data_layer/repositories/nostr_transport/websocket_client_nostr_transport_factory.dart';
import '../domain_layer/entities/global_state.dart';
import '../domain_layer/entities/jit_engine_relay_connectivity_data.dart';
import '../domain_layer/repositories/blossom.dart';
import '../domain_layer/repositories/lnurl_transport.dart';
import '../domain_layer/repositories/nip_05_repo.dart';
import '../domain_layer/usecases/accounts/accounts.dart';
import '../domain_layer/usecases/broadcast/broadcast.dart';
import '../domain_layer/usecases/cache_read/cache_read.dart';
import '../domain_layer/usecases/cache_write/cache_write.dart';
import '../domain_layer/usecases/connectivity/connectivity.dart';
import '../domain_layer/usecases/engines/network_engine.dart';
import '../domain_layer/usecases/files/blossom.dart';
import '../domain_layer/usecases/files/blossom_user_server_list.dart';
import '../domain_layer/usecases/files/files.dart';
import '../domain_layer/usecases/follows/follows.dart';
import '../domain_layer/usecases/gift_wrap/gift_wrap.dart';
import '../domain_layer/usecases/jit_engine/jit_engine.dart';
import '../domain_layer/usecases/lists/lists.dart';
import '../domain_layer/usecases/lnurl/lnurl.dart';
import '../domain_layer/usecases/metadatas/metadatas.dart';
import '../domain_layer/usecases/nip05/verify_nip_05.dart';
import '../domain_layer/usecases/nwc/nwc.dart';
import '../domain_layer/usecases/relay_manager.dart';
import '../domain_layer/usecases/relay_sets/relay_sets.dart';
import '../domain_layer/usecases/relay_sets_engine.dart';
import '../domain_layer/usecases/requests/requests.dart';
import '../domain_layer/usecases/search/search.dart';
import '../domain_layer/usecases/user_relay_lists/user_relay_lists.dart';
import '../domain_layer/usecases/zaps/zaps.dart';
import '../shared/logger/logger.dart';
import 'ndk_config.dart';

/// this class is used to inject all the dependencies \
/// its like playing lego ;)
class Initialization {
  final NdkConfig _ndkConfig;
  final GlobalState _globalState;

  /// data sources

  final HttpRequestDS _httpRequestDS = HttpRequestDS(http.Client());

  /// repositories with no dependencies

  final _webSocketNostrTransportFactory =
      WebSocketClientNostrTransportFactory();

  /// state obj

  /// use cases

  late RelayManager relayManager;
  late CacheWrite cacheWrite;
  late CacheRead cacheRead;
  late Requests requests;
  late Accounts accounts;
  late Follows follows;
  late Metadatas metadatas;
  late UserRelayLists userRelayLists;
  late Lists lists;
  late RelaySets relaySets;
  late Broadcast broadcast;
  late Nwc nwc;
  late Zaps zaps;
  late Lnurl lnurl;
  late Files files;
  late Blossom blossom;
  late BlossomUserServerList blossomUserServerList;
  late Search search;
  late GiftWrap giftWrap;
  late Connectivy connectivity;

  late VerifyNip05 verifyNip05;

  late final NetworkEngine engine;

  /// [NdkConfig] is user defined
  /// [GlobalState] global state object that schuld stay in memory
  Initialization({
    required NdkConfig ndkConfig,
    required GlobalState globalState,
  })  : _globalState = globalState,
        _ndkConfig = ndkConfig {
    // Configure global WebSocket User-Agent on dart:io platforms
    configureDefaultUserAgent(ndkConfig.userAgent);

    accounts = Accounts();

    switch (_ndkConfig.engine) {
      case NdkEngine.RELAY_SETS:
        relayManager = RelayManager(
          globalState: _globalState,
          accounts: accounts,
          nostrTransportFactory: _webSocketNostrTransportFactory,
          bootstrapRelays: _ndkConfig.bootstrapRelays,
        );

        engine = RelaySetsEngine(
          cacheManager: _ndkConfig.cache,
          globalState: _globalState,
          relayManager: relayManager,
          bootstrapRelays: _ndkConfig.bootstrapRelays,
        );
        break;
      case NdkEngine.JIT:
        relayManager = RelayManager<JitEngineRelayConnectivityData>(
          globalState: _globalState,
          accounts: accounts,
          nostrTransportFactory: _webSocketNostrTransportFactory,
          bootstrapRelays: _ndkConfig.bootstrapRelays,
          engineAdditionalDataFactory: JitEngineRelayConnectivityDataFactory(),
        );

        engine = JitEngine(
          cache: _ndkConfig.cache,
          ignoreRelays: _ndkConfig.ignoreRelays,
          relayManagerLight: relayManager,
          globalState: _globalState,
          bootstrapRelays: _ndkConfig.bootstrapRelays,
        );
        break;
    }

    /// repositories
    final Nip05Repository nip05repository =
        Nip05HttpRepositoryImpl(httpDS: _httpRequestDS);

    final BlossomRepository blossomRepository = BlossomRepositoryImpl(
      client: _httpRequestDS,
    );

    ///   use cases
    cacheWrite = CacheWrite(_ndkConfig.cache);
    cacheRead = CacheRead(_ndkConfig.cache);

    requests = Requests(
      defaultQueryTimeout: _ndkConfig.defaultQueryTimeout,
      globalState: _globalState,
      cacheRead: cacheRead,
      cacheWrite: cacheWrite,
      networkEngine: engine,
      relayManager: relayManager,
      eventVerifier: _ndkConfig.eventVerifier,
      eventOutFilters: _ndkConfig.eventOutFilters,
    );

    broadcast = Broadcast(
      globalState: _globalState,
      networkEngine: engine,
      cacheManager: _ndkConfig.cache,
      accounts: accounts,
      considerDonePercent: _ndkConfig.defaultBroadcastConsiderDonePercent,
      timeout: _ndkConfig.defaultBroadcastTimeout,
    );

    follows = Follows(
      requests: requests,
      cacheManager: _ndkConfig.cache,
      broadcast: broadcast,
      accounts: accounts,
    );

    metadatas = Metadatas(
      requests: requests,
      cacheManager: _ndkConfig.cache,
      broadcast: broadcast,
      accounts: accounts,
    );

    userRelayLists = UserRelayLists(
      requests: requests,
      cacheManager: _ndkConfig.cache,
      broadcast: broadcast,
      accounts: accounts,
    );

    lists = Lists(
      requests: requests,
      cacheManager: _ndkConfig.cache,
      broadcast: broadcast,
      accounts: accounts,
    );

    relaySets = RelaySets(
      cacheManager: _ndkConfig.cache,
      userRelayLists: userRelayLists,
      relayManager: relayManager,
      blockedRelays: _globalState.blockedRelays,
    );

    verifyNip05 = VerifyNip05(
      database: _ndkConfig.cache,
      nip05Repository: nip05repository,
    );

    nwc = Nwc(requests: requests, broadcast: broadcast);

    final LnurlTransport lnurlTransport =
        LnurlTransportHttpImpl(_httpRequestDS);

    lnurl = Lnurl(transport: lnurlTransport);
    zaps = Zaps(
      requests: requests,
      nwc: nwc,
      lnurl: lnurl,
    );

    blossomUserServerList = BlossomUserServerList(
      requests: requests,
      broadcast: broadcast,
      accounts: accounts,
    );

    blossom = Blossom(
      blossomRepository: blossomRepository,
      accounts: accounts,
      blossomUserServerList: blossomUserServerList,
    );

    files = Files(blossom: blossom);

    search = Search(
      cacheManager: _ndkConfig.cache,
      requests: requests,
    );

    giftWrap = GiftWrap(accounts: accounts);

    connectivity = Connectivy(relayManager);

    /// set the user configured log level
    Logger.setLogLevel(_ndkConfig.logLevel);
  }
}
