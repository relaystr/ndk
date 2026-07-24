---
label: files
title: files
icon: upload
order: 6
---

# `files` — high-level file management

A convenience wrapper over Blossom that auto-resolves user server lists and
handles sha256-in-URL detection transparently. See the
[files usecase](/usecases/files.md). For lower-level control, use the
[`blossom`](blossom.md) command.

```
ndk files <sub-command> [args]
```

| Sub-command | Description |
|-------------|-------------|
| `upload <filePath>` | Upload a local file, streaming hashing/upload/mirror progress |
| `download <url> <outputPath>` | Download to disk (blossom sha256 URL or plain HTTPS) |
| `delete <sha256>` | Delete a blob from its server(s) |
| `check <url>` | Resolve a URL to a known-alive mirror |

## Options

| Option | Description |
|--------|-------------|
| `--server <url>` (repeatable) | Blossom server(s); defaults to the user server list |
| `--pubkey <hex\|npub>` | Server-list owner (for download/check of someone else's blobs) |
| `--content-type <mime>` | Override mime type (`upload`) |
| `--media` | Server-side media optimisation (`upload`, [BUD-05]) |

## Examples

```bash
# upload to your default blossom servers (requires login for signing)
ndk accounts login nsec nsec1...
ndk files upload ~/photos/cat.jpg

# download a blossom URL to disk
ndk files download "https://cdn.example.com/<sha256>.jpg" ~/out.jpg

# delete by sha256
ndk files delete 0123...abcdef

# check that a URL resolves to an alive server
ndk files check "https://cdn.example.com/<sha256>.jpg" --pubkey npub1...
```
