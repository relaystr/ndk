# Publishing

## Full release order

Complete releases have two distinct stages, in this order:

1. Prepare and merge the package release PR. This publishes packages to
   pub.dev and creates package tags such as `ndk-v0.9.2`.
2. Tag that resulting `master` commit with the workspace release tag, such as
   `v0.9.2`. This creates the GitHub release and builds its Android, CLI, and
   web artifacts.

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

The workflow opens a PR named `chore(release): Publish packages`. Replace the
generated `Stable release.` changelog stub with the actual `0.9.2` release
notes. Then review the NDK version and all generated dependent-package
constraint updates before merging the PR.

Merging that release PR creates package tags and publishes every changed,
publishable package to pub.dev. Preparing the PR performs only a publish dry
run; it does not publish anything.

!!!
Do not use `graduate-prerelease` to change `0.9.1-dev.N` into `0.9.2`.
Graduation only removes `-dev.N`, so it would produce `0.9.1`. Use `exact` for
the `0.9.2` release.
!!!

## 2. Publish the GitHub release and artifacts

After the package release PR is merged, update local `master` and tag that
exact commit:

```sh
git switch master
git pull --ff-only
git tag -a v0.9.2 -m "Release v0.9.2"
git push origin v0.9.2
```

The `v0.9.2` tag starts the sample-app release workflow. It creates a draft
GitHub release, builds and uploads the Android APKs and cross-platform CLI
archives, and deploys the sample web app. After every job succeeds, the
workflow publishes the GitHub release automatically.

Verify the completed release and its assets on the
[GitHub releases page](https://github.com/relaystr/ndk/releases).

Do not create `v0.9.2` before the package release PR is merged. Otherwise the
tag and built artifacts point to source that still reports the previous
package version.

## Manual alternative

1. Either change the versions manually, including dependency constraints, or
   run `melos version` (which creates a Git commit).
2. Run `melos run format`.
3. Commit your changes.
4. Run `melos publish` to validate the release, then run
   `melos publish --no-dry-run`. To publish one package, use
   `melos publish --scope=<package_name> --no-dry-run`.
