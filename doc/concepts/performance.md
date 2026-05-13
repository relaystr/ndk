## Performance

There are two main constrains that we aim for: battery/compute and network bandwidth.

**network**\
Inbox/Outbox (gossip) is our main pillar to help avoid unnecessary nostr requests. We try to leverage the cache as much as possible. \
Even splitting the users filters into smaller relay tailored filters if we know the relay has the information we need.

**compute**\
Right now the most compute intensive operation is verifying signatures. \
We use the cache to determine if we have already seen the event and only if it is unknown signature verification is done. \
To make the operation as optimized as possible we strongly recommend using `PlatformEventVerifier` from the `ndk_flutter` package. It automatically selects the fastest verifier for the current platform (`WebEventVerifier` on web, `RustEventVerifier` on native).

For pure Dart applications (without Flutter), use `RustEventVerifier()` directly on native platforms.
