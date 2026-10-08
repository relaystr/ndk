#!/usr/bin/env bash
set -euo pipefail

# --- config ---
REPO="relaystr/ndk"
BIN_NAME="ndk"
INSTALL_DIR="${NDK_INSTALL_DIR:-$HOME/.local/bin}"
VERSION="${NDK_VERSION:-latest}"
PRERELEASE="${NDK_PRERELEASE:-0}"
INSTALL_MODE="${NDK_INSTALL_MODE:-user}"
USER_LIB_DIR="${NDK_USER_LIB_DIR:-$HOME/.local/lib}"
SYSTEM_BIN_DIR="${NDK_SYSTEM_BIN_DIR:-/usr/bin}"
SYSTEM_LIB_DIR="${NDK_SYSTEM_LIB_DIR:-/usr/lib}"

# --- helpers ---
info()  { echo -e "\033[1;34minfo\033[0m  $*"; }
ok()    { echo -e "\033[1;32m ok \033[0m  $*"; }
err()   { echo -e "\033[1;31merror\033[0m $*" >&2; exit 1; }

need() {
  command -v "$1" &>/dev/null || err "required tool not found: $1"
}

is_truthy() {
  case "$1" in
    1 | true | TRUE | yes | YES) return 0 ;;
    *) return 1 ;;
  esac
}

github_api_get() {
  local url="$1"
  local token="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
  local headers=(
    -H "Accept: application/vnd.github+json"
    -H "X-GitHub-Api-Version: 2022-11-28"
  )

  if [ -n "$token" ]; then
    headers+=(-H "Authorization: Bearer ${token}")
  fi

  curl -fsSL "${headers[@]}" "$url"
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

# --- resolve version/tag ---
resolve_tag() {
  local use_prerelease="0"
  local tag=""
  local release_url=""

  case "$VERSION" in
    latest-pre | latest-prerelease) use_prerelease="1" ;;
    latest) is_truthy "$PRERELEASE" && use_prerelease="1" ;;
  esac

  if [ "$VERSION" = "latest" ] || [ "$VERSION" = "latest-pre" ] || [ "$VERSION" = "latest-prerelease" ]; then
    need curl

    if [ "$use_prerelease" = "1" ]; then
      tag=$(
        github_api_get "https://api.github.com/repos/${REPO}/releases" \
          | awk '
              BEGIN { tag=""; draft=0; found="" }
              /"tag_name":/ {
                if (tag == "") {
                  tag = $0
                  sub(/^.*"tag_name":[[:space:]]*"/, "", tag)
                  sub(/".*$/, "", tag)
                }
              }
              /"draft":/ {
                draft = ($0 ~ /true/) ? 1 : 0
              }
              /"prerelease":/ {
                if ($0 ~ /true/ && draft == 0 && tag != "") {
                  if (found == "") {
                    found = tag
                  }
                }
                tag=""
                draft=0
              }
              END {
                if (found != "") {
                  print found
                }
              }
            '
      )
      [ -n "$tag" ] || err "could not determine latest pre-release version"
    else
      release_url="$(
        curl -fsSLI -o /dev/null -w '%{url_effective}' \
          "https://github.com/${REPO}/releases/latest"
      )"
      case "$release_url" in
        */releases/tag/*) tag="${release_url##*/}" ;;
      esac
      [ -n "$tag" ] || err "could not determine latest version"
    fi
  else
    if [[ "$VERSION" =~ ^v[0-9] ]]; then
      tag="$VERSION"
    else
      tag="v${VERSION}"
    fi
  fi

  echo "$tag"
}

check_sudo_needed() {
  local path parent
  for path in "$@"; do
    if [ -e "$path" ]; then
      [ -w "$path" ] || return 0
    else
      parent="$(dirname "$path")"
      [ -w "$parent" ] || return 0
    fi
  done
  return 1
}

run_priv() {
  if [ "${USE_SUDO:-0}" = "1" ]; then
    sudo "$@"
  else
    "$@"
  fi
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --system) INSTALL_MODE="system" ;;
      --user) INSTALL_MODE="user" ;;
      -h | --help)
        cat <<EOF
Usage: install.sh [--user|--system]

Install mode (Linux):
  --user      Install to user paths (default):
              - binary: NDK_INSTALL_DIR (default: ~/.local/bin)
              - libs:   NDK_USER_LIB_DIR (default: ~/.local/lib)
  --system    Install to system paths:
              - binary: NDK_SYSTEM_BIN_DIR (default: /usr/bin)
              - libs:   NDK_SYSTEM_LIB_DIR (default: /usr/lib)

Env vars:
  NDK_VERSION       Version or tag. Also supports latest, latest-pre.
  NDK_PRERELEASE    When truthy and NDK_VERSION=latest, picks latest pre-release.
  NDK_INSTALL_MODE  user|system (Linux)
  GH_TOKEN           GitHub token for authenticated pre-release discovery.
  GITHUB_TOKEN       Fallback when GH_TOKEN is not set.
EOF
        exit 0
        ;;
      *) err "unknown argument: $1" ;;
    esac
    shift
  done
}

# --- main ---
main() {
  parse_args "$@"

  need curl
  need tar

  local target tag release_version asset_name legacy_asset_name download_url tmp_dir extract_dir
  local bin_src lib_src lib_installed

  target="$(detect_target)"
  tag="$(resolve_tag)"
  release_version="${tag#v}"
  asset_name="ndk-cli-${release_version}-${target}.tar.gz"
  legacy_asset_name="ndk-cli-${target}.tar.gz"
  download_url="https://github.com/${REPO}/releases/download/${tag}/${asset_name}"

  info "installing ${BIN_NAME} ${tag} (${target})"
  info "from ${asset_name}"

  tmp_dir="$(mktemp -d)"
  extract_dir="${tmp_dir}/extract"
  trap 'rm -rf "${tmp_dir:-}"' EXIT
  mkdir -p "$extract_dir"

  # Current release assets include the version in their filename. Fall back to
  # the old unversioned convention so releases through v0.9.1 remain installable.
  if ! curl -fsSL --progress-bar "$download_url" -o "${tmp_dir}/${asset_name}" 2>/dev/null; then
    asset_name="$legacy_asset_name"
    download_url="https://github.com/${REPO}/releases/download/${tag}/${asset_name}"
    info "versioned asset not found; trying ${asset_name}"
    curl -fsSL --progress-bar "$download_url" -o "${tmp_dir}/${asset_name}" \
      || err "download failed — check that release asset exists: ${download_url}"
  fi

  tar -xzf "${tmp_dir}/${asset_name}" -C "$extract_dir" \
    || err "failed to extract archive: ${asset_name}"

  bin_src="${extract_dir}/bin/${BIN_NAME}"
  [ -f "$bin_src" ] || err "archive does not contain expected binary: bin/${BIN_NAME}"

  chmod +x "$bin_src"

  # quick sanity check (make bundled libs discoverable before install)
  # not all builds implement --version, so accept --help or default invocation too
  if ! LD_LIBRARY_PATH="${extract_dir}/lib:${LD_LIBRARY_PATH:-}" "$bin_src" --version &>/dev/null; then
    if ! LD_LIBRARY_PATH="${extract_dir}/lib:${LD_LIBRARY_PATH:-}" "$bin_src" --help &>/dev/null; then
      LD_LIBRARY_PATH="${extract_dir}/lib:${LD_LIBRARY_PATH:-}" "$bin_src" &>/dev/null \
        || err "downloaded binary failed to run — wrong platform?"
    fi
  fi

  if [ "${target#linux-}" != "$target" ] && [ "$INSTALL_MODE" = "system" ]; then
    USE_SUDO="0"
    if [ "$(id -u)" -ne 0 ] && check_sudo_needed "$SYSTEM_BIN_DIR" "$SYSTEM_LIB_DIR"; then
      need sudo
      USE_SUDO="1"
    fi

    run_priv mkdir -p "$SYSTEM_BIN_DIR" "$SYSTEM_LIB_DIR"
    run_priv install -m 0755 "$bin_src" "${SYSTEM_BIN_DIR}/${BIN_NAME}"

    lib_installed="0"
    for lib_src in "${extract_dir}/lib"/*; do
      [ -f "$lib_src" ] || continue
      run_priv install -m 0644 "$lib_src" "${SYSTEM_LIB_DIR}/$(basename "$lib_src")"
      lib_installed="1"
    done

    [ "$lib_installed" = "1" ] || err "archive does not contain shared libraries under lib/"
    run_priv ldconfig || true

    ok "${BIN_NAME} installed to ${SYSTEM_BIN_DIR}/${BIN_NAME}"
    ok "shared libraries installed to ${SYSTEM_LIB_DIR}"
    return
  fi

  # user install (default)
  mkdir -p "$INSTALL_DIR"
  mkdir -p "$USER_LIB_DIR"
  install -m 0755 "$bin_src" "${INSTALL_DIR}/${BIN_NAME}"

  lib_installed="0"
  for lib_src in "${extract_dir}/lib"/*; do
    [ -f "$lib_src" ] || continue
    install -m 0644 "$lib_src" "${USER_LIB_DIR}/$(basename "$lib_src")"
    lib_installed="1"
  done

  [ "$lib_installed" = "1" ] || err "archive does not contain shared libraries under lib/"

  ok "${BIN_NAME} installed to ${INSTALL_DIR}/${BIN_NAME}"
  ok "shared libraries installed to ${USER_LIB_DIR}"

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
