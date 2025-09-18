---
order: 60
icon: shield-check
---

# NIP-13: Proof of Work

Add computational proof-of-work to events for spam prevention.

```dart
final minedEvent = Nip01Event(
  pubKey: keyPair.publicKey,
  kind: 1,
  tags: [],
  content: 'message',
).minePoW(12);

if (minedEvent.checkPoWDifficulty(10)) {
  print('Valid PoW, event has difficulty >= 10');
}
```

## API

**Event Methods:**
- `minePoW(difficulty)` - Add PoW
- `checkPoWDifficulty(target)` - Verify
- `powDifficulty` - Get difficulty

**Nip13 Class:**
- `Nip13.mineEvent(event, difficulty)`
- `Nip13.validateEvent(event)`
