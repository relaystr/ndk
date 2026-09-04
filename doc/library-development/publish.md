---
label: Publishing
icon: rocket
order: 100
---

# Publishing

## Publish to GitHub

Create a tag
`git tag -a v1.2.3 -m "Release v1.2.3"`

Push to git

```
git push origin v1.2.3

```

> This will build the sample app and create a draft github release (gh actions).

Wait for the sample app to build, then review and publish it on the
[GitHub releases page](https://github.com/relaystr/ndk/releases).

## Publish to pub.dev (automated)

Open the [Prepare package release workflow](https://github.com/relaystr/ndk/actions/workflows/prerelease-manual.yaml),
select **Run workflow**, and choose one release mode:

| Release mode | Result |
| --- | --- |
| `stable` | Calculates the next stable versions from conventional commits. |
| `development-prerelease` | Calculates the next development versions, such as `0.9.2-dev.1`. This mode is also run automatically after ordinary PRs merge. |
| `graduate-prerelease` | Removes the prerelease suffix without changing its base version; for example, `0.9.2-dev.3` becomes `0.9.2`. |
| `exact` | Sets one selected package to the exact version entered. Melos also updates affected workspace dependents; add the package's changelog entry in the generated PR. |

The `exact_package` and `exact_version` inputs are used only with `exact` mode.
For the other modes, leave them at their defaults.

### Release NDK 0.9.2 as a stable version

Run the workflow with:

- `release_mode`: `exact`
- `exact_package`: `ndk`
- `exact_version`: `0.9.2`

The workflow opens a PR named `chore(release): Publish packages`. Exact mode
does not guess release notes, so add a `## 0.9.2` entry to
`packages/ndk/CHANGELOG.md`. Then review the NDK version and all generated
dependent-package constraint updates before merging the PR.

Merging that release PR creates package tags and publishes every changed,
publishable package to pub.dev. Preparing the PR performs only a publish dry
run; it does not publish anything.

!!!
Do not use `graduate-prerelease` to change `0.9.1-dev.N` into `0.9.2`.
Graduation only removes `-dev.N`, so it would produce `0.9.1`. Use `exact` for
the `0.9.2` release.
!!!

## Publish manually

1. Either change the versions manually, including dependency constraints, or
   run `melos version` (which creates a Git commit).
2. Run `melos run format`.
3. Commit your changes.
4. Run `melos publish` to validate the release, then run
   `melos publish --no-dry-run`. To publish one package, use
   `melos publish --scope=<package_name> --no-dry-run`.
