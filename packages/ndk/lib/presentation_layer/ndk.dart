import 'package:meta/meta.dart';

import '../data_layer/repositories/cache_manager/mem_cache_manager.dart';
import '../data_layer/repositories/verifiers/bip340_event_verifier.dart';
import '../domain_layer/entities/global_state.dart';
import '../domain_layer/usecases/broadcast/broadcast.dart';
import '../domain_layer/usecases/follows/follows.dart';
import '../domain_layer/usecases/lists/lists.dart';
import '../domain_layer/usecases/metadatas/metadatas.dart';
import '../domain_layer/usecases/nip05/verify_nip_05.dart';
import '../domain_layer/usecases/nwc/nwc.dart';
import '../domain_layer/usecases/relay_manager.dart';
import '../domain_layer/usecases/relay_sets/relay_sets.dart';
import '../domain_layer/usecases/requests/requests.dart';
import '../domain_layer/usecases/user_relay_lists/user_relay_lists.dart';
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

  /// Nostr Wallet connect
  @experimental
  Nwc get nwc => _initialization.nwc;

  /// Zaps
  @experimental
  Zaps get zaps => _initialization.zaps;

  /// Close all transports on relay manager
  Future<void> destroy() async {
    await nwc.disconnectAll();
    await _initialization.requests.closeAllSubscription();
    await _initialization.relayManager.closeAllTransports();
  }
}
