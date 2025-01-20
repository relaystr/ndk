---
icon: file-zip
---

[!badge variant="primary" text="low level"]

## Example

:::code source="../../packages/ndk/example/files/blossom_example_test.dart" language="dart" range="10-19" title="" :::

## When to use

For a simpler more generic api check out
[!ref](/usecases/files.md)

If no servers are specified the default user server list (kind `10063`) is used for upload and delete.

The auth events get automatically signed and are valid for:
:::code source="../../packages/ndk/lib/config/blossom_config.dart" language="dart" range="4-4" title="" :::