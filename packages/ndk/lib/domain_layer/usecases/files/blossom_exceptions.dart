/// Thrown when a blossom operation requires an identity that cannot sign, or
/// that the `AuthHandler` let no server see, so no request can carry an
/// authorization. Nothing is sent: going out bare is exactly what
/// [AuthPolicyRequire] rules out.
class BlossomAuthUnavailableException implements Exception {
  /// identity the operation required
  final String pubkey;

  /// blossom verb the authorization would have carried, such as "upload"
  final String operation;

  /// the required identity cannot sign or may not be revealed, so nothing was
  /// sent
  BlossomAuthUnavailableException(this.pubkey, this.operation);

  @override
  String toString() =>
      'BlossomAuthUnavailableException: $pubkey cannot sign or may not be '
      'revealed, so no blossom $operation request can be authorised';
}
