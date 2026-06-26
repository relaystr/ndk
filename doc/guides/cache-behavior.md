---
icon: database
order: 97
---

# Cache Behavior

NDK's cache persists event data, delivery state, and decrypted payload sidecars used by app-facing reads and writes.

This guide focuses on the behavior you can rely on when building an app with NDK. It does **not** cover backend implementation details.

## What gets cached

At a high level, NDK may persist:

- Nostr events
- event source relays
- pending delivery state for locally created events
- decrypted plaintext sidecars for encrypted events
- convenience projections like metadata, contact lists, and user relay lists

## What `load`-style reads mean

When NDK reads events from cache, it applies these visibility rules:

- expired events are hidden
- author-deleted events are hidden
- for replaceable and addressable events, only the latest visible winner is returned

App-facing reads return the current logical state, not raw historical storage.

## Event sources vs delivery targets

These are different concepts:

- **Event sources** answer: "where did this event come from?"
- **Delivery targets** answer: "where does this locally created event still need to be sent?"

As an app developer:

- use normal usecases and requests for reading and publishing
- only inspect low-level source relay APIs if your app explicitly needs provenance
- do not assume a source relay is automatically a pending broadcast target

## Local-first publishing

When your app broadcasts an event through normal NDK APIs:

- the event can become visible locally before every relay acknowledges it
- relay delivery progress can survive app restarts when the cache backend is persistent
- retries can continue in the background while the app is running
- replaceable events retry only the newest visible version

This lets the UI update from locally persisted state without waiting for every relay to accept the event.

## Encrypted payload cache

For encrypted content, NDK can cache decrypted plaintext separately from the original event.

This is useful when:

- the app needs to render the same DM or private list repeatedly
- decryption depends on a slow or remote signer

Important behavior:

- the original event stays encrypted in the canonical event store
- plaintext is cached in a separate sidecar keyed by event and viewer
- different viewers may have different cached plaintext results

## Convenience accessors

`metadata`, `follows`, and `userRelayLists` are high-level app APIs backed by the generic event cache.

In practice this means:

- you should keep using the high-level usecases
- you should not maintain a separate storage assumption for metadata/contact lists
- replaceable and deletion semantics are applied consistently across generic event reads and convenience accessors

## Cache eviction

Eviction behavior is:

- removing expired events
- removing author-deleted events
- removing superseded replaceable/addressable events
- optionally applying caps to visible events per kind

If background eviction scheduling is enabled, NDK uses the configured values from `NdkConfig`:

- `cacheEvictionEnabled`
- `cacheEvictionPolicy`
- `cacheEvictionStartupDelay`
- `cacheEvictionInterval`
- `runCacheEvictionOnStartup`

If you enable background eviction scheduling, NDK will periodically run the configured eviction policy while the app is alive.

## Recommended app usage

- Use a persistent `CacheManager` in real apps.
- Read through high-level usecases unless you specifically need low-level control.
- Treat local-first publish as locally durable and eventually relay-delivered.
- Configure eviction for long-lived apps with large caches.
- Let NDK manage decrypted payload caching instead of rewriting encrypted event content yourself.
