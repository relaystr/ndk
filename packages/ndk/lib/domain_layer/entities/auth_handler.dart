/// Asked before [pubkey] authenticates on [url], a relay or a Blossom server.
/// Answering false keeps that identity from being revealed there.
typedef AuthHandler = Future<bool> Function(String url, String pubkey);

/// Pauses the timeout of an operation while it waits on something that is not
/// the network's to answer, such as an [AuthHandler] or a remote signer.
abstract interface class TimeoutPausable {
  /// Stops the timer, keeping the time left. Calls nest.
  void pauseTimeout();

  /// Restarts the timer with the time left once every pause has resumed.
  void resumeTimeout();
}
