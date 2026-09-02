---
icon: arrow-down-left
---

[!badge variant="primary" text="low level"]

!!!warning Relay Misbehavior
Relays can misbehave and return events that do not match your query filters.
!!!

## Usage Example

:::code source="../../packages/ndk/example/basic_test.dart" language="dart" range="23-46" :::

## When to use

Requests should be used when no other use case fits your needs. \
There is `.query` and `.subscription` representing the nostr equivalent, `.subscription` should only be used when absolutely necessary. Many relays limit the amount of simultaneous subscriptions.

## Relay Authentication (NIP-42)

Some relays only serve a request to a client that authenticated. A connection
carries at most one identity, chosen when it is opened and immutable for its
whole lifetime, so choosing an identity is really choosing a connection. The
`auth` parameter says which one a request may use:

```dart
final account = Account(
  pubkey: myPubkey,
  type: AccountType.privateKey,
  signer: Bip340EventSigner(privateKey: myPrivkey, publicKey: myPubkey),
  // Use NdkEventSigner from ndk_flutter for automatic web/native selection
);

// the account must be registered, that is where the AUTH gets signed
ndk.accounts.addAccount(pubkey: account.pubkey, type: account.type, signer: account.signer);

final response = ndk.requests.query(
  filter: Filter(kinds: [1059], authors: [myPubkey]),
  auth: RelayAuth.allow(account),
);
```

### The three policies

| policy | connection | what a relay learns |
| --- | --- | --- |
| `RelayAuth.never()` | anonymous, always | nothing. A relay that refuses the request without an identity simply does not serve it, and the request returns what the other relays gave |
| `RelayAuth.allow(a)` | anonymous, moves to one bound to `a` once a relay refuses | who you are, but only after that relay asked |
| `RelayAuth.require(a)` | bound to `a` from the start | who you are, as soon as it sends a challenge |

Report an event without ever being attributable for it:

```dart
ndk.requests.query(
  filter: Filter(kinds: [1], ids: [suspiciousEventId]),
  auth: const RelayAuth.never(),
);
```

Read your own encrypted data, which no relay should serve to anyone else:

```dart
ndk.requests.query(
  filter: Filter(kinds: [1059], authors: [myPubkey]),
  auth: RelayAuth.require(account),
);
```

### What `require` guarantees, exactly

The request is never written to a connection other than one reserved for that
account. It does not mean the relay knows who asked: NIP-42 has no way to
authenticate unprompted, so a relay that never sends a challenge never learns
the identity. It also does not mean no anonymous socket to that relay exists.
NDK connects to its bootstrap relays anonymously at startup, and the JIT engine
discovers relays on anonymous connections before routing the request onto the
bound one, which costs a second socket to the same relay.

If the account cannot sign, no connection can carry the request at all. Rather
than fall back to the anonymous one, which is what `require` rules out, it is
sent to no relay and completes right away with whatever the local cache held.
Its timeout never fires: nothing timed out, the request was impossible from the
start.

### One request, one identity

A request authenticates as at most one account. To read data belonging to
several identities, issue one request per identity: each gets its own
connection, and a relay never sees two of your identities on the same socket.

### The default

Without `auth`, a request that meets `auth-required` authenticates as the
currently logged-in account. The relay therefore decides when your identity is
revealed. Pass `auth` explicitly whenever that matters. This default is
expected to change.

### Migrating from `authenticateAs`

`authenticateAs` is deprecated. It is translated into a policy, and `auth` wins
when both are given:

| `authenticateAs` | translated to |
| --- | --- |
| `[a]` | `RelayAuth.allow(a)` |
| `[a, b]` | `RelayAuth.allow(a)`, the rest of the list is dropped |
| a list where no account can sign | `const RelayAuth.never()` |
| not specified | nothing, the default above applies |

A list never authenticated as more than one identity: only the first account
that could sign was ever used, and that is now what it says. If you passed
`[a, b]` expecting both to be covered, issue one request per identity, each
with its own `auth`.

One behaviour did change. `authenticateAs` opened an authenticated connection
before any relay asked for one, which revealed the identity even to relays that
would have served the request anonymously. `allow` waits for the refusal.

## Event sources

When events are cached, NDK may also persist source relay information.

Current behavior:

- source relays are optional provenance data
- they answer where an event was observed
- they are separate from relay delivery targets

For most apps, normal request and usecase APIs are enough and you do not need to access source relay data directly.
