---
icon: arrow-down-left
---

[!badge variant="primary" text="low level"]

## Usage Example

:::code source="../../packages/ndk/example/basic_test.dart" language="dart" range="23-46" :::

## When to use

Requests schould be used when no other usecase fits your needs. \
Ther is `.query` and `.subscription` representing the nostr equivalent, `.subscription` schould only be used when absolutely necessary. Many relays limit the amout of simultanious subscriptions.
