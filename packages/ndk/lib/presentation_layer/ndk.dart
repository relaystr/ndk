import 'package:meta/meta.dart';

import '../data_layer/repositories/cache_manager/mem_cache_manager.dart';
import '../data_layer/repositories/cashu_seed_secret_generator/fake_cashu_seed_generator.dart';
import '../data_layer/repositories/verifiers/bip340_event_verifier.dart';
import '../domain_layer/entities/global_state.dart';
import '../domain_layer/usecases/accounts/accounts.dart';
import '../domain_layer/usecases/broadcast/broadcast.dart';
import '../domain_layer/usecases/bunkers/bunkers.dart';
import '../domain_layer/usecases/cashu/cashu.dart';
import '../domain_layer/usecases/connectivity/connectivity.dart';
import '../domain_layer/usecases/fetched_ranges/fetched_ranges.dart';
import '../domain_layer/usecases/files/blossom.dart';
import '../domain_layer/usecases/files/blossom_user_server_list.dart';
import '../domain_layer/usecases/files/files.dart';
import '../domain_layer/usecases/follows/follows.dart';
import '../domain_layer/usecases/gift_wrap/gift_wrap.dart';
import '../domain_layer/usecases/lists/lists.dart';
import '../domain_layer/usecases/metadatas/metadatas.dart';
import '../domain_layer/usecases/nip05/verify_nip_05.dart';
import '../domain_layer/usecases/nwc/nwc.dart';
import '../domain_layer/usecases/proof_of_work/proof_of_work.dart';
import '../domain_layer/usecases/relay_manager.dart';
import '../domain_layer/usecases/relay_sets/relay_sets.dart';
import '../domain_layer/usecases/requests/requests.dart';
import '../domain_layer/usecases/search/search.dart';
import '../domain_layer/usecases/user_relay_lists/user_relay_lists.dart';
import '../domain_layer/usecases/wallets/wallets.dart';
import '../domain_layer/usecases/zaps/zaps.dart';
import 'init.dart';
import 'ndk_config.dart';

/// Main entry point for the NDK (Nostr Development Kit) library.
///
/// This file contains the primary class [Ndk] which provides access to various
/// Nostr-related functionalities/usecases and manages the global state of the application.
class Ndk {
  /// Configuration for the NDK instance
  final NdkConfig config;

  /// Global state shared across the application
  static final GlobalState _globalState = GlobalState();

  /// Internal initialization object for setting up repositories and usecases
  final Initialization _initialization;

  /// Creates a new instance of [Ndk] with the given [config]
  Ndk(this.config)
      : _initialization = Initialization(
          ndkConfig: config,
          globalState: _globalState,
        );

  /// Creates a new instance of [Ndk] with default configuration
  Ndk.defaultConfig()
      : this(
          NdkConfig(
            cache: MemCacheManager(),
            eventVerifier: Bip340EventVerifier(),
          ),
        );

  /// Creates a new instance of [Ndk] with default configuration and empty bootstrap relays
  Ndk.emptyBootstrapRelaysConfig()
      : this(
          NdkConfig(
            cache: MemCacheManager(),
            eventVerifier: Bip340EventVerifier(),
            bootstrapRelays: [],
          ),
        );

  /// Provides access to low-level Nostr requests.
  ///
  /// Use this to directly query or subscribe to notes from the Nostr network. \
  /// Available methods include query() and subscription()
  Requests get requests => _initialization.requests;

  /// Accounts
  Accounts get accounts => _initialization.accounts;

  /// Bunker - NIP-46 remote signing protocol
  Bunkers get bunkers => _initialization.bunkers;

  /// Provides access to low-level Nostr broadcast/publish.
  ///
  /// high level broadcast operations like updating lists, etc are already included in the specific usecases
  Broadcast get broadcast => _initialization.broadcast;

  /// Relay Manager
  RelayManager get relays => _initialization.relayManager;

  /// Handles operations related to user follows
  ///
  /// Use getContactList() to retrieve contact lists
  Follows get follows => _initialization.follows;

  /// user metadata operations
  Metadatas get metadata => _initialization.metadatas;

  /// user relay lists usecase \
  /// similar to nip65 but more generic, contact list relays can also be considered
  UserRelayLists get userRelayLists => _initialization.userRelayLists;

  /// Manages various types of lists in the Nostr network
  Lists get lists => _initialization.lists;

  /// calculate relay set
  RelaySets get relaySets => _initialization.relaySets;

  /// Verifies NIP-05 events
  VerifyNip05 get nip05 => _initialization.verifyNip05;

  /// manage files on nostr \
  /// upload, download, delete files \
  /// high level usecase, recommended for most users
  Files get files => _initialization.files;

  /// Blossom usecase \
  /// upload, download, delete, list files \
  /// low level usecase, recommended for advanced users
  Blossom get blossom => _initialization.blossom;

  /// Blossom User Server list \
  /// used to manage the list of blossom servers for a user \
  /// low level usecase, recommended for advanced users
  BlossomUserServerList get blossomUserServerList =>
      _initialization.blossomUserServerList;

  /// Gift wrap - NIP-59 \
  /// crate gift wraps \
  /// unwrap gift wraps \
  ///
  /// low level usecase, recommended for advanced users
  GiftWrap get giftWrap => _initialization.giftWrap;

  /// Use case for managing relay connectivity \
  /// get notified about relay connectivity changes \
  /// and update NDK about your application connectivity \
  /// for faster reconnects
  Connectivy get connectivity => _initialization.connectivity;

  ProofOfWork get proofOfWork => _initialization.proofOfWork;

  /// Nostr Wallet connect
  @experimental // needs more docs & tests
  Nwc get nwc => _initialization.nwc;

  /// Zaps
  @experimental // needs more docs & tests
  Zaps get zaps => _initialization.zaps;

  /// Search
  @experimental
  Search get search => _initialization.search;

  /// Cashu Wallet
  @experimental // in development
  Cashu get cashu => _initialization.cashu;

  /// Wallet combining all wallet accounts \
  @experimental
  Wallets get wallets => _initialization.wallets;

  /// Fetched ranges tracking
  /// Track which time ranges have been fetched from which relays for each filter
  @experimental
  FetchedRanges get fetchedRanges => _initialization.fetchedRanges;

  /// Close all transports on relay manager
  Future<void> destroy() async {
    final allFutures = [
      nwc.disconnectAll(),
      _initialization.requests.closeAllSubscription(),
      _initialization.relayManager.closeAllTransports(),
      _initialization.requests.closeAllSubscription(),
      accounts.dispose(),
    ];

    await Future.wait(allFutures);
  }
}
