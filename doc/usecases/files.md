---
icon: file-zip
---

[!badge variant="primary" text="high level"]

## Example

:::code source="../../packages/ndk/example/files/files_example_test.dart" language="dart" range="10-15" title="blossom" :::

:::code source="../../packages/ndk/example/files/files_example_test.dart" language="dart" range="23-27" title="non blossom url" :::

## How to use

Files uses blossom under the hood to get, upload and delete files. \
The default user server list, specified by kind `10063` is used for upload and delete

If you need more granular control check out:
[!ref](/usecases/blossom.md)
