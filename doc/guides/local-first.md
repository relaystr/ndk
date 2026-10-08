---
icon: sync
order: 96
---

# Local-First Behavior

NDK treats app writes and reads as local-first when the relevant data is stored in the configured cache backend.

## Publish behavior

When an event is created through NDK broadcast flows:

- the event can be written to the cache before every relay acknowledges it
- the event can become visible to app reads from that cached state
- relay delivery can continue after the initial publish call finishes

This applies to normal events as well as targeted relay delivery used for replies, reactions, and other gossip-aware publish paths.

## Delivery state

NDK keeps delivery state in the configured cache backend.

That state includes:

- aggregate event delivery status
- per-relay delivery targets
- retry timing and retry outcome

Behavior depends on the backend:

- with `MemCacheManager`, delivery state exists while the process is alive
- with a persistent backend, delivery state also survives restart

## Retry behavior

NDK retries pending delivery in the background while the app is running.

Retry behavior includes:

- retry on reconnect when a relay becomes reachable
- periodic retry for targets that are due even if connectivity state does not change
- per-event-kind retry policy differences
- permanent failure detection for relay responses that should not be retried forever

## Replaceable events

For replaceable and addressable events:

- app reads return the latest visible winner
- background delivery follows that same visible winner
- older superseded offline versions are not kept in active retry once a newer visible version exists

## Reads after write

After a local publish, app-facing reads may show the event before every relay confirms it.

This means:

- your UI can update from NDK state immediately
- relay acknowledgement is a separate concern from local visibility
- delivery progress should be treated as asynchronous

## What this means for apps

- use a persistent cache backend if you want local-first behavior to survive restart
- treat locally visible publish as durable in the cache, not necessarily fully delivered to every relay yet
- do not assume one failed relay means the publish is globally failed
- for replaceable data, assume the newest visible version is the authoritative one
