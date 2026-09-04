#!/usr/bin/env bash
set -euo pipefail

base_sha="${1:?usage: release-pr-title.sh BASE_SHA [HEAD_SHA] [PRIMARY_PACKAGE]}"
head_sha="${2:-HEAD}"
primary_package="${3:-ndk}"
fallback_target=""
fallback_version=""
selected_target=""
selected_version=""

while IFS= read -r pubspec; do
  [[ -n "$pubspec" ]] || continue

  if ! git diff --unified=0 "$base_sha" "$head_sha" -- "$pubspec" \
    | grep -Eq '^\+version:[[:space:]]'; then
    continue
  fi

  package_name=$(git show "$head_sha:$pubspec" | awk '$1 == "name:" { print $2; exit }')
  package_version=$(git show "$head_sha:$pubspec" | awk '$1 == "version:" { print $2; exit }')
  if [[ -z "$package_name" || -z "$package_version" ]]; then
    echo "Could not read package name and version from $pubspec." >&2
    exit 1
  fi

  if [[ -z "$fallback_target" ]]; then
    fallback_target="$package_name $package_version"
    fallback_version="$package_version"
  fi
  if [[ "$package_name" == "$primary_package" ]]; then
    selected_target="$package_name $package_version"
    selected_version="$package_version"
  fi
done < <(git diff --name-only "$base_sha" "$head_sha" -- '**/pubspec.yaml')

if [[ -z "$fallback_target" ]]; then
  echo "No package version changes found since $base_sha." >&2
  exit 1
fi

if [[ -z "$selected_target" ]]; then
  selected_target="$fallback_target"
  selected_version="$fallback_version"
fi

release_kind=release
version_core="${selected_version%%+*}"
if [[ "$version_core" == *-* ]]; then
  release_kind=prerelease
fi

pr_title="chore(${release_kind}): publish ${selected_target}"
echo "$pr_title"
echo "pr_title=$pr_title" >> "$GITHUB_OUTPUT"
