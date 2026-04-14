import '../entities/nip_01_event.dart';
import '../entities/nip_85.dart';

/// Kind 10040 constant for Trusted Assertion Preferences
/// This is a replaceable event that stores the user's authorized providers
/// for each NIP-85 metric.
const int kTrustedAssertionPreferencesKind = 10040;

/// Holds the user's trusted assertion preferences (kind 10040).
///
/// Supports mixed public/private providers:
/// - **Public providers** are stored in the event's tags (visible to anyone)
/// - **Private providers** are NIP-44 encrypted in the content (only readable by the user)
///
/// Tag format: `["<kind:metric>", "<service_pubkey>", "<relay_hint>"]`
/// Example: `["30382:rank", "4fd5e210...", "wss://nip85.nostr.band"]`
class TrustedAssertionPreferences {
  /// The public key of the user who owns these preferences
  final String pubKey;

  /// The event ID
  final String id;

  /// When the event was created (unix timestamp)
  final int createdAt;

  /// Public providers (from tags, visible to anyone)
  final List<Nip85TrustedProvider> publicProviders;

  /// Private providers (decrypted from NIP-44 content, only visible to the user)
  final List<Nip85TrustedProvider> privateProviders;

  /// The raw encrypted content (if any private providers exist)
  final String? encryptedContent;

  /// Merged list of all providers (public + private).
  /// Private providers come after public providers.
  List<Nip85TrustedProvider> get allProviders => [
        ...publicProviders,
        ...privateProviders,
      ];

  /// Backwards-compatible getter alias for allProviders
  List<Nip85TrustedProvider> get providers => allProviders;

  /// Whether this event has any encrypted content
  bool get hasEncryptedContent => encryptedContent != null;

  /// Whether this event has any private providers
  bool get hasPrivateProviders => privateProviders.isNotEmpty;

  /// Whether this event has any public providers
  bool get hasPublicProviders => publicProviders.isNotEmpty;

  TrustedAssertionPreferences({
    required this.pubKey,
    required this.id,
    required this.createdAt,
    this.publicProviders = const [],
    this.privateProviders = const [],
    this.encryptedContent,
  });

  /// Creates a [TrustedAssertionPreferences] from a kind 10040 event.
  ///
  /// Only parses public providers from tags. Private providers require
  /// decryption with the signer (handled by [TrustedAssertionPrefsUsecase]).
  static TrustedAssertionPreferences? fromEvent(Nip01Event event) {
    if (event.kind != kTrustedAssertionPreferencesKind) return null;

    final publicProviders = <Nip85TrustedProvider>[];
    for (final tag in event.tags) {
      final provider = Nip85TrustedProvider.fromTag(tag);
      if (provider != null) {
        publicProviders.add(provider);
      }
    }

    return TrustedAssertionPreferences(
      pubKey: event.pubKey,
      id: event.id,
      createdAt: event.createdAt,
      publicProviders: publicProviders,
      privateProviders: [],
      encryptedContent:
          event.content.isNotEmpty ? event.content : null,
    );
  }

  /// Filters providers by kind and optionally by metrics.
  /// Searches both public and private providers.
  List<Nip85TrustedProvider> filterProviders({
    required int kind,
    Set<Nip85Metric>? metrics,
  }) {
    return allProviders.where((p) {
      if (p.kind != kind) return false;
      if (metrics != null && metrics.isNotEmpty) {
        return metrics.contains(p.metric);
      }
      return true;
    }).toList();
  }

  /// Returns all providers for a specific kind.
  List<Nip85TrustedProvider> getProvidersForKind(int kind) {
    return filterProviders(kind: kind);
  }

  /// Returns providers for a specific kind and metric combination.
  List<Nip85TrustedProvider> getProvidersForKindAndMetric(
    int kind,
    Nip85Metric metric,
  ) {
    return filterProviders(kind: kind, metrics: {metric});
  }
}
