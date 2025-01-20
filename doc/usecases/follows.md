---
icon: people
---

[!badge variant="primary" text="high level"]

## Example

:::code source="../../packages/ndk/example/contact_list_test.dart" language="dart" range="23-28" :::

## How to use

Gives you the list of contacts for a given pubKey.

Use `broadcastSetContactList()` to set the list initially (e.g. on signup) \
`broadcastAddContact()` to add a contact to the list \
`broadcastRemoveContact()` to remove a contact from the list
