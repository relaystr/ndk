#!/usr/bin/env bash
set -euo pipefail

# --- config ---
REPO="relaystr/ndk"
BIN_NAME="ndk"
INSTALL_DIR="${NDK_INSTALL_DIR:-$HOME/.local/bin}"
VERSION="${NDK_VERSION:-latest}"

# --- helpers ---
info()  { echo -e "\033[1;34minfo\033[0m  $*"; }
ok()    { echo -e "\033[1;32m ok \033[0m  $*"; }
err()   { echo -e "\033[1;31merror\033[0m $*" >&2; exit 1; }

need() {
  command -v "$1" &>/dev/null || err "required tool not found: $1"
}

# --- detect platform ---
detect_target() {
  local os arch
  os="$(uname -s)"
  arch="$(uname -m)"

  case "$os" in
    Linux)  os="linux" ;;
    Darwin) os="macos" ;;
    *)      err "unsupported OS: $os" ;;
  esac

  case "$arch" in
    x86_64)          arch="x64" ;;
    aarch64 | arm64) arch="arm64" ;;
    *)               err "unsupported architecture: $arch" ;;
  esac

  echo "${os}-${arch}"
}

# --- resolve version ---
resolve_version() {
  if [ "$VERSION" = "latest" ]; then
    need curl
    VERSION=$(
      curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
        | grep '"tag_name"' \
        | sed -E 's/.*"v?([^"]+)".*/\1/'
    )
    [ -n "$VERSION" ] || err "could not determine latest version"
  fi
  echo "$VERSION"
}

# --- main ---
main() {
  need curl

  local target version download_url tmp_file

  target="$(detect_target)"
  version="$(resolve_version)"
  download_url="https://github.com/${REPO}/releases/download/v${version}/${BIN_NAME}-${target}"

  info "installing ${BIN_NAME} ${version} (${target})"
  info "from ${download_url}"

  # download to temp file
  tmp_file="$(mktemp)"
  trap 'rm -f "$tmp_file"' EXIT

  curl -fsSL --progress-bar "$download_url" -o "$tmp_file" \
    || err "download failed — check that release asset exists: ${download_url}"

  chmod +x "$tmp_file"

  # quick sanity check
  "$tmp_file" --version &>/dev/null \
    || err "downloaded binary failed to run — wrong platform?"

  # install
  mkdir -p "$INSTALL_DIR"
  mv "$tmp_file" "${INSTALL_DIR}/${BIN_NAME}"

  ok "${BIN_NAME} installed to ${INSTALL_DIR}/${BIN_NAME}"

  # PATH hint
  if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
    echo ""
    echo "  Add this to your shell profile (~/.bashrc / ~/.zshrc):"
    echo ""
    echo "    export PATH=\"\$PATH:${INSTALL_DIR}\""
    echo ""
  fi
}

main "$@"