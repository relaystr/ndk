# Skills

Agent skills for Claude Code. Each skill is a self-contained directory with a `SKILL.md` manifest.

## Available Skills

### [ndk](ndk/SKILL.md)

> Nostr Development Kit CLI — wallet management (NWC/Cashu) and relay event queries over the Nostr network.

**Version:** 0.8.4 · **License:** MIT

#### 🚀 Install with single command

```bash
npx skills add relaystr/ndk
```

| Reference | Description |
|-----------|-------------|
| [Installation](ndk/references/installation.md) | install.sh usage, env vars, PATH setup |
| [Commands](ndk/references/commands.md) | Global options and command list |
| [Wallets](ndk/references/wallets.md) | `add nwc/cashu`, `list`, `remove`, `receive`, `send`, `balance`, `budget` |
| [Req](ndk/references/req.md) | Query Nostr relays, filter by kind/limit/timeout, NDJSON output |
| [Notes](ndk/references/notes.md) | Local DB path, default wallet selection, verbosity flags, platform support |

---

## Adding a Skill

1. Create `skills/<name>/` directory
2. Add `SKILL.md` with frontmatter (`name`, `description`, `license`, `metadata`)
3. Add `references/` sub-files for detailed sections
4. Add entry to this README
