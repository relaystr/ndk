/// Exception thrown when a signer request is rejected by the remote signer.
///
/// This occurs when the user explicitly rejects/denies the request on the
/// remote signer (bunker, browser extension, Amber, etc.).
class SignerRequestRejectedException implements Exception {
  /// The ID of the request that was rejected (if available)
  final String? requestId;

  /// The original error message from the remote signer
  final String? originalMessage;

  SignerRequestRejectedException({this.requestId, this.originalMessage});

  @override
  String toString() {
    final parts = <String>['SignerRequestRejectedException'];
    if (requestId != null) {
      parts.add('Request $requestId was rejected');
    }
    if (originalMessage != null) {
      parts.add('($originalMessage)');
    }
    return parts.join(': ');
  }
}
