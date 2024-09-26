import '../config/bootstrap_relays.dart';
import '../domain_layer/repositories/cache_manager.dart';
import '../domain_layer/repositories/event_signer.dart';
import '../domain_layer/repositories/event_verifier.dart';

/// Configuration class for the Nostr Development Kit (NDK)
///
/// This class holds various settings and dependencies required for
/// the NDK to function properly
class NdkConfig {
  /// The verifier used to validate Nostr events. E.g. RustEventVerifier(), Bip340EventVerifier
  EventVerifier eventVerifier;

  /// The signer used to sign Nostr events.
  ///
  /// This can be null if event signing is not required.
  EventSigner? eventSigner;

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

  /// Creates a new instance of [NdkConfig].
  ///
  /// [eventVerifier] The verifier used to validate Nostr events.
  /// [eventSigner] Optional signer used to sign Nostr events.
  /// [cache] The cache manager for storing and retrieving Nostr data.
  /// [engine] The engine mode to use (defaults to RELAY_SETS).
  /// [ignoreRelays] A list of relay URLs to ignore (defaults to an empty list).
  /// [bootstrapRelays] A list of initial relay URLs (defaults to DEFAULT_BOOTSTRAP_RELAYS).
  NdkConfig({
    required this.eventVerifier,
    this.eventSigner,
    required this.cache,
    this.engine = NdkEngine.RELAY_SETS,
    this.ignoreRelays = const [],
    this.bootstrapRelays = DEFAULT_BOOTSTRAP_RELAYS,
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
