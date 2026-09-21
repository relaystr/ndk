import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/main/ndk_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'motd_data.dart';

/// Lifecycle status of the Message of the Day controller.
enum NMotdStatus {
  /// Fetching the message from the network / cache.
  loading,

  /// The lookup finished; [NMotdController.current] may be null.
  loaded,

  /// The lookup failed; see [NMotdController.error].
  error,
}

/// Manages fetching, version filtering and dismissal state of a Message of
/// the Day (NIP-78 kind 30078) event.
///
/// The event is identified by its author pubkey and a `d` tag value (both
/// supplied by the app developer), so a single app can host several
/// independent message channels.
class NMotdController extends ChangeNotifier {
  /// The Flutter wrapper holding the NDK instance.
  final NdkFlutter ndkFlutter;

  /// Public key of the author that publishes the message.
  final String authorPubkey;

  /// `d` tag value identifying the message; defaults to "motd".
  final String dTagValue;

  /// Timeout for a single lookup round.
  final Duration queryTimeout;

  NMotdStatus _status = NMotdStatus.loading;
  MotdData? _current;
  Object? _error;
  String? _dismissedEventId;
  Future<void>? _startFuture;

  NMotdController({
    required this.ndkFlutter,
    required this.authorPubkey,
    this.dTagValue = MotdData.kDefaultDTag,
    this.queryTimeout = const Duration(seconds: 15),
  });

  /// Current lookup status.
  NMotdStatus get status => _status;

  /// The fetched message, or null when none exists (yet).
  MotdData? get current => _current;

  /// Last lookup error, when [status] is [NMotdStatus.error].
  Object? get error => _error;

  /// Whether [motd] decides whether the popup should be shown.
  ///
  /// The message is shown when it exists, was not dismissed yet, and
  /// (optionally) [appVersion] meets the event's `version` minimum tag. When
  /// either version is missing, no version filtering is applied.
  bool shouldShow({String? appVersion}) {
    if (_status != NMotdStatus.loaded) return false;
    final motd = _current;
    if (motd == null) return false;
    if (motd.eventId == _dismissedEventId) return false;

    final eventVersion = motd.version;
    if (eventVersion != null && appVersion != null) {
      if (compareVersions(appVersion, eventVersion) < 0) return false;
    }
    return true;
  }

  /// Starts the controller. Idempotent; safe to call multiple times.
  Future<void> start() {
    return _startFuture ??= _load();
  }

  /// Re-fetches the message from the network / cache.
  Future<void> refresh() async {
    _startFuture = null;
    await _load();
  }

  Future<void> _load() async {
    _status = NMotdStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final preferences = await SharedPreferences.getInstance();
      _dismissedEventId = preferences.getString(_dismissKey);

      final response = ndkFlutter.ndk.requests.query(
        filter: Filter(
          authors: [authorPubkey],
          kinds: [MotdData.kKind],
          dTags: [dTagValue],
          limit: 1,
        ),
        timeout: queryTimeout,
      );
      final events = await response.future;

      Nip01Event? latest;
      for (final event in events) {
        if (event.kind == MotdData.kKind &&
            event.getDtag() == dTagValue &&
            (latest == null || event.createdAt > latest.createdAt)) {
          latest = event;
        }
      }

      _current = latest == null ? null : MotdData.fromEvent(latest);
      _status = NMotdStatus.loaded;
    } catch (e) {
      _error = e;
      _status = NMotdStatus.error;
    }
    notifyListeners();
  }

  /// Marks the current message as seen so it is not shown again.
  Future<void> dismiss() async {
    final motd = _current;
    if (motd == null) return;
    _dismissedEventId = motd.eventId;

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_dismissKey, motd.eventId);
    notifyListeners();
  }

  String get _dismissKey => 'ndk-motd-dismissed:$authorPubkey:$dTagValue';

  /// Compares two version strings semantically.
  ///
  /// Handles numeric segments ("1.10" > "1.9"), build metadata and pre-release
  /// suffixes ("1.0.0-beta" < "1.0.0"). Returns a negative number when [a] is
  /// older, zero when equal, and a positive number when [a] is newer.
  static int compareVersions(String a, String b) {
    final cleanA = _stripBuild(a.trim());
    final cleanB = _stripBuild(b.trim());
    final baseA = cleanA.split('-').first;
    final baseB = cleanB.split('-').first;

    final numsA = _versionNumbers(baseA);
    final numsB = _versionNumbers(baseB);
    final length = max(numsA.length, numsB.length);
    for (var i = 0; i < length; i++) {
      final av = i < numsA.length ? numsA[i] : 0;
      final bv = i < numsB.length ? numsB[i] : 0;
      if (av != bv) return av < bv ? -1 : 1;
    }

    final preA = cleanA.contains('-');
    final preB = cleanB.contains('-');
    if (preA != preB) return preA ? -1 : 1;
    return 0;
  }

  static String _stripBuild(String version) =>
      version.split('+').first.trim();

  static List<int> _versionNumbers(String base) => base
      .split('.')
      .map((part) => int.tryParse(part.trim()) ?? 0)
      .toList();
}