---
icon: file-zip
---

[!badge variant="primary" text="high level"]

## Example

:::code source="../../packages/ndk/example/files/files_example_test.dart" language="dart" range="10-15" title="blossum url" :::

:::code source="../../packages/ndk/example/files/files_example_test.dart" language="dart" range="23-27" title="non blossum url" :::

## How to use

Files uses blossum under the hood to get, upload and delete files. \
The default user server list, specified by kind `10063` is used for upload and delete 

If you need more granular control check out:
[!ref](/usecases/blossom.md)