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

#### checkBlob

!!!
if you have a video player that uses a url you can use check to get a valid url first. Example can be found in NDK demo app
!!!

:::code source="../../packages/ndk/lib/domain_layer/usecases/files/blossom.dart" language="dart" range="137-148" title="" :::

#### getBlobStream

Similar to `getBlob`, it streams the data, which is helpful for video files.

:::code source="../../packages/ndk/lib/domain_layer/usecases/files/blossom.dart" language="dart" range="190-199" title="" :::

#### listBlobs

:::code source="../../packages/ndk/lib/domain_layer/usecases/files/blossom.dart" language="dart" range="242-252" title="" :::

#### deleteBlob

:::code source="../../packages/ndk/lib/domain_layer/usecases/files/blossom.dart" language="dart" range="289-296" title="" :::

#### directDownload

:::code source="../../packages/ndk/lib/domain_layer/usecases/files/blossom.dart" language="dart" range="329-332" title="" :::

#### report

:::code source="../../packages/ndk/lib/domain_layer/usecases/files/blossom.dart" language="dart" range="336-350" title="" :::

### methods - BlossomUserServerList

To get and set the user server list e.g. on settings page, you can use `BlossomUserServerList`

#### getUserServerList

:::code source="../../packages/ndk/lib/domain_layer/usecases/files/blossom_user_server_list.dart" language="dart" range="20-25" title="" :::

#### publishUserServerList

:::code source="../../packages/ndk/lib/domain_layer/usecases/files/blossom_user_server_list.dart" language="dart" range="54-58" title="" :::
