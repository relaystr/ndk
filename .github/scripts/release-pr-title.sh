#!/usr/bin/env bash
set -euo pipefail

base_sha="${1:?usage: release-pr-title.sh BASE_SHA [HEAD_SHA]}"
head_sha="${2:-HEAD}"
release_kind=release
targets=()

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

  targets+=("$package_name $package_version")
  version_core="${package_version%%+*}"
  if [[ "$version_core" == *-* ]]; then
    release_kind=prerelease
  fi
done < <(git diff --name-only "$base_sha" "$head_sha" -- '**/pubspec.yaml')

if (( ${#targets[@]} == 0 )); then
  echo "No package version changes found since $base_sha." >&2
  exit 1
fi

target_list="${targets[0]}"
for target in "${targets[@]:1}"; do
  target_list+=", $target"
done

pr_title="chore(${release_kind}): publish ${target_list}"
echo "$pr_title"
echo "pr_title=$pr_title" >> "$GITHUB_OUTPUT"
