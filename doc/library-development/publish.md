---
label: Publishing
icon: rocket
order: 100
---

# Publishing

## Full release order

Complete releases have two distinct stages, in this order:

1. Prepare and merge the package release PR. This publishes packages to
   pub.dev.
2. After publication succeeds, automation tags the release commit. NDK uses a
   plain tag such as `v0.9.2`; other packages use tags such as
   `ndk_flutter-v0.9.0`. An NDK `vX.Y.Z` tag creates the GitHub release and
   builds its Android, CLI, and web artifacts.

## 1. Publish packages to pub.dev

Open the [Prepare package release workflow](https://github.com/relaystr/ndk/actions/workflows/prerelease-manual.yaml),
select **Run workflow**, and choose one release mode:

| Release mode | Result |
| --- | --- |
| `stable` | Calculates the next stable versions from conventional commits. |
| `development-prerelease` | Calculates the next development versions, such as `0.9.2-dev.1`. This mode is also run automatically after ordinary PRs merge. |
| `graduate-prerelease` | Removes the prerelease suffix without changing its base version; for example, `0.9.2-dev.3` becomes `0.9.2`. |
| `exact` | Sets one selected package to the exact version entered. Melos also updates affected workspace dependents and creates a changelog stub to review. |

The `exact_package` and `exact_version` inputs are used only with `exact` mode.
For the other modes, leave them at their defaults.

### Release NDK 0.9.2 as a stable version

Run the workflow with:

- `release_mode`: `exact`
- `exact_package`: `ndk`
- `exact_version`: `0.9.2`

The workflow opens a versioned PR named
`chore(release): publish ndk 0.9.2`. Development versions instead use
`chore(prerelease)`, for example
`chore(prerelease): publish ndk 0.9.3-dev.0`. Replace the generated
`Stable release.` changelog stub with the actual release notes. Then review the
NDK version and all generated dependent-package constraint updates before
merging the PR. If several package versions change, the title lists each exact
package/version pair.

Merging that release PR creates package tags and publishes every changed,
publishable package to pub.dev. Preparing the PR performs only a publish dry
run; it does not publish anything.

!!!
Do not use `graduate-prerelease` to change `0.9.1-dev.N` into `0.9.2`.
Graduation only removes `-dev.N`, so it would produce `0.9.1`. Use `exact` for
the `0.9.2` release.
!!!

## 2. Verify the GitHub release and artifacts

After pub.dev publication succeeds, the package workflow creates `v0.9.2` on
the release commit. That tag starts the sample-app release workflow. It creates
a draft GitHub release using the matching section from
`packages/ndk/CHANGELOG.md`, builds and uploads the Android APKs and
cross-platform CLI archives, and deploys the sample web app. After every job
succeeds, the workflow publishes the GitHub release automatically.

The release preparation keeps `doc/retype.yml` aligned with the NDK package
version. The tag-triggered docs deployment also derives the displayed version
from the tag so the published site cannot retain a stale version label. The
documentation and sample-app deployments share one deployment queue and retain
each other's files on the `gh-pages` branch.

Verify the completed release and its assets on the
[GitHub releases page](https://github.com/relaystr/ndk/releases).

Release asset names use `<product>-<version>-<platform>-<architecture>` with
kebab-case product names, for example `ndk-demo-0.9.2-android-arm64-v8a.apk`
and `ndk-cli-0.9.2-linux-x64.tar.gz`.

Do not create `v0.9.2` manually before package publication finishes. Otherwise
the tag and built artifacts can point to source that still reports the
previous package version.

## Manual alternative

1. Either change the versions manually, including dependency constraints, or
   run `melos version` (which creates a Git commit).
2. Run `melos run format`.
3. Commit your changes.
4. Run `melos publish` to validate the release, then run
   `melos publish --no-dry-run`. To publish one package, use
   `melos publish --scope=<package_name> --no-dry-run`.
