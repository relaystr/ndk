---
icon: verified
---

[!badge variant="primary" text="high level"]

## Example

```dart
final result = await ndk.nip05.check(
  nip05: "username@domain.example",
  pubkey:
      "3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d",
);
print("valid? ${result.valid}, relays: ${result.relays}");

```

## When to use

Uses caching so there are no repeated network requests if you call this multiple times. \
Use this when you need to verify a domain. \
If you call this, the result is automatically used as inbox/outbox information.

:::code source="../../packages/ndk/lib/config/nip_05_defaults.dart" language="dart" range="4-5" title="default cache time" :::
