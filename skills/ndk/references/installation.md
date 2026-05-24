# Installation

## Single command (Linux / macOS)

```bash
curl -fsSL https://raw.githubusercontent.com/relaystr/ndk/refs/heads/master/install.sh | bash
```

Installs to `~/.local/bin/ndk` (user mode, default).

## Install options

```bash
# system-wide (/usr/bin/ndk) — may require sudo
curl -fsSL https://raw.githubusercontent.com/relaystr/ndk/refs/heads/master/install.sh | bash -s -- --system

# specific version
NDK_VERSION=v0.8.3 curl -fsSL ... | bash

# latest pre-release
NDK_VERSION=latest-pre curl -fsSL ... | bash
```

## Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `NDK_VERSION` | `latest` | Version tag, `latest`, or `latest-pre` |
| `NDK_PRERELEASE` | `0` | When `1` and `NDK_VERSION=latest`, picks latest pre-release |
| `NDK_INSTALL_MODE` | `user` | `user` or `system` |
| `NDK_INSTALL_DIR` | `~/.local/bin` | Binary destination (user mode) |
| `NDK_USER_LIB_DIR` | `~/.local/lib` | Shared libs destination (user mode) |
| `NDK_SYSTEM_BIN_DIR` | `/usr/bin` | Binary destination (system mode) |
| `NDK_SYSTEM_LIB_DIR` | `/usr/lib` | Shared libs destination (system mode) |

## PATH

If `~/.local/bin` is not in `PATH`, add to shell profile:

```bash
export PATH="$PATH:$HOME/.local/bin"
```

Verify: `ndk --version`

Releases: https://github.com/relaystr/ndk/releases
