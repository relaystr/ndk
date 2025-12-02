---
icon: arrow-down-left
---

[!badge variant="primary" text="low level"]

!!!warning Relay Misbehavior
Relays can misbehave and return events that do not match your query filters.
!!!

## Usage Example

:::code source="../../packages/ndk/example/basic_test.dart" language="dart" range="23-46" :::

## When to use

Requests should be used when no other use case fits your needs. \
There is `.query` and `.subscription` representing the nostr equivalent, `.subscription` should only be used when absolutely necessary. Many relays limit the amount of simultaneous subscriptions.
