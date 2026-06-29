import 'package:ndk/ndk.dart';

import '../../../shared/helpers/relay_helper.dart';
import '../../../shared/nips/nip09/deletion.dart';
import '../../../shared/nips/nip25/reactions.dart';
import 'broadcast_sender.dart';
import 'pending_broadcast_delivery.dart';

/// Public-facing broadcast facade. \
/// Delegates immediate sending to [BroadcastSender] and coordinates pending
/// delivery enrollment for specific-relay broadcasts. \
/// The retry path in [PendingBroadcastDelivery] calls [BroadcastSender] directly,
/// so it never re-enters this facade's enrollment logic.
class Broadcast {
  final BroadcastSender _sender;
  final Accounts _accounts;
  final CacheManager _cacheManager;
  final PendingBroadcastDelivery? _pendingDelivery;

  /// creates a new [Broadcast] facade instance
  ///
  Broadcast({
    required BroadcastSender broadcastSender,
    required Accounts accounts,
    required CacheManager cacheManager,
    required PendingBroadcastDelivery pendingDelivery,
  })  : _sender = broadcastSender,
        _accounts = accounts,
        _cacheManager = cacheManager,
        _pendingDelivery = pendingDelivery;

  /// [throws] if the default signer and the custom signer are null \
  /// [returns] the signer that is not null, if both are provided returns [customSigner]
  EventSigner _checkSinger({EventSigner? customSigner}) {
    if (_accounts.isNotLoggedIn && customSigner == null) {
      throw "cannot broadcast without a signer!";
    }
    return customSigner ?? _accounts.getLoggedAccount()!.signer;
  }

  /// low level nostr broadcast using inbox/outbox (gossip) \
  /// [specificRelays] disables inbox/outbox (gossip) and broadcasts to the relays specified. Useful for NostrWalletConnect \
  /// [customSigner] if you want to use a different signer than the one from currently logged in user in [Accounts] \
  /// [considerDonePercent] the percentage (0.0, 1.0) of relays that need to respond with "OK" for the broadcast to be considered done (overrides the default value) \
  /// [timeout] the timeout for the broadcast (overrides the default timeout) \
  /// [saveToCache] whether to save the event to cache (overrides the default value from config) \
  /// [returns] a [NdkBroadcastResponse] object containing the result => success per relay
  NdkBroadcastResponse broadcast({
    required Nip01Event nostrEvent,
    Iterable<String>? specificRelays,
    EventSigner? customSigner,
    double? considerDonePercent,
    Duration? timeout,
    bool? saveToCache,
  }) {
    // prep for pending delivery enrollment
    final cleanedSpecificRelays =
        specificRelays != null ? cleanRelayUrls(specificRelays.toList()) : null;
    final signer = nostrEvent.sig == null
        ? _checkSinger(customSigner: customSigner)
        : null;

    // delegate immediate send to the sender
    final response = _sender.broadcast(
      nostrEvent: nostrEvent,
      specificRelays: specificRelays,
      customSigner: customSigner,
      considerDonePercent: considerDonePercent,
      timeout: timeout,
      saveToCache: saveToCache,
    );

    // enroll in pending delivery for specific-relay broadcasts
    final pendingDelivery = _pendingDelivery;
    Future<void>? pendingEnrollment;
    if (pendingDelivery != null &&
        cleanedSpecificRelays != null &&
        cleanedSpecificRelays.isNotEmpty) {
      pendingEnrollment = pendingDelivery.enqueueSpecificRelayBroadcast(
        event: nostrEvent,
        relayUrls: cleanedSpecificRelays,
        requiresInteractiveSigning:
            signer != null && signer.requiresInteractiveSigning,
      );
      pendingEnrollment.then((_) {
        response.broadcastDoneFuture.then(
          (responses) => pendingDelivery.persistSpecificRelayBroadcastResult(
            nostrEvent,
            responses,
          ),
          onError: (_, __) {},
        );
      }, onError: (_, __) {});
    }

    if (pendingEnrollment == null) {
      return response;
    }

    final broadcastDoneFuture = pendingEnrollment.then(
      (_) => response.broadcastDoneFuture,
    );
    return NdkBroadcastResponse(
      publishEvent: response.publishEvent,
      broadcastDoneStream: response.broadcastDone,
      broadcastDoneFuture: broadcastDoneFuture,
    );
  }

  /// **********************************************************************************************************
  /// convenience methods
  /// **********************************************************************************************************

  /// broadcast a reaction to an event \
  /// [eventId] the event you want to react to \
  /// [customRelays] relay URls to send the deletion request to specific relays \
  /// [reaction] the reaction, default + (like) can be 🤔 (emoji)
  NdkBroadcastResponse broadcastReaction({
    required String eventId,
    Iterable<String>? customRelays,
    String reaction = "+",
  }) {
    final signer = _checkSinger();
    Nip01Event event = Nip01Event(
        pubKey: signer.getPublicKey(),
        kind: Reaction.kKind,
        tags: [
          ["e", eventId]
        ],
        content: reaction,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000);
    return broadcast(nostrEvent: event, specificRelays: customRelays);
  }

  /// Request a deletion of an event (NIP-09 compliant).
  ///
  /// **New API recommended:**
  /// - [event] single event to delete → generates `e` + `k` tags
  /// - [events] multiple events to delete → generates `e` + `k` tags
  /// - [eventAndAllVersions] event to delete including all versions → generates `e` + `a` + `k` tags
  /// - [eventsAndAllVersions] events to delete including all versions → generates `e` + `a` + `k` tags
  ///
  /// **Legacy API without `k` tag:**
  /// - [eventId] event ID to delete → generates only `e` tag
  /// - [eventIds] event IDs to delete → generates only `e` tags
  ///
  /// [customRelays] relay URLs to send the deletion request to specific relays
  /// [customSigner] if you want to use a different signer than the default specified in [NdkConfig]
  /// [reason] reason for deletion (content of the deletion event)
  NdkBroadcastResponse broadcastDeletion({
    // New API (NIP-09 compliant)
    Nip01Event? event,
    List<Nip01Event>? events,
    Nip01Event? eventAndAllVersions,
    List<Nip01Event>? eventsAndAllVersions,
    // Legacy API (backward compatible, without "k" tag)
    String? eventId,
    List<String>? eventIds,
    // Common parameters
    Iterable<String>? customRelays,
    EventSigner? customSigner,
    String reason = "delete",
  }) {
    final EventSigner mySigner = _checkSinger(customSigner: customSigner);

    // Collect all events from new API
    List<Nip01Event> allEvents = [];
    if (event != null) {
      allEvents.add(event);
    }
    if (events != null) {
      allEvents.addAll(events);
    }

    List<Nip01Event> allEventsAndAllVersions = [];
    if (eventAndAllVersions != null) {
      allEventsAndAllVersions.add(eventAndAllVersions);
    }
    if (eventsAndAllVersions != null) {
      allEventsAndAllVersions.addAll(eventsAndAllVersions);
    }

    // Collect all IDs from legacy API
    List<String> allEventIds = [];
    if (eventId != null) {
      allEventIds.add(eventId);
    }
    if (eventIds != null) {
      allEventIds.addAll(eventIds);
    }

    // Validate that at least one parameter is provided
    if (allEvents.isEmpty &&
        allEventsAndAllVersions.isEmpty &&
        allEventIds.isEmpty) {
      throw ArgumentError(
          "At least one event or eventId must be provided for deletion.");
    }

    // Build tags
    List<List<String>> tags = [];
    Set<int> kinds = {};
    Set<String> idsToRemoveFromCache = {};

    // 1. Events from new API → e + k tags
    for (final e in allEvents) {
      tags.add(["e", e.id]);
      kinds.add(e.kind);
      idsToRemoveFromCache.add(e.id);
    }

    // 2. Events with all versions → e + a + k tags
    for (final e in allEventsAndAllVersions) {
      tags.add(["e", e.id]);
      kinds.add(e.kind);

      // Generate "a" tag to delete all versions of this kind from this pubkey
      // Works for replaceable events (NIP-09) and as extension for regular events
      final dTag = e.getDtag();
      tags.add(["a", "${e.kind}:${e.pubKey}:${dTag ?? ''}"]);
    }

    // 3. Event IDs from legacy API → e tags only (no k tag)
    for (final id in allEventIds) {
      tags.add(["e", id]);
      idsToRemoveFromCache.add(id);
    }

    // 4. Add "k" tags for each unique kind (only from new API events)
    for (final k in kinds) {
      tags.add(["k", k.toString()]);
    }

    Nip01Event deletionEvent = Nip01Event(
        pubKey: mySigner.getPublicKey(),
        kind: Deletion.kKind,
        tags: tags,
        content: reason,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000);

    // Remove events from cache
    if (idsToRemoveFromCache.isNotEmpty) {
      _cacheManager.removeEvents(ids: idsToRemoveFromCache.toList());
    }

    // Remove all versions from cache for eventAndAllVersions
    for (final e in allEventsAndAllVersions) {
      final dTag = e.getDtag();
      _cacheManager.removeEvents(
        pubKeys: [e.pubKey],
        kinds: [e.kind],
        tags: dTag != null
            ? {
                'd': [dTag]
              }
            : null,
      );
    }

    return broadcast(
      nostrEvent: deletionEvent,
      specificRelays: customRelays,
      customSigner: mySigner,
    );
  }
}
