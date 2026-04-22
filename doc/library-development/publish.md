---
label: Publishing
icon: rocket
order: 100
---

# Publishing

## publish to github

Create a tag
`git tag -a v1.2.3 -m "Release v1.2.3"`

Push to git

```
git push origin v1.2.3

```

> This will build the sample app and create a draft github release (gh actions).

Wait for the sample app to build and review && publish on github release page [releases](https://github.com/relaystr/ndk/releases)


## publish to pub.dev (automated)

go to [manual release gh actions](https://github.com/relaystr/ndk/actions/workflows/prerelease-manual.yaml)

For dev releases this is called automatically on each merge.

If you want a major release check 'Version as prerelease'!

A new PR named 'chore(release): Publish packages' will open Review the changelog/versions, modify if needed.

!!!
Merging this PR will automatically publish the changed (packages with version bump) packages to pub.dev
!!!

Notice: the automated PR does just versioning and publish dry-run. The Publishing happens when this PR is merged.

## publish manually

1.) either change the versions manually (also all dependencies) or run melos version (this will create a git commit)

2.) run 'melos run format'

3.) commit your changes to git

4.) run `melos publish` check everything then run `melos publish --no-dry-run`. For a single package run `melos publish --<package name>`

