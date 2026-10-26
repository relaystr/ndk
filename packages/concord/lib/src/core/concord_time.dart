import 'package:ndk/domain_layer/entities/nip_01_event.dart';

import 'encoding.dart';

/// Concord's comparison clock (CORD-02 §4): every ordering decision uses
/// `created_at * 1000 + ms`, never the author-settable timestamp alone and
/// never the outer wrap's time.
class Millis {
  /// The `ms` tag key.
  static const String tag = 'ms';

  /// Malformed values (outside 0..999) must be **dropped, not interpreted**
  /// (checklist) — this is what callers use to decide.
  static const int maxValue = 999;

  /// Extracts the sub-second remainder from a rumor's tags. Returns null
  /// when the `ms` tag is present but malformed (entry dropped, per the
  /// checklist); an absent tag is treated as 0.
  static int? msOf(Nip01Event rumor) {
    final raw = rumor.getFirstTag(tag);
    if (raw == null) return 0;
    final parsed = tryParseDecimal(raw);
    if (parsed == null || parsed > maxValue) return null;
    return parsed;
  }

  /// The true event time in milliseconds, or null when the event is
  /// malformed (its `ms` tag outside 0..999).
  static int? of(Nip01Event rumor) {
    final ms = msOf(rumor);
    if (ms == null) return null;
    return rumor.createdAt * 1000 + ms;
  }

  /// True time of a (createdAt, ms) pair.
  static int ofValues(int createdAt, int ms) => createdAt * 1000 + ms;

  /// Builds the `["ms", "<0..999>"]` tag for a fresh rumor. Sub-second
  /// ordering rides this tag; `created_at` stays untweaked.
  static List<String> tagFor(DateTime time) => [
    tag,
    decimalTag(time.millisecond),
  ];

  /// Clock-skew bound for guestbook coalescing (CORD-02 §5): an entry dated
  /// more than one hour ahead of the receiver's clock is dropped outright.
  static const int guestbookFutureBoundMs = 3600 * 1000;
}

/// NIP-40 expiration helpers (CORD-08).
class Expiration {
  static const String tag = 'expiration';

  /// The expiration value a rumor carries, or null when absent/malformed.
  /// Absent, 0, or malformed means **off** — never guess a default.
  static int? secondsOf(Nip01Event rumor) {
    final raw = rumor.getFirstTag(tag);
    if (raw == null) return null;
    return tryParseDecimal(raw);
  }

  /// Whether [rumor] is already expired at [nowSeconds]. A reader MUST
  /// refuse an already-expired rumor at ingest (CORD-08 §3).
  static bool isExpired(Nip01Event rumor, {required int nowSeconds}) {
    final seconds = secondsOf(rumor);
    if (seconds == null || seconds == 0) return false;
    return nowSeconds >= seconds;
  }
}
