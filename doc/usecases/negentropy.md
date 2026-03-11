---
icon: sync
---

## Basic reconciliation

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
  final events = await ndk.query(filter: filter, paginate: true);
} on Nip77TimeoutException catch (e) {
  print('Reconciliation timed out: ${e.timeout}');
}
```

## When to use

✅ **Good for:**
- Syncing large event sets (long history)
- Periodic reconciliation with home relays
- Ensuring relay has all your events
- Discovering events you missed

❌ **Use other methods for:**
- Small queries → use `ndk.query()`
