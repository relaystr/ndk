/// Why a connection to a relay was opened.
///
/// Purely diagnostic: it is recorded on [Relay] when the connection is created
/// so a connection can be traced back to whatever asked for it. Nothing routes
/// on it.
enum ConnectionSource {
  unknown,
  seed,
  pubkeyStrategy,
  broadcastOwn,
  broadcastOther,
  broadcastSpecific,

  /// a relay the caller named directly, e.g. a request's `explicitRelays`
  explicit,

  /// a relay named by the request's relay set
  relaySet,
  connectionProbe,
  nip51Search,
}
