/// NIP-85 Event kinds for trusted assertions
class Nip85Kind {
  /// User assertions (pubkey as subject)
  static const int user = 30382;

  /// Event assertions (event_id as subject)
  static const int event = 30383;

  /// Addressable event assertions (event_address as subject)
  static const int addressable = 30384;

  /// External identifier assertions (NIP-73 i-tag as subject)
  static const int externalId = 30385;

  static const List<int> all = [user, event, addressable, externalId];
}

/// Available metrics for NIP-85 trusted assertions
enum Nip85Metric {
  // User metrics (kind 30382)
  followers('followers'),
  firstCreatedAt('first_created_at'),
  firstSeenAt('first_seen_at'),
  postCount('post_cnt'),
  replyCount('reply_cnt'),
  reactionsCount('reactions_cnt'),
  zapAmountReceived('zap_amt_recd'),
  zapAmountSent('zap_amt_sent'),
  zapCountReceived('zap_cnt_recd'),
  zapCountSent('zap_cnt_sent'),
  zapAvgAmountDayReceived('zap_avg_amt_day_recd'),
  zapAvgAmountDaySent('zap_avg_amt_day_sent'),
  reportsCountReceived('reports_cnt_recd'),
  reportsCountSent('reports_cnt_sent'),
  activeHoursStart('active_hours_start'),
  activeHoursEnd('active_hours_end'),

  // Event/Addressable metrics (kinds 30383, 30384, 30385)
  commentCount('comment_cnt'),
  quoteCount('quote_cnt'),
  repostCount('repost_cnt'),
  reactionCount('reaction_cnt'),
  zapCount('zap_cnt'),
  zapAmount('zap_amount'),

  // Shared (all kinds)
  rank('rank');

  const Nip85Metric(this.tagName);

  /// The tag name used in NIP-85 events
  final String tagName;

  /// Get metric from tag name
  static Nip85Metric? fromTagName(String tagName) {
    for (final metric in values) {
      if (metric.tagName == tagName) return metric;
    }
    return null;
  }
}

/// Configuration for a NIP-85 trusted assertion provider
///
/// Maps directly to NIP-85 kind 10040 tag format:
/// `["<kind>:<metric>", "<pubkey>", "<relay>"]`
class Nip85TrustedProvider {
  /// The assertion kind this provider handles
  final int kind;

  /// The specific metric this provider offers
  final Nip85Metric metric;

  /// Provider's public key
  final String pubkey;

  /// Relay URL where assertions are published
  final String relay;

  const Nip85TrustedProvider({
    required this.kind,
    required this.metric,
    required this.pubkey,
    required this.relay,
  });

  /// Create from NIP-85 kind 10040 tag format
  /// `["30382:rank", "pubkey", "relay"]`
  static Nip85TrustedProvider? fromTag(List<String> tag) {
    if (tag.length < 3) return null;

    final kindMetric = tag[0].split(':');
    if (kindMetric.length != 2) return null;

    final kind = int.tryParse(kindMetric[0]);
    if (kind == null) return null;

    final metric = Nip85Metric.fromTagName(kindMetric[1]);
    if (metric == null) return null;

    return Nip85TrustedProvider(
      kind: kind,
      metric: metric,
      pubkey: tag[1],
      relay: tag[2],
    );
  }

  /// Convert to NIP-85 kind 10040 tag format
  List<String> toTag() => ['$kind:${metric.tagName}', pubkey, relay];
}

/// User metrics result from a NIP-85 assertion (kind 30382)
class Nip85UserMetrics {
  /// Event kind for user assertions
  static const int kKind = Nip85Kind.user;

  /// Subject pubkey (the user being asserted about)
  final String pubkey;

  /// Provider pubkey (who made the assertion)
  final String providerPubkey;

  /// Timestamp of the assertion
  final int createdAt;

  /// Map of metric values
  final Map<Nip85Metric, dynamic> metrics;

  /// Common topics (t tags)
  final List<String> topics;

  Nip85UserMetrics({
    required this.pubkey,
    required this.providerPubkey,
    required this.createdAt,
    required this.metrics,
    this.topics = const [],
  });

  /// Get a specific metric value
  T? getMetric<T>(Nip85Metric metric) {
    final value = metrics[metric];
    if (value is T) return value;
    return null;
  }

  /// Get rank (0-100)
  int? get rank => getMetric<int>(Nip85Metric.rank);

  /// Get follower count
  int? get followers => getMetric<int>(Nip85Metric.followers);

  /// Get first created at timestamp
  int? get firstCreatedAt => getMetric<int>(Nip85Metric.firstCreatedAt);

  /// Get first seen at timestamp
  int? get firstSeenAt => getMetric<int>(Nip85Metric.firstSeenAt);

  /// Get post count
  int? get postCount => getMetric<int>(Nip85Metric.postCount);

  /// Get reply count
  int? get replyCount => getMetric<int>(Nip85Metric.replyCount);

  /// Get reactions count
  int? get reactionsCount => getMetric<int>(Nip85Metric.reactionsCount);

  /// Get zap amount received (sats)
  int? get zapAmountReceived => getMetric<int>(Nip85Metric.zapAmountReceived);

  /// Get zap amount sent (sats)
  int? get zapAmountSent => getMetric<int>(Nip85Metric.zapAmountSent);

  /// Get zap count received
  int? get zapCountReceived => getMetric<int>(Nip85Metric.zapCountReceived);

  /// Get zap count sent
  int? get zapCountSent => getMetric<int>(Nip85Metric.zapCountSent);
}
