# Architecture Decision Record: Relay authentication

Title: Who a query, subscription, broadcast or Blossom operation authenticates as

## status

proposed

Updated on 2026-09-25

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

### AuthPolicy

```dart
sealed class AuthPolicy {
  const factory AuthPolicy.never();               // (url, null), never sends AUTH
  const factory AuthPolicy.allow(Account a);      // (url, null), moves to (url, a) if refused
  const factory AuthPolicy.require(Account a);    // (url, a) from the start
}

ndk.broadcast.broadcast(
  nostrEvent: report,
  auth: const AuthPolicy.never(),
);
```

### AuthHandler

```dart
typedef AuthHandler = Future<bool> Function(String url, String pubkey);
```

Configured once on the NDK config, asked before a pubkey authenticates on a relay or a
Blossom server.

| `auth` | without handler | with handler |
| --- | --- | --- |
| `never()` | reveals no identity | reveals no identity, never asked |
| `allow(a)`, `require(a)` | authenticates as `a` | authenticates as `a` where the handler accepts |
| absent | reveals no identity | authenticates as the default account where the handler accepts |

The default account is the logged one, or a broadcast's author when it is registered. A
Blossom read has none and stays anonymous.

`require` asks before sending, one URL at a time: a request on three relays accepted on two
goes out on those two only. So does a Blossom write without `auth`, which authorises by
default. The rest asks after a refusal.

A relay is asked when a connection bound to that pubkey opens, a Blossom server once per
operation.
