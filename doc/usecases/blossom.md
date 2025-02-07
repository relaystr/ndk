---
icon: file-zip
---

[!badge variant="primary" text="low level"]

## Example

:::code source="../../packages/ndk/example/files/blossom_example_test.dart" language="dart" range="10-19" title="" :::

## When to use

For a simpler, more generic API, check out
[!ref](/usecases/files.md)

If no servers are specified the default user server list (kind `10063`) is used for upload and delete.

The auth events get automatically signed and are valid for:
:::code source="../../packages/ndk/lib/config/blossom_config.dart" language="dart" range="4-4" title="" :::

### methods - Blossom

#### uploadBlob

upload a blob, if serverMediaOptimisation is set to `true` the `/media` endpoint is used.

:::code source="../../packages/ndk/lib/domain_layer/usecases/files/blossom.dart" language="dart" range="36-48" title="" :::

#### getBlob

Download the blob and use fallback if the blob is not found or the server is offline.

:::code source="../../packages/ndk/lib/domain_layer/usecases/files/blossom.dart" language="dart" range="87-95" title="" :::

#### getBlobStream

Similar to `getBlob`, it streams the data, which is helpful for video files.

:::code source="../../packages/ndk/lib/domain_layer/usecases/files/blossom.dart" language="dart" range="137-146" title="" :::

#### listBlobs

:::code source="../../packages/ndk/lib/domain_layer/usecases/files/blossom.dart" language="dart" range="193-199" title="" :::

#### deleteBlob

:::code source="../../packages/ndk/lib/domain_layer/usecases/files/blossom.dart" language="dart" range="236-243" title="" :::

#### directDownload

:::code source="../../packages/ndk/lib/domain_layer/usecases/files/blossom.dart" language="dart" range="276-279" title="" :::

#### report

:::code source="../../packages/ndk/lib/domain_layer/usecases/files/blossom.dart" language="dart" range="283-297" title="" :::

### methods - BlossomUserServerList

To get and set the user server list e.g. on settings page, you can use `BlossomUserServerList`

#### getUserServerList

:::code source="../../packages/ndk/lib/domain_layer/usecases/files/blossom_user_server_list.dart" language="dart" range="20-23" title="" :::

#### publishUserServerList

:::code source="../../packages/ndk/lib/domain_layer/usecases/files/blossom_user_server_list.dart" language="dart" range="54-58" title="" :::
