---
icon: list-ordered
---

[!badge variant="primary" text="low level"]

## Example

:::code source="../../packages/ndk/example/user_relay_list_test.dart" language="dart" range="23-29" title="" :::

## When to use

User relay lists provides you with the relays for a given user. \
It orients itself on nip65 but also uses data from nip02 in case nip65 is not available. \
It's used by inbox/outbox; only use this if you are doing something custom that is not directly handled by inbox/outbox.

## Current behavior

User relay list resolution combines relay information from:

- NIP-65 relay list events
- contact-list relay content when needed

Behavior:

- the cache stores a computed user relay list projection
- that projection is refreshed from authoritative events when needed
- repeated reads can return cached projections

For DM relay lists, `getDmRelays()` reads the latest visible relay list event for the user and can refresh from relays when requested.
