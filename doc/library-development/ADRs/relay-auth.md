# Architecture Decision Record: Relay authentication

Title: Relay authentication - who a query, subscription or broadcast authenticates as

## status

accepted

Updated on 2026-09-02

## contributors

- Main contributor(s): nogringo

- Reviewer(s): frnandu, 1leo

- Final decision made by: frnandu, 1leo, nogringo

## Context and Problem Statement

A connection carries at most one identity, immutable for its whole lifetime
(`RelayConnectionKey`). The caller-facing half is missing: `authenticateAs: List<Account>?`
cannot say "never be attributable for this request", nor "authenticate before asking".

And the absent case is the leaky one. With no `authenticateAs`, a request that meets
`auth-required` falls back to the logged account, so the relay decides when an identity is
revealed.

## Main Proposal

### RelayAuth

```dart
sealed class RelayAuth {
  const factory RelayAuth.never();               // (url, null), never sends AUTH
  const factory RelayAuth.allow(Account a);      // (url, null), moves to (url, a) if refused
  const factory RelayAuth.require(Account a);    // (url, a) from the start
}

ndk.broadcast.broadcast(
  nostrEvent: report,
  auth: const RelayAuth.never(),
);
```

### RelayAuthHandler

```dart
typedef RelayAuthHandler = Future<Account?> Function(RelayAuthRequest);

sealed class RelayAuthRequest {
  final String relayUrl;
  final Account? account;
  final AuthRefusal? refusal; // null when asked before any refusal
}

class ReadAuthRequest extends RelayAuthRequest {
  final Filter? filter;
  final String? requestName;
}

class WriteAuthRequest extends RelayAuthRequest {
  final Nip01Event event;
}

class AuthRefusal {
  final AuthReason reason; // authRequired, restricted, blocked, rateLimited
  final String message;    // raw relay message
}
```

Configured once on the NDK config, consulted only for `allow` and `require`. With no handler,
both authenticate automatically.

Returning `null` means do not authenticate.


## Final Notes

Proposal Accepted
by: frnandu, 1leo, nogringo
