/// Thrown when a broadcast requires an identity that cannot sign, so no
/// connection can carry it. Nothing is sent: falling back to the anonymous
/// connection is exactly what [RelayAuthRequire] rules out.
class BroadcastAuthUnavailableException implements Exception {
  /// identity the broadcast required
  final String pubkey;

  /// the required identity cannot sign, so nothing was sent
  BroadcastAuthUnavailableException(this.pubkey);

  @override
  String toString() =>
      'BroadcastAuthUnavailableException: $pubkey cannot sign, so no '
      'connection can carry this broadcast';
}
