import 'nip_05.dart';

/// Result of [Nip05Usecase.resolve].
///
/// Lets callers distinguish three outcomes:
/// - [Nip05Found] - the identifier was resolved (from cache or network).
/// - [Nip05NotFound] - the `.well-known/nostr.json` file was reachable but
///   does not contain the requested user (no entry under the username and no
///   fallback `_` entry).
/// - [Nip05ResolveError] - we could not determine whether the user exists.
///   Switch on its subtypes ([Nip05ResolveNetworkError],
///   [Nip05ResolveInvalidResponse]) to react accordingly.
sealed class Nip05ResolveResult {
  const Nip05ResolveResult();
}

/// The NIP-05 identifier was resolved.
class Nip05Found extends Nip05ResolveResult {
  final Nip05 data;
  const Nip05Found(this.data);
}

/// The NIP-05 file was reached but does not contain the requested user.
class Nip05NotFound extends Nip05ResolveResult {
  const Nip05NotFound();
}

/// We could not determine whether the user exists.
///
/// Sealed: switch on [Nip05ResolveNetworkError] vs
/// [Nip05ResolveInvalidResponse] to tell a transient transport failure
/// from a server returning a body we cannot parse.
sealed class Nip05ResolveError extends Nip05ResolveResult {
  /// The underlying error that caused the resolution to fail.
  Object get cause;
  const Nip05ResolveError();
}

/// We could not fetch the `.well-known/nostr.json` file.
///
/// Covers DNS failures, timeouts, connection refused, and non-2xx HTTP
/// responses. Often transient - safe to retry later.
class Nip05ResolveNetworkError extends Nip05ResolveError {
  @override
  final Object cause;
  const Nip05ResolveNetworkError(this.cause);
}

/// The file was fetched but could not be interpreted as a valid nostr.json.
///
/// Covers malformed JSON bodies and unexpected response schemas (e.g.
/// missing `names` field, wrong types). The server is misconfigured.
class Nip05ResolveInvalidResponse extends Nip05ResolveError {
  @override
  final Object cause;
  const Nip05ResolveInvalidResponse(this.cause);
}
