import '../config/bootstrap_relays.dart';
import '../config/broadcast_defaults.dart';
import '../config/logger_defaults.dart';
import '../config/request_defaults.dart';
import '../domain_layer/entities/cashu/cashu_user_seedphrase.dart';
import '../domain_layer/entities/event_filter.dart';
import '../domain_layer/repositories/cache_manager.dart';
import '../domain_layer/repositories/event_verifier.dart';
import 'package:logger/logger.dart' as lib_logger;

/// Configuration class for the Nostr Development Kit (NDK)
///
/// This class holds various settings and dependencies required for
/// the NDK to function properly
class NdkConfig {
  /// The verifier used to validate Nostr events. E.g. RustEventVerifier(), Bip340EventVerifier
  EventVerifier eventVerifier;

  /// The cache manager (DB) used to store and retrieve Nostr data. E.g MemCacheManager()
  CacheManager cache;

  /// The engine mode to use for Nostr network operations (inbox/outbox mode).
  ///
  /// Defaults to [NdkEngine.RELAY_SETS].
  NdkEngine engine;

  /// A list of relay URLs to ignore for inbox/outbox operations.
  List<String> ignoreRelays;

  /// A list of initial relay URLs to use for bootstrapping the network.
  /// These connect on start.
  ///
  /// Defaults to [DEFAULT_BOOTSTRAP_RELAYS].
  List<String> bootstrapRelays;

  /// filters that are applied to the output stream
  List<EventFilter> eventOutFilters;

  /// default timeout for queries \
  /// this value is used if no individual timeout is set for a query
  Duration defaultQueryTimeout;

  /// timeout for broadcasts
  Duration defaultBroadcastTimeout;

  /// percentage of relays that need to respond with "OK" for the broadcast to be considered done \
  /// value between 0.0 and 1.0
  double defaultBroadcastConsiderDonePercent;

  /// cashu user seed phrase, required for using cashu features \
  /// you can use CashuSeed.generateSeedPhrase() to generate a new seed phrase \
  /// Store this securely! Seed phrase allow full access to cashu funds!
  final CashuUserSeedphrase? cashuUserSeedphrase;

  /// log level
  lib_logger.Level logLevel;

  /// Creates a new instance of [NdkConfig].
  ///
  /// [eventVerifier] The verifier used to validate Nostr events. \
  /// [cache] The cache manager for storing and retrieving Nostr data. \
  /// [engine] The engine mode to use (defaults to RELAY_SETS). \
  /// [ignoreRelays] A list of relay URLs to ignore (defaults to an empty list). \
  /// [bootstrapRelays] A list of initial relay URLs (defaults to DEFAULT_BOOTSTRAP_RELAYS). \
  /// [eventOutFilters] A list of filters to apply to the output stream (defaults to an empty list). \
  /// [defaultQueryTimeout] The default timeout for queries (defaults to DEFAULT_QUERY_TIMEOUT). \
  /// [logLevel] The log level for the NDK (defaults to warning).
  /// [cashuUserSeedphrase] The cashu user seed phrase, required for using cashu features
  NdkConfig({
    required this.eventVerifier,
    required this.cache,
    this.engine = NdkEngine.RELAY_SETS,
    this.ignoreRelays = const [],
    this.bootstrapRelays = DEFAULT_BOOTSTRAP_RELAYS,
    this.eventOutFilters = const [],
    this.defaultQueryTimeout = RequestDefaults.DEFAULT_QUERY_TIMEOUT,
    this.defaultBroadcastTimeout = BroadcastDefaults.TIMEOUT,
    this.defaultBroadcastConsiderDonePercent =
        BroadcastDefaults.CONSIDER_DONE_PERCENT,
    this.logLevel = defaultLogLevel,
    this.cashuUserSeedphrase,
  });
}

/// Enum representing different engine modes for Nostr network operations.
enum NdkEngine {
  /// Uses relay sets for network operations.
  // ignore: constant_identifier_names
  RELAY_SETS,

  /// Uses Just-In-Time (JIT) mode for network operations.
  // ignore: constant_identifier_names
  JIT
}
