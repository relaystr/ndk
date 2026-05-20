import 'nip_05.dart';

/// Result of [Nip05Usecase.resolve].
///
/// Lets callers distinguish three outcomes:
/// - [Nip05Found] - the identifier was resolved (from cache or network).
/// - [Nip05NotFound] - the `.well-known/nostr.json` file was reachable but
///   does not contain the requested user (no entry under the username and no
///   fallback `_` entry).
/// - [Nip05ResolveError] - we could not determine whether the user exists:
///   network failure, non-2xx HTTP status, malformed body, or unexpected
///   schema. Inspect [Nip05ResolveError.cause] for the underlying error.
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

/// We could not determine whether the user exists. Covers network failures
/// (DNS, timeout, connection refused), non-2xx HTTP responses (e.g. 404 / 500),
/// malformed JSON bodies, and unexpected response schemas.
class Nip05ResolveError extends Nip05ResolveResult {
  final Object cause;
  const Nip05ResolveError(this.cause);
}
