# NIP-42 Authentication

NDK handles NIP-42 relay authentication automatically. When a relay requires authentication, NDK will sign and send AUTH events, then retry the original request.
