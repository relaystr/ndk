#!/usr/bin/env bash
set -euo pipefail

script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/release-pr-title.sh"
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
export GITHUB_OUTPUT="$test_dir/github-output"
git init -q "$test_dir/repo"
cd "$test_dir/repo"
git config user.email test@example.com
git config user.name Test
git config commit.gpgsign false

write_package() {
  mkdir -p "packages/$1"
  printf 'name: %s\nversion: %s\n' "$2" "$3" > "packages/$1/pubspec.yaml"
}

commit() {
  git add packages
  git commit -qm "$1"
}

assert_title() {
  local expected="$1"
  shift
  : > "$GITHUB_OUTPUT"
  local actual
  actual=$(bash "$script_path" "$@")
  if [[ "$actual" != "$expected" || "$(cat "$GITHUB_OUTPUT")" != "pr_title=$expected" ]]; then
    printf 'Expected: %s\nActual: %s\n' "$expected" "$actual" >&2
    exit 1
  fi
}

write_package ndk ndk 0.10.0-dev.3
write_package ndk_flutter ndk_flutter 0.10.0-dev.3
write_package drift ndk_drift 0.1.1-dev.15
write_package private private_package 1.0.0
printf "publish_to: 'none'\n" >> packages/private/pubspec.yaml
commit baseline
base_sha=$(git rev-parse HEAD)

# PR #825: only ndk_flutter is released; ndk remains unchanged.
write_package ndk_flutter ndk_flutter 0.10.0-dev.4
commit flutter-release
assert_title 'chore(prerelease): publish ndk_flutter 0.10.0-dev.4' HEAD prerelease

# Ignore dependency-only changes and private package bumps. Use the package
# name from pubspec, not the directory name, and preserve distinct versions.
write_package drift ndk_drift 0.1.1-dev.16
printf 'dependencies:\n  ndk_flutter: ^0.10.0-dev.4\n' >> packages/ndk/pubspec.yaml
write_package private private_package 1.0.1
printf 'publish_to: "none" # internal only\n' >> packages/private/pubspec.yaml
commit other-changes
assert_title 'chore(prerelease): publish ndk_drift 0.1.1-dev.16, ndk_flutter 0.10.0-dev.4' HEAD prerelease "$base_sha"

# Stable/exact and graduated releases use the same committed-version source.
write_package ndk ndk '"0.10.0"'
commit stable-release
assert_title 'chore(release): publish ndk 0.10.0' HEAD release

# Newly added public packages can be included too.
write_package new_package new_package 1.0.0
commit new-package
assert_title 'chore(release): publish new_package 1.0.0' HEAD release

# No version changes must not produce a misleading title.
printf 'description: Updated description\n' >> packages/ndk/pubspec.yaml
commit metadata-only
: > "$GITHUB_OUTPUT"
if bash "$script_path" HEAD prerelease > "$test_dir/stdout" 2> "$test_dir/stderr"; then
  echo 'Expected failure when no publishable versions changed.' >&2
  exit 1
fi
[[ ! -s "$GITHUB_OUTPUT" ]]
grep -q 'No publishable package versions changed' "$test_dir/stderr"

if bash "$script_path" HEAD invalid > "$test_dir/stdout" 2> "$test_dir/stderr"; then
  echo 'Expected failure for an invalid release kind.' >&2
  exit 1
fi
grep -q "Release kind must be 'release' or 'prerelease'." "$test_dir/stderr"

echo 'Release PR title tests passed.'
