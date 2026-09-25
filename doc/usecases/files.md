---
icon: file-zip
---

[!badge variant="primary" text="high level"]

[!badge text="CLI"](/guides/cli/files.md) — `ndk files upload|download|delete|check`

## Example

:::code source="../../packages/ndk/example/files/files_example_test.dart" language="dart" range="10-15" title="blossom" :::

:::code source="../../packages/ndk/example/files/files_example_test.dart" language="dart" range="23-27" title="non blossom url" :::

## How to use

Files uses blossom under the hood to get, upload and delete files. \
The default user server list, specified by kind `10063` is used for upload and delete

If you need more granular control check out:
[!ref](/usecases/blossom.md)

## Server authentication

Every method takes an `auth` parameter saying which identity a blossom server
may learn, described in
[blossom](/usecases/blossom.md#server-authentication-bud-01). It is ignored for
a plain url, which is fetched directly.

```dart
await ndk.files.upload(
  file: myFile,
  auth: AuthPolicy.require(account),
);
```
