# Req Command Reference

Query Nostr relays for events and stream JSON to stdout.

```
ndk req [-k <kind>] [-l <limit>] [-t <seconds>] <relay1> [relay2 ...]
```

## Options

| Flag | Default | Description |
|------|---------|-------------|
| `-k`, `--kind <n>` | (none) | Filter by event kind (integer) |
| `-l`, `--limit <n>` | `10` | Max events to return |
| `-t`, `--timeout <sec>` | `12` | Query timeout in seconds |
| `-h`, `--help` | — | Show usage |

At least one relay URL is required. `wss://` prefix is optional — the CLI prepends it automatically.

## Output

One JSON object per line (newline-delimited JSON):

```json
{"id":"...","pubkey":"...","created_at":1234567890,"kind":1,"tags":[...],"content":"...","sig":"..."}
```

## Examples

```bash
# fetch 10 events from a relay (default limit)
ndk req relay.damus.io

# fetch kind-1 notes, limit 5, 20s timeout
ndk req -k 1 -l 5 -t 20 wss://relay.damus.io wss://nos.lol

# pipe into jq
ndk req -k 1 -l 3 relay.damus.io | jq '.content'
```

## Notes

- `cacheRead` and `cacheWrite` both disabled — always hits relays directly
- Relay URLs: accepts bare hostnames (`relay.damus.io`), prefixed (`wss://relay.damus.io`), or with path
