---
icon: server
---

[!badge variant="primary" text="low level"]

## Example

:::code source="../../packages/ndk/test/relays/relay_sets_test.dart" language="dart" range="245-260" title="" :::



## When to use

Calculates the best relays for a given set of pubkeys. Its used by inbox/outbox. \
This allows for granular control in the relaySets engine. \
E.g. calculating the best relays for a thread view.