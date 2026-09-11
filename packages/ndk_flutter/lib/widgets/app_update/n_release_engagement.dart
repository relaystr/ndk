import 'package:flutter/foundation.dart';
import 'package:ndk/ndk.dart';

@immutable
class NReleaseComment {
  final Nip01Event event;
  final Metadata? author;

  const NReleaseComment({required this.event, this.author});

  String get content => event.content;
  String get authorName =>
      author?.displayName ?? author?.name ?? _shortKey(event.pubKey);
}

@immutable
class NReleaseZapContributor {
  final String pubkey;
  final Metadata? metadata;
  final int amountSats;

  const NReleaseZapContributor({
    required this.pubkey,
    required this.metadata,
    required this.amountSats,
  });
}

@immutable
class NReleaseEngagementState {
  final bool loading;
  final bool hasLoaded;
  final bool posting;
  final int zapCount;
  final int zapAmountSats;
  final List<NReleaseZapContributor> zapContributors;
  final int reactionCount;
  final List<NReleaseComment> comments;
  final Metadata? publisher;
  final String? error;
  final bool errorFromPosting;

  const NReleaseEngagementState({
    this.loading = false,
    this.hasLoaded = false,
    this.posting = false,
    this.zapCount = 0,
    this.zapAmountSats = 0,
    this.zapContributors = const [],
    this.reactionCount = 0,
    this.comments = const [],
    this.publisher,
    this.error,
    this.errorFromPosting = false,
  });

  NReleaseEngagementState copyWith({
    bool? loading,
    bool? hasLoaded,
    bool? posting,
    int? zapCount,
    int? zapAmountSats,
    List<NReleaseZapContributor>? zapContributors,
    int? reactionCount,
    List<NReleaseComment>? comments,
    Metadata? publisher,
    String? error,
    bool? errorFromPosting,
    bool clearError = false,
  }) => NReleaseEngagementState(
    loading: loading ?? this.loading,
    hasLoaded: hasLoaded ?? this.hasLoaded,
    posting: posting ?? this.posting,
    zapCount: zapCount ?? this.zapCount,
    zapAmountSats: zapAmountSats ?? this.zapAmountSats,
    zapContributors: zapContributors ?? this.zapContributors,
    reactionCount: reactionCount ?? this.reactionCount,
    comments: comments ?? this.comments,
    publisher: publisher ?? this.publisher,
    error: clearError ? null : error ?? this.error,
    errorFromPosting: clearError
        ? false
        : errorFromPosting ?? this.errorFromPosting,
  );
}

class NReleaseEngagementController extends ChangeNotifier {
  final Ndk ndk;
  final SoftwareRelease release;
  final List<String> relays;
  final SoftwareAppRef? zapTargetApp;
  final Duration queryTimeout;
  final Duration metadataTimeout;

  NReleaseEngagementState _state = const NReleaseEngagementState();
  NReleaseEngagementState get state => _state;
  bool _disposed = false;
  Future<void>? _loadFuture;

  NReleaseEngagementController({
    required this.ndk,
    required this.release,
    this.relays = const [],
    this.zapTargetApp,
    this.queryTimeout = const Duration(seconds: 4),
    this.metadataTimeout = const Duration(seconds: 3),
  });

  String get releaseAddress =>
      '$softwareReleaseKind:${release.event.pubKey}:'
      '${release.identifier}@${release.version}';

  String get applicationAddress =>
      '$softwareApplicationKind:${release.event.pubKey}:${release.identifier}';

  bool get canComment => ndk.accounts.canSign;

  Future<void> load() => _loadFuture ??= _load().whenComplete(() {
    _loadFuture = null;
  });

  Future<void> _load() async {
    final totalTimer = Stopwatch()..start();
    _setState(_state.copyWith(loading: true, clearError: true));
    try {
      final targetTimer = Stopwatch()..start();
      final targetsFuture = _loadEngagementTargets();
      final zapTargetsFuture = zapTargetApp == null
          ? targetsFuture
          : _loadEngagementTargets(app: zapTargetApp);
      final targets = await targetsFuture;
      final zapTargets = await zapTargetsFuture;
      _logTiming('targets', targetTimer);
      final eventsTimer = Stopwatch()..start();
      final earliestRelease = [
        targets.earliestRelease,
        zapTargets.earliestRelease,
      ].reduce((a, b) => a < b ? a : b);
      final publishers = {
        release.event.pubKey,
        zapTargetApp?.publisher,
      }.whereType<String>().toList(growable: false);
      final responses = await Future.wait([
        ndk.requests
            .query(
              name: 'software-release-zaps-reactions',
              explicitRelays: relays.isEmpty ? null : relays,
              filter: Filter(
                kinds: const [9735, 7],
                pTags: publishers,
                since: earliestRelease,
                limit: 1000,
              ),
              timeout: queryTimeout,
            )
            .future,
        ndk.requests
            .query(
              name: 'software-release-comments',
              explicitRelays: relays.isEmpty ? null : relays,
              filter: Filter(
                kinds: const [1111],
                tags: {'#A': targets.addresses.toList()},
                since: targets.earliestRelease,
                limit: 500,
              ),
              timeout: queryTimeout,
            )
            .future,
        ndk.requests
            .query(
              name: 'software-release-parent-comments',
              explicitRelays: relays.isEmpty ? null : relays,
              filter: Filter(
                kinds: const [1111],
                tags: {'#a': targets.releaseAddresses.toList()},
                since: targets.earliestRelease,
                limit: 500,
              ),
              timeout: queryTimeout,
            )
            .future,
      ]);
      final events = responses.expand((response) => response);
      _logTiming('events', eventsTimer);
      final unique = {
        for (final event in events)
          if (_isRelevantEngagement(event, targets, zapTargets))
            event.id: event,
      }.values;
      final zapEvents = unique.where((event) => event.kind == 9735);
      var zapCount = 0;
      var zapAmount = 0;
      final satsByPubkey = <String, int>{};
      final zapRecipient = zapTargetApp?.publisher ?? release.event.pubKey;
      for (final event in zapEvents) {
        try {
          final receipt = ZapReceipt.fromEvent(event);
          if (receipt.recipient != zapRecipient) continue;
          zapCount++;
          final amount = receipt.amountSats ?? 0;
          zapAmount += amount;
          final sender = receipt.sender;
          if (sender != null && sender.isNotEmpty) {
            satsByPubkey.update(
              sender,
              (current) => current + amount,
              ifAbsent: () => amount,
            );
          }
        } catch (_) {
          // Ignore malformed receipts; relay signatures are already verified.
        }
      }
      final commentEvents =
          unique
              .where(
                (event) =>
                    event.kind == 1111 && event.content.trim().isNotEmpty,
              )
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final authors = {
        release.event.pubKey,
        ...commentEvents.map((event) => event.pubKey),
        ...satsByPubkey.keys,
      };
      final reactionCount = unique.where((event) => event.kind == 7).length;
      _setState(
        _state.copyWith(
          loading: true,
          hasLoaded: true,
          zapCount: zapCount,
          zapAmountSats: zapAmount,
          zapContributors: _zapContributors(
            satsByPubkey,
            const <String, Metadata>{},
          ),
          reactionCount: reactionCount,
          comments: _comments(commentEvents, const <String, Metadata>{}),
        ),
      );

      final metadataTimer = Stopwatch()..start();
      final metadata = await _loadMetadata(authors);
      _logTiming('metadata', metadataTimer);
      _setState(
        _state.copyWith(
          loading: false,
          zapContributors: _zapContributors(satsByPubkey, metadata),
          comments: _comments(commentEvents, metadata),
          publisher: metadata[release.event.pubKey],
        ),
      );
      _logTiming('total', totalTimer);
    } catch (error) {
      _setState(_state.copyWith(loading: false, error: error.toString()));
      _logTiming('failed', totalTimer);
    }
  }

  bool _isRelevantEngagement(
    Nip01Event event,
    _EngagementTargets targets,
    _EngagementTargets zapTargets,
  ) {
    if (event.kind == 9735) return zapTargets.isReferencedBy(event);
    if (event.kind == 7) return targets.isReferencedBy(event);
    if (event.kind == 1111) {
      return event.getTags('A').any(targets.containsAddress) ||
          event
              .getTags('a')
              .any(
                (value) => targets.releaseAddresses.any(
                  (address) => address.toLowerCase() == value.toLowerCase(),
                ),
              );
    }
    return false;
  }

  Future<Map<String, Metadata>> _loadMetadata(Set<String> authors) async {
    final loaded = await ndk.metadata
        .loadMetadatas(authors.toList(growable: false), null)
        .timeout(metadataTimeout, onTimeout: () => const <Metadata>[]);
    return {for (final item in loaded) item.pubKey: item};
  }

  List<NReleaseZapContributor> _zapContributors(
    Map<String, int> satsByPubkey,
    Map<String, Metadata> metadata,
  ) =>
      satsByPubkey.entries
          .map(
            (entry) => NReleaseZapContributor(
              pubkey: entry.key,
              metadata: metadata[entry.key],
              amountSats: entry.value,
            ),
          )
          .toList()
        ..sort((a, b) => b.amountSats.compareTo(a.amountSats));

  List<NReleaseComment> _comments(
    List<Nip01Event> events,
    Map<String, Metadata> metadata,
  ) => events
      .map(
        (event) =>
            NReleaseComment(event: event, author: metadata[event.pubKey]),
      )
      .toList(growable: false);

  void _logTiming(String stage, Stopwatch timer) {
    timer.stop();
    Logger.log.d(
      () =>
          'software-release-engagement $stage '
          '${timer.elapsedMilliseconds}ms (${release.identifier})',
    );
  }

  Future<_EngagementTargets> _loadEngagementTargets({
    SoftwareAppRef? app,
  }) async {
    final targetApp =
        app ??
        SoftwareAppRef(
          publisher: release.event.pubKey,
          identifier: release.identifier,
        );
    final isCurrentRelease =
        targetApp.publisher == release.event.pubKey &&
        targetApp.identifier == release.identifier;
    final releases = <SoftwareRelease>{if (isCurrentRelease) release};
    final releasesFuture = () async {
      try {
        return await ndk.software.getReleases(
          app: targetApp,
          channel: release.channel,
          relays: relays,
          timeout: queryTimeout,
        );
      } catch (_) {
        return const <SoftwareRelease>[];
      }
    }();
    final applicationFuture = () async {
      try {
        return await ndk.software.getApp(
          app: targetApp,
          relays: relays,
          timeout: queryTimeout,
        );
      } catch (_) {
        return null;
      }
    }();
    releases.addAll(await releasesFuture);
    final application = await applicationFuture;

    final releaseAddresses = releases
        .map(
          (item) =>
              '$softwareReleaseKind:${item.event.pubKey}:'
              '${item.identifier}@${item.version}',
        )
        .toSet();
    return _EngagementTargets(
      addresses: {
        '$softwareApplicationKind:${targetApp.publisher}:${targetApp.identifier}',
        ...releaseAddresses,
      },
      releaseAddresses: releaseAddresses,
      eventIds: {
        if (application != null) application.event.id,
        ...releases.map((item) => item.event.id),
      },
      earliestRelease: releases.map((item) => item.event.createdAt).fold<int>(
        0,
        (earliest, timestamp) {
          if (earliest == 0 || timestamp < earliest) return timestamp;
          return earliest;
        },
      ),
    );
  }

  Future<bool> postComment(String content) async {
    final text = content.trim();
    final pubkey = ndk.accounts.getPublicKey();
    if (text.isEmpty || pubkey == null || !canComment || _state.posting) {
      return false;
    }
    _setState(_state.copyWith(posting: true, clearError: true));
    try {
      final event = Nip01Event(
        pubKey: pubkey,
        kind: 1111,
        tags: [
          ['A', applicationAddress, ...relays.take(1)],
          ['K', softwareApplicationKind.toString()],
          ['P', release.event.pubKey],
          ['a', releaseAddress, ...relays.take(1)],
          ['k', softwareReleaseKind.toString()],
          ['p', release.event.pubKey],
        ],
        content: text,
      );
      final responses = await ndk.broadcast
          .broadcast(
            nostrEvent: event,
            specificRelays: relays.isEmpty ? null : relays,
          )
          .broadcastDoneFuture;
      if (!responses.any((response) => response.broadcastSuccessful)) {
        final relayErrors = responses
            .map((response) => response.msg.trim())
            .where((message) => message.isNotEmpty)
            .toSet()
            .join('; ');
        throw StateError(
          relayErrors.isEmpty
              ? 'No relay accepted the comment.'
              : 'No relay accepted the comment: $relayErrors',
        );
      }
      _setState(_state.copyWith(posting: false));
      final activeLoad = _loadFuture;
      if (activeLoad != null) await activeLoad;
      await load();
      return true;
    } catch (error) {
      _setState(
        _state.copyWith(
          posting: false,
          error: error.toString(),
          errorFromPosting: true,
        ),
      );
      return false;
    }
  }

  void _setState(NReleaseEngagementState value) {
    if (_disposed) return;
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class _EngagementTargets {
  final Set<String> addresses;
  final Set<String> releaseAddresses;
  final Set<String> eventIds;
  final int earliestRelease;

  const _EngagementTargets({
    required this.addresses,
    required this.releaseAddresses,
    required this.eventIds,
    required this.earliestRelease,
  });

  bool isReferencedBy(Nip01Event event) {
    final normalizedEventIds = eventIds.map((value) => value.toLowerCase());
    final normalizedAddresses = addresses.map((value) => value.toLowerCase());
    final referencedEvents = event.getTags('e');
    if (referencedEvents.any(normalizedEventIds.contains)) return true;
    final referencedAddresses = event.getTags('a');
    return referencedAddresses.any(normalizedAddresses.contains);
  }

  bool containsAddress(String value) =>
      addresses.any((address) => address.toLowerCase() == value.toLowerCase());
}

String _shortKey(String value) => value.length <= 12
    ? value
    : '${value.substring(0, 8)}…${value.substring(value.length - 4)}';
