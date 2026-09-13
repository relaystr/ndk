import '../../entities/cashu/cashu_mint_recommendation.dart';
import '../../entities/filter.dart';
import '../../entities/nip_01_event.dart';
import '../requests/requests.dart';

/// Discovers and ranks Cashu mints using NIP-87 announcements and reviews.
class CashuMintRecommendations {
  static const int mintAnnouncementKind = 38172;
  static const int mintReviewKind = 38000;
  static const Set<String> defaultRelays = {
    'wss://relay.cashumints.space',
    'wss://nos.lol',
    'wss://relay.azzamo.net',
    'wss://relay.snort.social',
  };

  final Requests _requests;
  final Duration cacheDuration;
  List<CashuMintRecommendation>? _cache;
  DateTime? _cachedAt;
  Future<List<CashuMintRecommendation>>? _inFlight;

  CashuMintRecommendations({
    required Requests requests,
    this.cacheDuration = const Duration(minutes: 15),
  }) : _requests = requests;

  /// Returns recommendations ordered by review count, then average rating.
  ///
  /// Network-delivered events also use NDK's configured persistent event cache.
  Future<List<CashuMintRecommendation>> discoverMints({
    Set<String> relays = defaultRelays,
    Duration timeout = const Duration(seconds: 10),
    bool forceRefresh = false,
  }) async {
    final cached = _cache;
    final cachedAt = _cachedAt;
    if (!forceRefresh &&
        cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < cacheDuration) {
      return cached;
    }
    final inFlight = _inFlight;
    if (!forceRefresh && inFlight != null) return inFlight;

    final request = _load(relays: relays, timeout: timeout);
    _inFlight = request;
    try {
      final result = await request;
      // An empty result commonly means every relay was temporarily
      // unavailable. Keep it retryable instead of hiding recommendations for
      // the full cache window.
      if (result.isNotEmpty) {
        _cache = result;
        _cachedAt = DateTime.now();
      }
      return result;
    } finally {
      if (identical(_inFlight, request)) _inFlight = null;
    }
  }

  Future<List<CashuMintRecommendation>> _load({
    required Set<String> relays,
    required Duration timeout,
  }) async {
    var result = await _loadOnce(relays: relays, timeout: timeout);
    if (result.isEmpty) {
      // A browser's first request can expire while relay connections and event
      // verification warm up. Retry once on those now-established connections.
      result = await _loadOnce(relays: relays, timeout: timeout);
    }
    return result;
  }

  Future<List<CashuMintRecommendation>> _loadOnce({
    required Set<String> relays,
    required Duration timeout,
  }) async {
    final responses = await Future.wait([
      _requests
          .query(
            filter: Filter(kinds: const [mintAnnouncementKind], limit: 5000),
            explicitRelays: relays,
            timeout: timeout,
          )
          .stream
          .toList(),
      _requests
          .query(
            filter: Filter(
              kinds: const [mintReviewKind],
              tags: const {
                '#k': ['$mintAnnouncementKind'],
              },
              limit: 5000,
            ),
            explicitRelays: relays,
            timeout: timeout,
          )
          .stream
          .toList(),
    ]);
    return fromEvents(
      announcements: responses.first,
      reviews: responses.last,
    );
  }

  /// Parses fetched events. Public for custom transports and deterministic tests.
  static List<CashuMintRecommendation> fromEvents({
    required Iterable<Nip01Event> announcements,
    required Iterable<Nip01Event> reviews,
  }) {
    final urls = <String>{};
    for (final event in announcements) {
      if (event.kind != mintAnnouncementKind) continue;
      urls.addAll(_mintUrls(event));
    }

    final latestByReviewerAndUrl = <String, CashuMintReview>{};
    for (final event in reviews) {
      if (event.kind != mintReviewKind ||
          _firstTag(event, 'k') != '$mintAnnouncementKind') {
        continue;
      }
      final parsed = _parseReview(event.content);
      for (final url in _mintUrls(event)) {
        urls.add(url);
        final key = '$url|${event.pubKey}';
        final existing = latestByReviewerAndUrl[key];
        if (existing == null || event.createdAt > existing.createdAt) {
          latestByReviewerAndUrl[key] = CashuMintReview(
            reviewerPubkey: event.pubKey,
            createdAt: event.createdAt,
            rating: parsed.rating,
            comment: parsed.comment,
          );
        }
      }
    }

    final ranked = urls.map((url) {
      final mintReviews = latestByReviewerAndUrl.entries
          .where((entry) => entry.key.startsWith('$url|'))
          .map((entry) => entry.value)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final ratings =
          mintReviews.map((review) => review.rating).whereType<int>().toList();
      return CashuMintRecommendation(
        url: url,
        averageRating: ratings.isEmpty
            ? null
            : ratings.reduce((a, b) => a + b) / ratings.length,
        reviewsCount: mintReviews.length,
        reviews: mintReviews,
      );
    }).toList();

    ranked.sort((a, b) {
      final byCount = b.reviewsCount.compareTo(a.reviewsCount);
      if (byCount != 0) return byCount;
      return (b.averageRating ?? 0).compareTo(a.averageRating ?? 0);
    });
    return ranked;
  }

  static Iterable<String> _mintUrls(Nip01Event event) sync* {
    for (final tag in event.tags) {
      if (tag.length < 2 || tag.first != 'u') continue;
      final uri = Uri.tryParse(tag[1].trim());
      if (uri?.scheme == 'https' && uri!.host.isNotEmpty) {
        yield uri.toString().replaceAll(RegExp(r'/+$'), '');
      }
    }
  }

  static String? _firstTag(Nip01Event event, String name) {
    for (final tag in event.tags) {
      if (tag.length >= 2 && tag.first == name) return tag[1];
    }
    return null;
  }

  static ({int? rating, String comment}) _parseReview(String content) {
    final match = RegExp(
      r'\s*\[(\d)\s*/\s*5\]\s*(.*)$',
      dotAll: true,
    ).firstMatch(content);
    if (match == null) return (rating: null, comment: content.trim());
    final parsed = int.tryParse(match.group(1)!);
    return (
      rating: parsed != null && parsed >= 1 && parsed <= 5 ? parsed : null,
      comment: match.group(2)!.trim(),
    );
  }
}
