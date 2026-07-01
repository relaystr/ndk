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

## Current behavior

Contact lists behave as replaceable event state.

That means:

- reads return the latest visible contact list for the pubkey
- expired or deleted older versions are not returned
- repeated reads can return cached results
- `forceRefresh` refreshes from relays

When mutating the logged-in user's contact list:

- NDK refreshes first when needed to avoid overwriting newer remote state
- NDK publishes a newer replaceable version of the full contact list
- the resulting event is cached for later reads
