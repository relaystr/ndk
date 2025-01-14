## Performance

There are two main constrains that we aim for: battery/compute and network bandwidth.

**network**\
Inbox/Outbox (gossip) is our main pillar to help avoid unnecessary nostr requests. We try to leverage the cache as much as possible. \
Even splitting the users filters into smaller relay tailored filters if we know the relay has the information we need.

**compute**\
Right now the most compute intensive operation is verifying signatures. \
We use the cache to determine if we have already seen the event and only if it is unknown signature verification is done. \
To make the operation as optimized as possible we strongly recommend using `RustEventVerifier()` because it uses a separate thread for verification.