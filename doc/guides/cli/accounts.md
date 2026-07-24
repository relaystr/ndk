---
label: accounts
title: accounts
icon: person
order: 3
---

# `accounts` — manage local identities

Login, persist and switch between Nostr identities. Identities are stored in
plaintext at `~/.ndk/accounts.json` (file mode `0600`) so that subsequent
commands (`broadcast`, etc.) can reuse the active signer. Override the file
location with the `NDK_ACCOUNTS_FILE` environment variable.

> **Security warning**: the accounts file contains signing material (private
> keys or bunker connection secrets) in plaintext. Treat it like an SSH key.
> Do not commit or share it.

```
ndk accounts <sub-command> [args]
```

| Sub-command | Description |
|-------------|-------------|
| `login nsec <hex\|nsec>` | Login with a private key |
| `login npub <hex\|npub>` | Read-only login (public key only, cannot sign) |
| `login bunker <bunkerUrl>` | Connect to a NIP-46 bunker (async; prints an auth URL if the bunker requires one) |
| `login generate [name]` | Generate a fresh keypair, login and persist |
| `logout [pubkey]` | Logout current (or specific) account and remove from store |
| `list` | List persisted accounts |
| `switch <pubkey\|npub>` | Set the active account |
| `whoami` | Show the active account |

```bash
# login with an existing nsec / hex private key
ndk accounts login nsec nsec1...
ndk accounts login nsec 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef

# read-only login (no signing)
ndk accounts login npub npub1...

# connect to a NIP-46 bunker
ndk accounts login bunker "bunker://...?relay=wss://...&secret=..."

# generate a fresh keypair (nsec is printed once + saved to disk)
ndk accounts login generate

ndk accounts list
ndk accounts whoami
ndk accounts switch npub1...
ndk accounts logout
```

The first account logged in becomes the active one. Use `switch` to change
the active account; the choice persists across CLI invocations.
