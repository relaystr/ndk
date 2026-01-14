import 'dart:async';

import '../../entities/filter.dart';
import '../../entities/nip_01_event.dart';
import '../../entities/nip_85.dart';
import '../requests/requests.dart';

/// Trusted Assertions usecase (NIP-85)
///
/// Allows fetching pre-computed metrics from trusted service providers.
class TrustedAssertions {
  final Requests _requests;
  final List<Nip85TrustedProvider> _defaultProviders;

  TrustedAssertions({
    required Requests requests,
    required List<Nip85TrustedProvider> defaultProviders,
  })  : _requests = requests,
        _defaultProviders = defaultProviders;

  /// Filter providers by kind and optionally by metrics
  List<Nip85TrustedProvider> _filterProviders(
    List<Nip85TrustedProvider> providers, {
    required int kind,
    Set<Nip85Metric>? metrics,
  }) {
    return providers.where((p) {
      // Must match the kind
      if (p.kind != kind) return false;
      // If metrics specified, must match one of them
      if (metrics != null && metrics.isNotEmpty) {
        return metrics.contains(p.metric);
      }
      return true;
    }).toList();
  }

  /// Get user metrics from trusted providers
  ///
  /// [pubkey] - The public key of the user to get metrics for
  /// [metrics] - Optional set of specific metrics to fetch. If null, fetches all available.
  /// [providers] - Optional list of providers to use. If null, uses default providers.
  ///
  /// Returns [Nip85UserMetrics] or null if no assertion found.
  Future<Nip85UserMetrics?> getUserMetrics(
    String pubkey, {
    Set<Nip85Metric>? metrics,
    List<Nip85TrustedProvider>? providers,
  }) async {
    final effectiveProviders = _filterProviders(
      providers ?? _defaultProviders,
      kind: Nip85Kind.user,
      metrics: metrics,
    );

    if (effectiveProviders.isEmpty) {
      return null;
    }

    // Group providers by relay for efficient querying
    final providersByRelay = <String, List<Nip85TrustedProvider>>{};
    for (final provider in effectiveProviders) {
      providersByRelay.putIfAbsent(provider.relay, () => []).add(provider);
    }

    Nip85UserMetrics? result;
    int latestCreatedAt = 0;

    // Query each relay
    for (final entry in providersByRelay.entries) {
      final relay = entry.key;
      final relayProviders = entry.value;
      final providerPubkeys = relayProviders.map((p) => p.pubkey).toList();

      try {
        await for (final event in _requests
            .query(
              filter: Filter(
                kinds: [Nip85Kind.user],
                authors: providerPubkeys,
                dTags: [pubkey],
                limit: providerPubkeys.length,
              ),
              explicitRelays: [relay],
              cacheRead: true,
              cacheWrite: true,
            )
            .stream) {
          final parsed = _parseUserMetricsEvent(event, metrics);
          if (parsed != null && parsed.createdAt > latestCreatedAt) {
            result = parsed;
            latestCreatedAt = parsed.createdAt;
          }
        }
      } catch (_) {
        // Continue with other relays if one fails
      }
    }

    return result;
  }

  /// Stream user metrics from trusted providers
  ///
  /// [pubkey] - The public key of the user to get metrics for
  /// [metrics] - Optional set of specific metrics to fetch. If null, fetches all available.
  /// [providers] - Optional list of providers to use. If null, uses default providers.
  ///
  /// Returns a [Stream] of [Nip85UserMetrics] that emits updates as they arrive.
  Stream<Nip85UserMetrics> streamUserMetrics(
    String pubkey, {
    Set<Nip85Metric>? metrics,
    List<Nip85TrustedProvider>? providers,
  }) {
    final effectiveProviders = _filterProviders(
      providers ?? _defaultProviders,
      kind: Nip85Kind.user,
      metrics: metrics,
    );

    final controller = StreamController<Nip85UserMetrics>();

    if (effectiveProviders.isEmpty) {
      controller.close();
      return controller.stream;
    }

    // Group providers by relay
    final providersByRelay = <String, List<Nip85TrustedProvider>>{};
    for (final provider in effectiveProviders) {
      providersByRelay.putIfAbsent(provider.relay, () => []).add(provider);
    }

    // Track subscriptions for cleanup
    final subscriptionIds = <String>[];

    // Subscribe to each relay
    for (final entry in providersByRelay.entries) {
      final relay = entry.key;
      final relayProviders = entry.value;
      final providerPubkeys = relayProviders.map((p) => p.pubkey).toList();

      final response = _requests.subscription(
        filter: Filter(
          kinds: [Nip85Kind.user],
          authors: providerPubkeys,
          dTags: [pubkey],
        ),
        explicitRelays: [relay],
      );

      subscriptionIds.add(response.requestId);

      response.stream.listen(
        (event) {
          final parsed = _parseUserMetricsEvent(event, metrics);
          if (parsed != null) {
            controller.add(parsed);
          }
        },
        onError: (e) {
          // Ignore errors from individual relays
        },
      );
    }

    // Close subscriptions when stream is cancelled
    controller.onCancel = () async {
      for (final id in subscriptionIds) {
        await _requests.closeSubscription(id);
      }
    };

    return controller.stream;
  }

  /// Parse a NIP-85 kind 30382 event into [Nip85UserMetrics]
  Nip85UserMetrics? _parseUserMetricsEvent(
    Nip01Event event,
    Set<Nip85Metric>? requestedMetrics,
  ) {
    if (event.kind != Nip85Kind.user) return null;

    final dTag = event.getDtag();
    if (dTag == null) return null;

    final metricsMap = <Nip85Metric, dynamic>{};
    final topics = <String>[];

    for (final tag in event.tags) {
      if (tag.length < 2) continue;

      final tagName = tag[0];
      final tagValue = tag[1];

      // Handle topic tags
      if (tagName == 't') {
        topics.add(tagValue);
        continue;
      }

      // Try to parse as metric
      final metric = Nip85Metric.fromTagName(tagName);
      if (metric != null) {
        // If specific metrics requested, filter
        if (requestedMetrics != null && !requestedMetrics.contains(metric)) {
          continue;
        }

        // Parse value based on metric type
        final parsedValue = int.tryParse(tagValue);
        if (parsedValue != null) {
          metricsMap[metric] = parsedValue;
        }
      }
    }

    return Nip85UserMetrics(
      pubkey: dTag,
      providerPubkey: event.pubKey,
      createdAt: event.createdAt,
      metrics: metricsMap,
      topics: topics,
    );
  }

  // ===========================================================================
  // EVENT METRICS (kind 30383)
  // ===========================================================================

  /// Get event metrics from trusted providers
  ///
  /// [eventId] - The event ID to get metrics for
  /// [metrics] - Optional set of specific metrics to fetch. If null, fetches all available.
  /// [providers] - Optional list of providers to use. If null, uses default providers.
  ///
  /// Returns [Nip85EventMetrics] or null if no assertion found.
  Future<Nip85EventMetrics?> getEventMetrics(
    String eventId, {
    Set<Nip85Metric>? metrics,
    List<Nip85TrustedProvider>? providers,
  }) async {
    final effectiveProviders = _filterProviders(
      providers ?? _defaultProviders,
      kind: Nip85Kind.event,
      metrics: metrics,
    );

    if (effectiveProviders.isEmpty) {
      return null;
    }

    // Group providers by relay for efficient querying
    final providersByRelay = <String, List<Nip85TrustedProvider>>{};
    for (final provider in effectiveProviders) {
      providersByRelay.putIfAbsent(provider.relay, () => []).add(provider);
    }

    Nip85EventMetrics? result;
    int latestCreatedAt = 0;

    // Query each relay
    for (final entry in providersByRelay.entries) {
      final relay = entry.key;
      final relayProviders = entry.value;
      final providerPubkeys = relayProviders.map((p) => p.pubkey).toList();

      try {
        await for (final event in _requests
            .query(
              filter: Filter(
                kinds: [Nip85Kind.event],
                authors: providerPubkeys,
                dTags: [eventId],
                limit: providerPubkeys.length,
              ),
              explicitRelays: [relay],
              cacheRead: true,
              cacheWrite: true,
            )
            .stream) {
          final parsed = _parseEventMetricsEvent(event, metrics);
          if (parsed != null && parsed.createdAt > latestCreatedAt) {
            result = parsed;
            latestCreatedAt = parsed.createdAt;
          }
        }
      } catch (_) {
        // Continue with other relays if one fails
      }
    }

    return result;
  }

  /// Stream event metrics from trusted providers
  ///
  /// [eventId] - The event ID to get metrics for
  /// [metrics] - Optional set of specific metrics to fetch. If null, fetches all available.
  /// [providers] - Optional list of providers to use. If null, uses default providers.
  ///
  /// Returns a [Stream] of [Nip85EventMetrics] that emits updates as they arrive.
  Stream<Nip85EventMetrics> streamEventMetrics(
    String eventId, {
    Set<Nip85Metric>? metrics,
    List<Nip85TrustedProvider>? providers,
  }) {
    final effectiveProviders = _filterProviders(
      providers ?? _defaultProviders,
      kind: Nip85Kind.event,
      metrics: metrics,
    );

    final controller = StreamController<Nip85EventMetrics>();

    if (effectiveProviders.isEmpty) {
      controller.close();
      return controller.stream;
    }

    // Group providers by relay
    final providersByRelay = <String, List<Nip85TrustedProvider>>{};
    for (final provider in effectiveProviders) {
      providersByRelay.putIfAbsent(provider.relay, () => []).add(provider);
    }

    // Track subscriptions for cleanup
    final subscriptionIds = <String>[];

    // Subscribe to each relay
    for (final entry in providersByRelay.entries) {
      final relay = entry.key;
      final relayProviders = entry.value;
      final providerPubkeys = relayProviders.map((p) => p.pubkey).toList();

      final response = _requests.subscription(
        filter: Filter(
          kinds: [Nip85Kind.event],
          authors: providerPubkeys,
          dTags: [eventId],
        ),
        explicitRelays: [relay],
      );

      subscriptionIds.add(response.requestId);

      response.stream.listen(
        (event) {
          final parsed = _parseEventMetricsEvent(event, metrics);
          if (parsed != null) {
            controller.add(parsed);
          }
        },
        onError: (e) {
          // Ignore errors from individual relays
        },
      );
    }

    // Close subscriptions when stream is cancelled
    controller.onCancel = () async {
      for (final id in subscriptionIds) {
        await _requests.closeSubscription(id);
      }
    };

    return controller.stream;
  }

  /// Parse a NIP-85 kind 30383 event into [Nip85EventMetrics]
  Nip85EventMetrics? _parseEventMetricsEvent(
    Nip01Event event,
    Set<Nip85Metric>? requestedMetrics,
  ) {
    if (event.kind != Nip85Kind.event) return null;

    final dTag = event.getDtag();
    if (dTag == null) return null;

    final metricsMap = <Nip85Metric, dynamic>{};

    for (final tag in event.tags) {
      if (tag.length < 2) continue;

      final tagName = tag[0];
      final tagValue = tag[1];

      // Try to parse as metric
      final metric = Nip85Metric.fromTagName(tagName);
      if (metric != null) {
        // If specific metrics requested, filter
        if (requestedMetrics != null && !requestedMetrics.contains(metric)) {
          continue;
        }

        // Parse value based on metric type
        final parsedValue = int.tryParse(tagValue);
        if (parsedValue != null) {
          metricsMap[metric] = parsedValue;
        }
      }
    }

    return Nip85EventMetrics(
      eventId: dTag,
      providerPubkey: event.pubKey,
      createdAt: event.createdAt,
      metrics: metricsMap,
    );
  }

  // ===========================================================================
  // ADDRESSABLE METRICS (kind 30384)
  // ===========================================================================

  /// Get addressable event metrics from trusted providers
  ///
  /// [eventAddress] - The event address (kind:pubkey:d-tag) to get metrics for
  /// [metrics] - Optional set of specific metrics to fetch. If null, fetches all available.
  /// [providers] - Optional list of providers to use. If null, uses default providers.
  ///
  /// Returns [Nip85AddressableMetrics] or null if no assertion found.
  Future<Nip85AddressableMetrics?> getAddressableMetrics(
    String eventAddress, {
    Set<Nip85Metric>? metrics,
    List<Nip85TrustedProvider>? providers,
  }) async {
    final effectiveProviders = _filterProviders(
      providers ?? _defaultProviders,
      kind: Nip85Kind.addressable,
      metrics: metrics,
    );

    if (effectiveProviders.isEmpty) {
      return null;
    }

    final providersByRelay = <String, List<Nip85TrustedProvider>>{};
    for (final provider in effectiveProviders) {
      providersByRelay.putIfAbsent(provider.relay, () => []).add(provider);
    }

    Nip85AddressableMetrics? result;
    int latestCreatedAt = 0;

    for (final entry in providersByRelay.entries) {
      final relay = entry.key;
      final relayProviders = entry.value;
      final providerPubkeys = relayProviders.map((p) => p.pubkey).toList();

      try {
        await for (final event in _requests
            .query(
              filter: Filter(
                kinds: [Nip85Kind.addressable],
                authors: providerPubkeys,
                dTags: [eventAddress],
                limit: providerPubkeys.length,
              ),
              explicitRelays: [relay],
              cacheRead: true,
              cacheWrite: true,
            )
            .stream) {
          final parsed = _parseAddressableMetricsEvent(event, metrics);
          if (parsed != null && parsed.createdAt > latestCreatedAt) {
            result = parsed;
            latestCreatedAt = parsed.createdAt;
          }
        }
      } catch (_) {}
    }

    return result;
  }

  /// Stream addressable event metrics from trusted providers
  Stream<Nip85AddressableMetrics> streamAddressableMetrics(
    String eventAddress, {
    Set<Nip85Metric>? metrics,
    List<Nip85TrustedProvider>? providers,
  }) {
    final effectiveProviders = _filterProviders(
      providers ?? _defaultProviders,
      kind: Nip85Kind.addressable,
      metrics: metrics,
    );

    final controller = StreamController<Nip85AddressableMetrics>();

    if (effectiveProviders.isEmpty) {
      controller.close();
      return controller.stream;
    }

    final providersByRelay = <String, List<Nip85TrustedProvider>>{};
    for (final provider in effectiveProviders) {
      providersByRelay.putIfAbsent(provider.relay, () => []).add(provider);
    }

    final subscriptionIds = <String>[];

    for (final entry in providersByRelay.entries) {
      final relay = entry.key;
      final relayProviders = entry.value;
      final providerPubkeys = relayProviders.map((p) => p.pubkey).toList();

      final response = _requests.subscription(
        filter: Filter(
          kinds: [Nip85Kind.addressable],
          authors: providerPubkeys,
          dTags: [eventAddress],
        ),
        explicitRelays: [relay],
      );

      subscriptionIds.add(response.requestId);

      response.stream.listen(
        (event) {
          final parsed = _parseAddressableMetricsEvent(event, metrics);
          if (parsed != null) {
            controller.add(parsed);
          }
        },
        onError: (e) {},
      );
    }

    controller.onCancel = () async {
      for (final id in subscriptionIds) {
        await _requests.closeSubscription(id);
      }
    };

    return controller.stream;
  }

  Nip85AddressableMetrics? _parseAddressableMetricsEvent(
    Nip01Event event,
    Set<Nip85Metric>? requestedMetrics,
  ) {
    if (event.kind != Nip85Kind.addressable) return null;

    final dTag = event.getDtag();
    if (dTag == null) return null;

    final metricsMap = <Nip85Metric, dynamic>{};

    for (final tag in event.tags) {
      if (tag.length < 2) continue;

      final metric = Nip85Metric.fromTagName(tag[0]);
      if (metric != null) {
        if (requestedMetrics != null && !requestedMetrics.contains(metric)) {
          continue;
        }
        final parsedValue = int.tryParse(tag[1]);
        if (parsedValue != null) {
          metricsMap[metric] = parsedValue;
        }
      }
    }

    return Nip85AddressableMetrics(
      eventAddress: dTag,
      providerPubkey: event.pubKey,
      createdAt: event.createdAt,
      metrics: metricsMap,
    );
  }

  // ===========================================================================
  // EXTERNAL ID METRICS (kind 30385)
  // ===========================================================================

  /// Get external identifier metrics from trusted providers (NIP-73)
  ///
  /// [identifier] - The NIP-73 i-tag value to get metrics for
  /// [metrics] - Optional set of specific metrics to fetch. If null, fetches all available.
  /// [providers] - Optional list of providers to use. If null, uses default providers.
  ///
  /// Returns [Nip85ExternalIdMetrics] or null if no assertion found.
  Future<Nip85ExternalIdMetrics?> getExternalIdMetrics(
    String identifier, {
    Set<Nip85Metric>? metrics,
    List<Nip85TrustedProvider>? providers,
  }) async {
    final effectiveProviders = _filterProviders(
      providers ?? _defaultProviders,
      kind: Nip85Kind.externalId,
      metrics: metrics,
    );

    if (effectiveProviders.isEmpty) {
      return null;
    }

    final providersByRelay = <String, List<Nip85TrustedProvider>>{};
    for (final provider in effectiveProviders) {
      providersByRelay.putIfAbsent(provider.relay, () => []).add(provider);
    }

    Nip85ExternalIdMetrics? result;
    int latestCreatedAt = 0;

    for (final entry in providersByRelay.entries) {
      final relay = entry.key;
      final relayProviders = entry.value;
      final providerPubkeys = relayProviders.map((p) => p.pubkey).toList();

      try {
        await for (final event in _requests
            .query(
              filter: Filter(
                kinds: [Nip85Kind.externalId],
                authors: providerPubkeys,
                dTags: [identifier],
                limit: providerPubkeys.length,
              ),
              explicitRelays: [relay],
              cacheRead: true,
              cacheWrite: true,
            )
            .stream) {
          final parsed = _parseExternalIdMetricsEvent(event, metrics);
          if (parsed != null && parsed.createdAt > latestCreatedAt) {
            result = parsed;
            latestCreatedAt = parsed.createdAt;
          }
        }
      } catch (_) {}
    }

    return result;
  }

  /// Stream external identifier metrics from trusted providers (NIP-73)
  Stream<Nip85ExternalIdMetrics> streamExternalIdMetrics(
    String identifier, {
    Set<Nip85Metric>? metrics,
    List<Nip85TrustedProvider>? providers,
  }) {
    final effectiveProviders = _filterProviders(
      providers ?? _defaultProviders,
      kind: Nip85Kind.externalId,
      metrics: metrics,
    );

    final controller = StreamController<Nip85ExternalIdMetrics>();

    if (effectiveProviders.isEmpty) {
      controller.close();
      return controller.stream;
    }

    final providersByRelay = <String, List<Nip85TrustedProvider>>{};
    for (final provider in effectiveProviders) {
      providersByRelay.putIfAbsent(provider.relay, () => []).add(provider);
    }

    final subscriptionIds = <String>[];

    for (final entry in providersByRelay.entries) {
      final relay = entry.key;
      final relayProviders = entry.value;
      final providerPubkeys = relayProviders.map((p) => p.pubkey).toList();

      final response = _requests.subscription(
        filter: Filter(
          kinds: [Nip85Kind.externalId],
          authors: providerPubkeys,
          dTags: [identifier],
        ),
        explicitRelays: [relay],
      );

      subscriptionIds.add(response.requestId);

      response.stream.listen(
        (event) {
          final parsed = _parseExternalIdMetricsEvent(event, metrics);
          if (parsed != null) {
            controller.add(parsed);
          }
        },
        onError: (e) {},
      );
    }

    controller.onCancel = () async {
      for (final id in subscriptionIds) {
        await _requests.closeSubscription(id);
      }
    };

    return controller.stream;
  }

  Nip85ExternalIdMetrics? _parseExternalIdMetricsEvent(
    Nip01Event event,
    Set<Nip85Metric>? requestedMetrics,
  ) {
    if (event.kind != Nip85Kind.externalId) return null;

    final dTag = event.getDtag();
    if (dTag == null) return null;

    final metricsMap = <Nip85Metric, dynamic>{};

    for (final tag in event.tags) {
      if (tag.length < 2) continue;

      final metric = Nip85Metric.fromTagName(tag[0]);
      if (metric != null) {
        if (requestedMetrics != null && !requestedMetrics.contains(metric)) {
          continue;
        }
        final parsedValue = int.tryParse(tag[1]);
        if (parsedValue != null) {
          metricsMap[metric] = parsedValue;
        }
      }
    }

    return Nip85ExternalIdMetrics(
      identifier: dTag,
      providerPubkey: event.pubKey,
      createdAt: event.createdAt,
      metrics: metricsMap,
    );
  }
}
