#!/usr/bin/env bash
set -euo pipefail

head_sha="${1:-HEAD}"
release_kind="${2:?usage: release-pr-title.sh [HEAD_SHA] RELEASE_KIND [BASE_SHA]}"
base_sha="${3:-${head_sha}^}"

if [[ "$release_kind" != "release" && "$release_kind" != "prerelease" ]]; then
  echo "Release kind must be 'release' or 'prerelease'." >&2
  exit 1
fi

# Read top-level pubspec scalars, including quoted versions and publish_to.
read_field() {
  awk -v key="$1:" '$1 == key { gsub(/[\047\042]/, "", $2); print $2; exit }'
}

# Compare the prepared release against the checkout before versioning. Package
# versions are independent; dependency-only edits do not represent a release.
changed_pubspecs=$(git diff --name-only --diff-filter=AM "$base_sha" "$head_sha" \
  -- ':(glob)packages/*/pubspec.yaml')
packages=""
while IFS= read -r pubspec_path; do
  [[ -n "$pubspec_path" ]] || continue
  pubspec=$(git show "$head_sha:$pubspec_path")
  [[ "$(read_field publish_to <<< "$pubspec")" != "none" ]] || continue

  package_name=$(read_field name <<< "$pubspec")
  package_version=$(read_field version <<< "$pubspec")
  if [[ -z "$package_name" || -z "$package_version" ]]; then
    echo "Could not read the package name and version from $head_sha:$pubspec_path." >&2
    exit 1
  fi

  previous_pubspec=$(git show "$base_sha:$pubspec_path" 2>/dev/null || true)
  previous_version=$(read_field version <<< "$previous_pubspec")
  [[ "$package_version" != "$previous_version" ]] || continue

  packages+="${packages:+, }${package_name} ${package_version}"
done <<< "$changed_pubspecs"

if [[ -z "$packages" ]]; then
  echo "No publishable package versions changed between $base_sha and $head_sha." >&2
  exit 1
fi

pr_title="chore(${release_kind}): publish ${packages}"
echo "$pr_title"
echo "pr_title=$pr_title" >> "$GITHUB_OUTPUT"
