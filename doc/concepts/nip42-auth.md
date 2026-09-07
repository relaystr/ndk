# NIP-42 Authentication

NDK handles NIP-42 relay authentication automatically. When a relay requires authentication, NDK will sign and send AUTH events, then retry the original request.

A connection carries at most one identity, chosen when it is opened and immutable for its whole lifetime, so a request that authenticates moves to its own connection.

Which identity a request may be attributed to is the `auth` parameter, see [requests](/usecases/requests.md#relay-authentication-nip-42).
