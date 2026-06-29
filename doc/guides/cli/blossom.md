---
label: blossom
title: blossom
icon: server
order: 7
---

# `blossom` — low-level Blossom operations

Direct access to the Blossom protocol (BUD-*) and the user server list
(kind `10063`). Use this when you need control that
[`files`](files.md) doesn't expose. See the
[blossom usecase](/usecases/blossom.md).

```
ndk blossom <sub-command> [args]
```

| Sub-command | Description |
|-------------|-------------|
| `upload <filePath>` | Upload a local file (hash → upload → mirror, streamed) |
| `download <sha256> <outputPath>` | Download a blob by sha256 to disk |
| `delete <sha256>` | Delete a blob |
| `list [pubkey]` | List blobs for a pubkey (defaults to active account) |
| `mirror <sourceUrl> --server <url>...` | Mirror an existing blob to new server(s) |
| `check <sha256>` | Check blob existence, return an alive URL |
| `servers list [pubkey]` | Show a user's kind `10063` server list |
| `servers publish <url> [url ...]` | Publish your own server list (login required) |

## Options

| Option | Description |
|--------|-------------|
| `--server <url>` (repeatable) | Blossom server(s); defaults to the user server list |
| `--pubkey <hex\|npub>` | Server-list owner |
| `--content-type <mime>` | Override mime type (`upload`) |
| `--media` | Server-side media optimisation (`upload`) |
| `--auth` | Use signed GET (`download`, `check`, `list`) |
| `--since <iso\|unix>` | `list`: only blobs after this date |
| `--until <iso\|unix>` | `list`: only blobs before this date |

## Examples

```bash
# list someone's blossom servers
ndk blossom servers list npub1...

# publish your own server list (order matters — first = most trusted)
ndk accounts login nsec nsec1...
ndk blossom servers publish https://cdn.example.com https://cdn.backup.io

# list all blobs owned by the active account on a specific server
ndk blossom list --server https://cdn.example.com

# mirror an existing blob to a second server
ndk blossom mirror "https://cdn.example.com/<sha256>.pdf" \
    --server https://cdn.backup.io

# download a blob straight to disk
ndk blossom download 0123...abcdef ~/blob.bin
```
