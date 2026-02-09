/// Exception thrown when a signer request is cancelled by the user.
///
/// This is a "soft cancel" - the request is removed from the pending list
/// and the caller receives this exception, but the remote signer (bunker,
/// browser extension, etc.) may still have the request pending.
class SignerRequestCancelledException implements Exception {
  /// The ID of the request that was cancelled
  final String requestId;

  SignerRequestCancelledException(this.requestId);

  @override
  String toString() =>
      'SignerRequestCancelledException: Request $requestId was cancelled';
}
