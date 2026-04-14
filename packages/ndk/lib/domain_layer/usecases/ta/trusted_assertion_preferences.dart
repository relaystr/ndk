import 'dart:convert';

import '../../../shared/logger/logger.dart';
import '../../../shared/nips/nip01/helpers.dart';
import '../../entities/filter.dart';
import '../../entities/nip_01_event.dart';
import '../../entities/nip_85.dart';
import '../../entities/trusted_assertion_preferences.dart';
import '../../repositories/cache_manager.dart';
import '../../repositories/event_signer.dart';
import '../accounts/accounts.dart';
import '../broadcast/broadcast.dart';
import '../relay_manager.dart';
import '../requests/requests.dart';
import '../user_relay_lists/user_relay_lists.dart';

/// Duration after which we consider cached preferences stale and refresh
const Duration _refreshPreferencesDuration = Duration(hours: 6);

/// Manages the user's trusted assertion preferences (kind 10040).
///
/// This usecase handles fetching, caching, and updating the user's kind 10040 event,
/// which declares their trusted service providers for NIP-85 assertions.
///
/// The kind 10040 event can store providers in two ways:
/// 1. Public tags (readable by anyone)
/// 2. Encrypted content (private, NIP-44 encrypted with user's own public key)
class TrustedAssertionPrefsUsecase {
  final Requests _requests;
  final CacheManager _cacheManager;
  final Broadcast _broadcast;
  final Accounts _accounts;
  final UserRelayLists _userRelayLists;
  final RelayManager _relayManager;

  TrustedAssertionPrefsUsecase({
    required Requests requests,
    required CacheManager cacheManager,
    required Broadcast broadcast,
    required Accounts accounts,
    required UserRelayLists userRelayLists,
    required RelayManager relayManager,
  })  : _requests = requests,
        _cacheManager = cacheManager,
        _broadcast = broadcast,
        _accounts = accounts,
        _userRelayLists = userRelayLists,
        _relayManager = relayManager;

  EventSigner get _signer {
    if (_accounts.isNotLoggedIn) {
      throw "cannot access preferences without a signer";
    }
    return _accounts.getLoggedAccount()!.signer;
  }

  /// Fetches the user's trusted assertion preferences from cache or network.
  ///
  /// [pubKey] - The public key of the user. If null, uses the logged-in user.
  /// [forceRefresh] - Force refresh from network even if cached.
  ///
  /// Returns [TrustedAssertionPreferences] or null if not found.
  Future<TrustedAssertionPreferences?> getPreferences({
    String? pubKey,
    bool forceRefresh = false,
  }) async {
    final targetPubKey = pubKey ?? _signer.getPublicKey();

    if (!forceRefresh) {
      final cached =
          await _cacheManager.loadTrustedAssertionPreferences(targetPubKey);
      if (cached != null) {
        final sometimeAgo = DateTime.now()
                .subtract(_refreshPreferencesDuration)
                .millisecondsSinceEpoch ~/
            1000;
        if (cached.createdAt >= sometimeAgo) {
          return cached;
        }
      }
    }

    try {
      TrustedAssertionPreferences? latest;

      await for (final event in _requests
          .query(
            name: "trusted-assertion-preferences",
            filter: Filter(
              authors: [targetPubKey],
              kinds: [kTrustedAssertionPreferencesKind],
              limit: 1,
            ),
            cacheRead: true,
            cacheWrite: true,
          )
          .stream) {
        final prefs = await _parsePreferencesEvent(event);
        if (prefs != null &&
            (latest == null || prefs.createdAt > latest.createdAt)) {
          latest = prefs;
        }
      }

      if (latest != null) {
        await _cacheManager.saveTrustedAssertionPreferences(latest);
      }

      return latest;
    } catch (e) {
      Logger.log.w(() => "Error fetching trusted assertion preferences: $e");
      return null;
    }
  }

  /// Ensures the preferences are up-to-date, refreshing if stale.
  /// Used internally before write operations.
  Future<TrustedAssertionPreferences?> _ensureUpToDate() async {
    final pubKey = _signer.getPublicKey();
    return getPreferences(pubKey: pubKey, forceRefresh: true);
  }

  /// Parses a kind 10040 event into [TrustedAssertionPreferences].
  ///
  /// If the content is encrypted (non-empty), attempts to decrypt it
  /// using NIP-44 with the signer to extract private providers.
  /// Returns preferences with both public (from tags) and private (decrypted)
  /// providers merged.
  Future<TrustedAssertionPreferences?> _parsePreferencesEvent(
      Nip01Event event) async {
    final base = TrustedAssertionPreferences.fromEvent(event);
    if (base == null) return null;

    final privateProviders = <Nip85TrustedProvider>[];

    // If content exists, try to decrypt and extract private providers
    if (base.hasEncryptedContent && _signer.canSign()) {
      try {
        final decryptedJson = await _signer.decryptNip44(
          ciphertext: base.encryptedContent!,
          senderPubKey: _signer.getPublicKey(),
        );

        if (decryptedJson != null) {
          final List<dynamic> tags = jsonDecode(decryptedJson);
          for (final tag in tags) {
            if (tag is List) {
              final provider = Nip85TrustedProvider.fromTag(
                  tag.map((e) => e.toString()).toList());
              if (provider != null) {
                privateProviders.add(provider);
              }
            }
          }
        }
      } catch (e) {
        Logger.log.w(() => "Failed to decrypt kind 10040 content: $e");
      }
    }

    // Return with both public and private providers
    return TrustedAssertionPreferences(
      pubKey: base.pubKey,
      id: base.id,
      createdAt: base.createdAt,
      publicProviders: base.publicProviders,
      privateProviders: privateProviders,
      encryptedContent: base.encryptedContent,
    );
  }

  /// Broadcasts an update to the user's trusted assertion preferences.
  ///
  /// [publicProviders] - Providers stored in public tags (visible to anyone).
  /// [privateProviders] - Providers stored encrypted in content (NIP-44, only visible to user).
  /// [broadcastRelays] - Specific relays to broadcast to. If null, uses user's NIP-65 relays or connected relays.
  ///
  /// Returns the updated preferences or null if broadcast failed.
  Future<TrustedAssertionPreferences?> updatePreferences({
    List<Nip85TrustedProvider> publicProviders = const [],
    List<Nip85TrustedProvider> privateProviders = const [],
    Iterable<String>? broadcastRelays,
  }) async {
    // Ensure we have current state before updating
    await _ensureUpToDate();

    final now = Helpers.now;
    String content = '';
    final tags = publicProviders.map((p) => p.toTag()).toList();

    // Encrypt private providers into content using NIP-44
    if (privateProviders.isNotEmpty) {
      final tagsJson =
          jsonEncode(privateProviders.map((p) => p.toTag()).toList());
      final encryptedContent = await _signer.encryptNip44(
        plaintext: tagsJson,
        recipientPubKey: _signer.getPublicKey(),
      );

      if (encryptedContent == null) {
        Logger.log.w(() => "Failed to encrypt kind 10040 content");
        return null;
      }

      content = encryptedContent;
    }

    if (publicProviders.isEmpty && privateProviders.isEmpty) {
      Logger.log.w(() => "No providers to save. Both public and private lists are empty.");
    }

    // Create unsigned event, then sign it
    final unsignedEvent = Nip01Event(
      pubKey: _signer.getPublicKey(),
      kind: kTrustedAssertionPreferencesKind,
      tags: tags,
      content: content,
      createdAt: now,
    );

    final event = await _signer.sign(unsignedEvent);

    // Broadcast to user's NIP-65 relays, or fallback to connected relays
    final userRelayList =
        await _userRelayLists.getSingleUserRelayList(_signer.getPublicKey());
    List<String> targetRelays;

    if (broadcastRelays != null) {
      targetRelays = broadcastRelays.toList();
    } else if (userRelayList != null && userRelayList.relays.isNotEmpty) {
      targetRelays = userRelayList.relays.keys.toList();
    } else {
      // Fallback to connected relays
      targetRelays = _relayManager.connectedRelays.map((r) => r.url).toList();
    }

    if (targetRelays.isEmpty) {
      Logger.log.w(
          () => "No relays available to broadcast kind 10040. Connect to at least one relay first.");
      return null;
    }

    final broadcastResponse = _broadcast.broadcast(
      nostrEvent: event,
      specificRelays: targetRelays,
    );

    await broadcastResponse.broadcastDoneFuture;

    final prefs = TrustedAssertionPreferences(
      pubKey: event.pubKey,
      id: event.id,
      createdAt: now,
      publicProviders: publicProviders,
      privateProviders: privateProviders,
      encryptedContent: privateProviders.isNotEmpty ? content : null,
    );

    await _cacheManager.saveTrustedAssertionPreferences(prefs);

    return prefs;
  }

  /// Adds a provider to the user's trusted assertion preferences.
  ///
  /// [provider] - The provider to add.
  /// [private] - Whether the provider should be private (encrypted). Defaults to false.
  /// [broadcastRelays] - Specific relays to broadcast to. If null, uses user's NIP-65 relays or connected relays.
  ///
  /// Returns the updated preferences or null if broadcast failed.
  Future<TrustedAssertionPreferences?> addProvider({
    required Nip85TrustedProvider provider,
    bool private = false,
    Iterable<String>? broadcastRelays,
  }) async {
    final current = await _ensureUpToDate();
    if (current == null) {
      // No existing preferences, create new with just this provider
      if (private) {
        return updatePreferences(
          privateProviders: [provider],
          broadcastRelays: broadcastRelays,
        );
      } else {
        return updatePreferences(
          publicProviders: [provider],
          broadcastRelays: broadcastRelays,
        );
      }
    }

    // Check if provider already exists (in either public or private)
    final allCurrentProviders = current.allProviders;
    final alreadyExists = allCurrentProviders.any(
      (p) =>
          p.kind == provider.kind &&
          p.metric == provider.metric &&
          p.pubkey == provider.pubkey &&
          p.relay == provider.relay,
    );
    if (alreadyExists) {
      return current;
    }

    // Build new lists, preserving existing public/private split
    // If a provider exists in the wrong list (e.g. was public, now marked private),
    // remove it from old list and add to new list
    final newPublicProviders = current.publicProviders
        .where((p) =>
            !(p.kind == provider.kind &&
                p.metric == provider.metric &&
                p.pubkey == provider.pubkey &&
                p.relay == provider.relay))
        .toList();
    final newPrivateProviders = current.privateProviders
        .where((p) =>
            !(p.kind == provider.kind &&
                p.metric == provider.metric &&
                p.pubkey == provider.pubkey &&
                p.relay == provider.relay))
        .toList();

    if (private) {
      newPrivateProviders.add(provider);
    } else {
      newPublicProviders.add(provider);
    }

    return updatePreferences(
      publicProviders: newPublicProviders,
      privateProviders: newPrivateProviders,
      broadcastRelays: broadcastRelays,
    );
  }

  /// Removes a provider from the user's trusted assertion preferences.
  ///
  /// [provider] - The provider to remove.
  /// [broadcastRelays] - Specific relays to broadcast to. If null, uses user's NIP-65 relays or connected relays.
  ///
  /// Returns the updated preferences or null if broadcast failed.
  Future<TrustedAssertionPreferences?> removeProvider({
    required Nip85TrustedProvider provider,
    Iterable<String>? broadcastRelays,
  }) async {
    final current = await _ensureUpToDate();
    if (current == null) {
      return null;
    }

    final newPublicProviders = current.publicProviders.where((p) {
      return !(p.kind == provider.kind &&
          p.metric == provider.metric &&
          p.pubkey == provider.pubkey &&
          p.relay == provider.relay);
    }).toList();

    final newPrivateProviders = current.privateProviders.where((p) {
      return !(p.kind == provider.kind &&
          p.metric == provider.metric &&
          p.pubkey == provider.pubkey &&
          p.relay == provider.relay);
    }).toList();

    if (newPublicProviders.length == current.publicProviders.length &&
        newPrivateProviders.length == current.privateProviders.length) {
      // Provider not found, nothing to remove
      return current;
    }

    return updatePreferences(
      publicProviders: newPublicProviders,
      privateProviders: newPrivateProviders,
      broadcastRelays: broadcastRelays,
    );
  }

  /// Sets a provider's visibility (public vs private).
  ///
  /// Moves the provider between public tags and encrypted content.
  /// [provider] - The provider to update.
  /// [private] - Whether the provider should be private (encrypted).
  ///
  /// Returns the updated preferences or null if broadcast failed.
  Future<TrustedAssertionPreferences?> setProviderVisibility({
    required Nip85TrustedProvider provider,
    required bool private,
  }) async {
    final current = await _ensureUpToDate();
    if (current == null) return null;

    // Remove from both lists
    final newPublicProviders = current.publicProviders.where((p) {
      return !(p.kind == provider.kind &&
          p.metric == provider.metric &&
          p.pubkey == provider.pubkey &&
          p.relay == provider.relay);
    }).toList();
    final newPrivateProviders = current.privateProviders.where((p) {
      return !(p.kind == provider.kind &&
          p.metric == provider.metric &&
          p.pubkey == provider.pubkey &&
          p.relay == provider.relay);
    }).toList();

    // Add to the correct list
    if (private) {
      newPrivateProviders.add(provider);
    } else {
      newPublicProviders.add(provider);
    }

    return updatePreferences(
      publicProviders: newPublicProviders,
      privateProviders: newPrivateProviders,
    );
  }

  /// Gets providers for a specific kind and metric.
  ///
  /// [kind] - The NIP-85 event kind (e.g., 30382 for user metrics).
  /// [metric] - The specific metric to filter by.
  /// [pubKey] - The public key of the user. If null, uses the logged-in user.
  ///
  /// Returns a list of matching providers, empty if none found.
  Future<List<Nip85TrustedProvider>> getProvidersForKindAndMetric({
    required int kind,
    required Nip85Metric metric,
    String? pubKey,
  }) async {
    final prefs = await getPreferences(pubKey: pubKey);
    if (prefs == null) return [];

    return prefs.filterProviders(
      kind: kind,
      metrics: {metric},
    );
  }

  /// Gets all providers for a specific kind.
  ///
  /// [kind] - The NIP-85 event kind (e.g., 30382 for user metrics).
  /// [pubKey] - The public key of the user. If null, uses the logged-in user.
  ///
  /// Returns a list of matching providers, empty if none found.
  Future<List<Nip85TrustedProvider>> getProvidersForKind({
    required int kind,
    String? pubKey,
  }) async {
    final prefs = await getPreferences(pubKey: pubKey);
    if (prefs == null) return [];

    return prefs.filterProviders(kind: kind);
  }

  /// Reads the latest cached trusted assertion preferences from cache.
  ///
  /// [pubKey] - The public key to get preferences for.
  /// [cacheManager] - The cache manager to use.
  ///
  /// Returns cached preferences or null if not found.
  static Future<TrustedAssertionPreferences?> getPreferencesCacheLatest({
    required String pubKey,
    required CacheManager cacheManager,
  }) async {
    return cacheManager.loadTrustedAssertionPreferences(pubKey);
  }
}
