# NIP-42 Authentication

NDK handles NIP-42 relay authentication automatically. When a relay requires authentication, NDK will sign and send AUTH events, then retry the original request.

## Auth Strategies

NDK supports two authentication strategies:

### Lazy Auth (default)

```dart
final ndk = Ndk(NdkConfig(
  eventVerifier: Bip340EventVerifier(),
  cache: MemCacheManager(),
  // eagerAuth: false (default)
));
```

- AUTH is sent **only after** the relay responds with `auth-required`
- More privacy-respecting: doesn't reveal identity until necessary
- Flow: `REQ` → `CLOSED auth-required` → `AUTH` → `OK` → `REQ` (retry)

### Eager Auth

```dart
final ndk = Ndk(NdkConfig(
  eventVerifier: Bip340EventVerifier(),
  cache: MemCacheManager(),
  eagerAuth: true,
));
```

- AUTH is sent **immediately** when the relay sends a challenge
- Faster for relays that always require auth
- Flow: `AUTH challenge` → `AUTH` → `OK` → `REQ`
