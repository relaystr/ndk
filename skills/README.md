# Skills

Agent skills for Claude Code. Each skill is a self-contained directory with a `SKILL.md` manifest.

## Available Skills

### CLI Tools

#### [ndk](ndk/SKILL.md)

> NDK CLI tool — wallet management (NWC/Cashu) and relay event queries via the `ndk` binary.

#### 🚀 Install with single command

```bash
npx skills add relaystr/ndk
```

| Reference | Description |
| --------- | ----------- |
| [Installation](ndk/references/installation.md) | install.sh usage, env vars, PATH setup |
| [Commands](ndk/references/commands.md) | Global options and command list |
| [Wallets](ndk/references/wallets.md) | `add nwc/cashu`, `list`, `remove`, `receive`, `send`, `balance`, `budget` |
| [Req](ndk/references/req.md) | Query Nostr relays, filter by kind/limit/timeout, NDJSON output |
| [Notes](ndk/references/notes.md) | Local DB path, default wallet selection, verbosity flags, platform support |

---

### Dart Libraries

#### [ndk-core](ndk-core/SKILL.md)

> NDK core Dart library — event requests, relay management, accounts, wallets, zaps, files, and more.

#### 🚀 Install ndk-core

```bash
npx skills add relaystr/ndk-core
```

| Reference | Description |
| --------- | ----------- |
| [Setup](ndk-core/references/setup.md) | `pub add`, NdkConfig, engines, cache options |
| [Requests](ndk-core/references/requests.md) | query(), subscription(), Filter, Nip01Event |
| [Accounts](ndk-core/references/accounts.md) | addAccount, switchAccount, signers, bunkers |
| [Usecases](ndk-core/references/usecases.md) | All `ndk.*` accessors (metadata, follows, files, broadcast…) |
| [Wallets](ndk-core/references/wallets.md) | NWC connect/pay/invoice, Cashu setup |

---

### Flutter Libraries

#### [ndk-flutter](ndk-flutter/SKILL.md)

> Flutter UI package — ready-to-use Nostr widgets, login/account management, wallet UI.

#### 🚀 Install ndk-flutter

```bash
npx skills add relaystr/ndk-flutter
```

| Reference | Description |
| --------- | ----------- |
| [Setup](ndk-flutter/references/setup.md) | `flutter pub add`, l10n, NdkFlutter init, app startup |
| [Widgets](ndk-flutter/references/widgets.md) | NBanner, NPicture, NName, NLogin, NSwitchAccount, NWallets… |
| [Accounts](ndk-flutter/references/accounts.md) | save/restoreAccountsState, signers, account kinds |

---

## Adding a Skill

1. Create `skills/<name>/` directory
2. Add `SKILL.md` with frontmatter (`name`, `description`, `metadata`)
3. Add `references/` sub-files for detailed sections
4. Add entry to this README
