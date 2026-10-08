---
icon: comment-discussion
label: DM
---

[!badge variant="primary" text="high level"]

## When to use

Use `ndk.dms` for direct-message style conversations based on NIP-17 gift-wrapped messages.

## Current behavior

`ndk.dms` provides:

- sending a message to a peer
- loading all conversations for the logged-in account
- loading a single conversation with one peer
- loading a cache-only snapshot of conversations
- parsing a wrapped message into a `Nip17Message`

## Relay behavior

Sending uses DM relay lists for:

- the recipient
- the sender

That means:

- the recipient receives a wrapped copy on their DM relays
- the sender receives a wrapped copy on their own DM relays
- the sender can load their own conversation history from the same model

If either side does not have the required DM relay list, sending fails.

## Loading conversations

`loadConversations()`:

- loads wrapped messages addressed to the logged-in user
- unwraps them into message objects
- groups them by peer pubkey
- sorts messages inside a conversation by creation time
- sorts conversations by latest message time

`loadConversationsSnapshot()`:

- reads only from cache
- does not require a network round trip
- is useful for immediate UI rendering

## Existing conversations from other clients

NDK can load existing conversations created by other clients as long as:

- the messages are stored on relays queried by the logged-in user's DM relay list
- the logged-in account can decrypt the wrapped payloads

## Decryption behavior

Conversation loading can reuse cached decrypted payload sidecars.

That means:

- previously unwrapped messages can load from cache
- repeated UI reads do not need to decrypt every message again
- persistent cache backends keep that benefit across restarts
