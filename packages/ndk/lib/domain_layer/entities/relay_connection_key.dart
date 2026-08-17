import '../../shared/helpers/relay_helper.dart';

final _hexPubkeyRegex = RegExp(r'^[0-9a-fA-F]{64}$');

/// Identifies a single relay connection.
///
/// A connection carries at most one authenticated identity, chosen when the
/// connection is opened and immutable for its whole lifetime. Several
/// connections may therefore exist towards the same relay.
class RelayConnectionKey {
  /// relay url, normalized
  final String url;

  /// lowercase hex pubkey authenticated on this connection, null when anonymous
  final String? pubkey;

  /// stands for the absent pubkey in [canonical]; not a valid pubkey, so it
  /// cannot collide with one
  static const String anonymousMarker = 'anon';

  const RelayConnectionKey._(this.url, this.pubkey);

  /// key of a connection that never authenticates
  factory RelayConnectionKey.anonymous(String url) =>
      RelayConnectionKey._(_normalizeUrl(url), null);

  /// key of a connection authenticated as [pubkey]
  factory RelayConnectionKey.authenticated(String url, String pubkey) {
    if (!_hexPubkeyRegex.hasMatch(pubkey)) {
      throw ArgumentError.value(pubkey, 'pubkey', 'expected 64 hex characters');
    }
    return RelayConnectionKey._(_normalizeUrl(url), pubkey.toLowerCase());
  }

  /// whether any identity is bound to this connection
  bool get isAnonymous => pubkey == null;

  /// stable representation, for persisted keys and logs
  String get canonical => '$url|${pubkey ?? anonymousMarker}';

  /// an unparsable url is kept as given: it simply never matches a connection,
  /// which is what an unparsable url did before it became part of the key
  static String _normalizeUrl(String url) => cleanRelayUrl(url) ?? url.trim();

  @override
  String toString() => canonical;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RelayConnectionKey &&
          runtimeType == other.runtimeType &&
          url == other.url &&
          pubkey == other.pubkey;

  @override
  int get hashCode => Object.hash(url, pubkey);
}
