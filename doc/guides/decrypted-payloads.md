---
icon: lock
order: 95
---

# Decrypted Payload Caching

NDK can cache decrypted plaintext separately from the original encrypted event.

## Behavior

When a supported usecase needs encrypted content:

- NDK first checks for a cached plaintext sidecar
- if plaintext is already cached, the signer does not need to decrypt again
- if plaintext is missing, NDK decrypts and stores it in the cache backend

The original event remains unchanged and stays encrypted in the canonical event store.

## Cache key

Decrypted plaintext is cached per:

- event id
- viewer pubkey

This means the same event can have different cached plaintext entries for different viewers.

## What this helps with

This is especially useful when:

- the app re-renders the same encrypted content repeatedly
- decryption depends on a remote signer
- the signer is slow compared to local cache reads

## Current use

Current NDK usecases that can reuse cached decrypted payloads include:

- `GiftWrap`
- private `Nip51List` content through `Lists`
- NIP-17 direct message flows that unwrap gift-wrapped messages

## What apps should assume

- cached plaintext is an optimization and a persisted sidecar
- encrypted event content is still the authoritative wire format
- deleting the original event from cache should also remove the associated decrypted sidecar
- using a persistent cache backend allows decrypted sidecars to survive restart
