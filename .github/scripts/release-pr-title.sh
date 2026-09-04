#!/usr/bin/env bash
set -euo pipefail

head_sha="${1:-HEAD}"
release_kind="${2:?usage: release-pr-title.sh [HEAD_SHA] RELEASE_KIND}"

if [[ "$release_kind" != "release" && "$release_kind" != "prerelease" ]]; then
  echo "Release kind must be 'release' or 'prerelease'." >&2
  exit 1
fi

ndk_version=$(
  git show "$head_sha:packages/ndk/pubspec.yaml" \
    | awk '$1 == "version:" { print $2; exit }'
)
if [[ -z "$ndk_version" ]]; then
  echo "Could not read the NDK version from $head_sha." >&2
  exit 1
fi

pr_title="chore(${release_kind}): publish ndk ${ndk_version}"
echo "$pr_title"
echo "pr_title=$pr_title" >> "$GITHUB_OUTPUT"
