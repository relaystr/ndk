# NIP-42 Authentication

NDK handles NIP-42 relay authentication automatically. When a relay requires authentication, NDK will sign and send AUTH events, then retry the original request.

A connection carries at most one identity, chosen when it is opened and immutable for its whole lifetime, so a request that authenticates moves to its own connection.

Which identity a request may be attributed to is the `auth` parameter, see [requests](/usecases/requests.md#relay-authentication-nip-42). The same parameter says which identity a negentropy reconciliation may use, see [negentropy](/usecases/negentropy.md#relay-authentication-nip-42), and which identity an event may be published under, see [broadcast](/usecases/broadcast.md#relay-authentication-nip-42).

## AuthHandler

Asked before a pubkey authenticates on a relay or a Blossom server. Without one, a request that does not pass `auth` reveals no identity.

```dart
final ndk = Ndk(NdkConfig(
  eventVerifier: Bip340EventVerifier(),
  cache: MemCacheManager(),
  authHandler: (url, pubkey) => askUser(url, pubkey),
));
```

- `never()` is never asked about. `allow(a)`, `require(a)` and a request without `auth` authenticate only where the handler returns true.
- `require` asks before sending, so a relay or server it refuses receives nothing. The rest asks once a relay or server refused.
- A relay is asked when a connection bound to that pubkey opens, a Blossom server once per operation.
- The time spent waiting on the handler does not count against the request timeout.

`authHandler: (_, _) async => true` restores the previous default: authenticate as the logged-in account wherever asked.
