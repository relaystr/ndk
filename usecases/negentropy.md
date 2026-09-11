[!badge variant="primary" text="low level"]

## Basic reconciliation

```dart
final filter = Filter(
  authors: ['your_pubkey'],
);

final response = ndk.nip77.reconcile(
  relayUrl: 'wss://relay.example.com',
  filter: filter,
);

// Wait for completion
final result = await response.future;
print('Sync complete: ${result.needIds.length} events to fetch, ${result.haveIds.length} events to broadcast');
```

## Relay authentication (NIP-42)

Some relays only reconcile with a client that authenticated, the same way they
only serve a request to one. The `auth` parameter says which identity the
reconciliation may be attributed to, exactly like on
[requests](/usecases/requests.md#relay-authentication-nip-42):

```dart
final response = ndk.nip77.reconcile(
  relayUrl: 'wss://relay.example.com',
  filter: Filter(authors: [myPubkey]),
  auth: RelayAuth.require(account),
);
```

| policy | connection | what a relay learns |
| --- | --- | --- |
| `RelayAuth.never()` | anonymous, always | nothing. A relay that refuses the negotiation without an identity simply does not reconcile |
| `RelayAuth.allow(a)` | anonymous, moves to one bound to `a` once the relay refuses | who you are, but only after that relay asked |
| `RelayAuth.require(a)` | bound to `a` from the start | who you are, as soon as it sends a challenge |

Without `auth`, a refused negotiation authenticates as the currently logged-in
account, so the relay decides when your identity is revealed. Pass `auth`
explicitly whenever that matters.

If `require` names an account that cannot sign, no connection can carry the
reconciliation. Rather than fall back to the anonymous one, which is what
`require` rules out, nothing is sent and `reconcile` itself throws
`Nip77AuthUnavailableException`.

## Error handling

### Relay doesn't support NIP-77

```dart
try {
  final response = ndk.nip77.reconcile(
    relayUrl: 'wss://relay.example.com',
    filter: filter,
  );
  await response.future;
} on Nip77NotSupportedException catch (e) {
  print('Relay does not support NIP-77: ${e.message}');
  // Fall back to traditional query with paginate true
  ndk.requests.query(filter: filter, paginate: true);
} on Nip77TimeoutException catch (e) {
  print('Reconciliation timed out: ${e.timeout}');
}
```

### Relay requires an identity you did not give it

```dart
try {
  await ndk.nip77.reconcile(
    relayUrl: 'wss://relay.example.com',
    filter: filter,
    auth: const RelayAuth.never(),
  ).future;
} on Nip77AuthRequiredException catch (e) {
  print('Relay wants an identity: ${e.message}');
} on Nip77AuthUnavailableException catch (e) {
  print('${e.pubkey} cannot sign, nothing was sent');
}
```

## When to use

✅ **Good for:**
- Syncing large event sets (long history)
- Periodic reconciliation with home relays
- Ensuring relay has all your events
- Discovering events you missed

❌ **Use other methods for:**
- Small queries → use `ndk.requests.query()`
