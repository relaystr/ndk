---
icon: file-zip
---

[!badge variant="primary" text="low level"]

[!badge text="CLI"](/guides/cli/blossom.md) — `ndk blossom upload|download|delete|list|mirror|check|servers`

## Example

:::code source="../../packages/ndk/example/files/blossom_example_test.dart" language="dart" range="10-19" title="" :::

## When to use

For a simpler, more generic API, check out
[!ref](/usecases/files.md)

If no servers are specified the default user server list (kind `10063`) is used for upload and delete.

The auth events get automatically signed and are valid for:
:::code source="../../packages/ndk/lib/config/blossom_config.dart" language="dart" range="4-4" title="" :::

## Server authentication (BUD-01)

Some servers only serve a private blob, or only accept an upload, from a client
that signed a kind `24242` event. The `auth` parameter says which identity a
server may learn, as on
[requests](/usecases/requests.md#relay-authentication-nip-42) and
[broadcasts](/usecases/broadcast.md#relay-authentication-nip-42):

```dart
final response = await ndk.blossom.getBlob(
  sha256: hash,
  serverUrls: ['https://cdn.example.com'],
  auth: AuthPolicy.allow(account),
);
```

| policy | what goes out | what a server learns |
| --- | --- | --- |
| `AuthPolicy.never()` | no authorization, ever | nothing. A server that refuses without one simply does not serve the request |
| `AuthPolicy.allow(a)` | nothing at first, then the signed event once a server answered 401 | who you are, but only after that server asked |
| `AuthPolicy.require(a)` | the signed event on the first request | who you are, as soon as you ask it for anything |

The account does not have to be one NDK knows. `allow` costs a refused HTTP
round trip, and for an upload a body sent twice, so prefer `require` when the
server is known to ask. If `require` names an account that cannot sign, nothing
is sent and the call throws `BlossomAuthUnavailableException`.

Without `auth`, reads stay anonymous and everything else authorises as the
logged-in account, or as a throwaway key when none is. This default is expected
to change.

`useAuth` and `customSigner` were removed in favour of `auth`:

| removed | replace with |
| --- | --- |
| `useAuth: true` | `auth: AuthPolicy.require(account)`, with the logged-in account, or the one holding the `customSigner` passed alongside |
| `customSigner: s` alone | the same with the account holding `s`, except on a download or a check, where it never signed: drop it |
| `useAuth: false` | `auth: const AuthPolicy.never()` on `listBlobs`, nothing elsewhere |

### methods - Blossom

#### uploadBlob

upload a blob, if serverMediaOptimisation is set to `true` the `/media` endpoint is used.

```dart
Future<List<BlobUploadResult>> uploadBlob({
  required Uint8List data,
  List<String>? serverUrls,
  String? contentType,
  UploadStrategy strategy = UploadStrategy.mirrorAfterSuccess,
  bool serverMediaOptimisation = false,
  AuthPolicy? auth,
  String? pubkeyToFetchUserServerList,
  String? precomputedSha256,
})
```

#### uploadBlobFromFile

Reads the file in chunks, so a large file is never held whole in memory.

```dart
Stream<BlobUploadProgress> uploadBlobFromFile({
  required String filePath,
  List<String>? serverUrls,
  String? contentType,
  UploadStrategy strategy = UploadStrategy.mirrorAfterSuccess,
  bool serverMediaOptimisation = false,
  AuthPolicy? auth,
  String? pubkeyToFetchUserServerList,
  String? precomputedSha256,
})
```

#### getBlob

Download the blob and use fallback if the blob is not found or the server is offline.

```dart
Future<BlobResponse> getBlob({
  required String sha256,
  AuthPolicy? auth,
  List<String>? serverUrls,
  String? pubkeyToFetchUserServerList,
})
```

#### checkBlob

!!!
if you have a video player that uses a url you can use check to get a valid url first. Example can be found in NDK demo app
!!!

```dart
Future<String> checkBlob({
  required String sha256,
  AuthPolicy? auth,
  List<String>? serverUrls,
  String? pubkeyToFetchUserServerList,
})
```

#### getBlobStream

Similar to `getBlob`, it streams the data, which is helpful for video files.

```dart
Future<Stream<BlobResponse>> getBlobStream({
  required String sha256,
  AuthPolicy? auth,
  List<String>? serverUrls,
  String? pubkeyToFetchUserServerList,
  int chunkSize = 1024 * 1024,
})
```

#### listBlobs

```dart
Future<List<BlobDescriptor>> listBlobs({
  required String pubkey,
  List<String>? serverUrls,
  AuthPolicy? auth,
  DateTime? since,
  DateTime? until,
})
```

#### deleteBlob

```dart
Future<List<BlobDeleteResult>> deleteBlob({
  required String sha256,
  List<String>? serverUrls,
  AuthPolicy? auth,
  String? pubkeyToFetchUserServerList,
})
```

#### mirrorToServers

Copies a blob that already lives somewhere else onto other servers, without
downloading it first.

```dart
Future<List<BlobUploadResult>> mirrorToServers({
  required Uri blossomUrl,
  required List<String> targetServerUrls,
  AuthPolicy? auth,
})
```

#### directDownload

```dart
Future<BlobResponse> directDownload({required Uri url})
```

#### report

The report is a signed event in the request body, so `never()` signs it with a
throwaway key rather than sending nothing.

```dart
Future<int> report({
  required String sha256,
  required String eventId,
  required String reportType,
  required String reportMsg,
  required String serverUrl,
  AuthPolicy? auth,
})
```

### methods - BlossomUserServerList

To get and set the user server list e.g. on settings page, you can use `BlossomUserServerList`

#### getUserServerList

:::code source="../../packages/ndk/lib/domain_layer/usecases/files/blossom_user_server_list.dart" language="dart" range="23-28" title="" :::

#### publishUserServerList

:::code source="../../packages/ndk/lib/domain_layer/usecases/files/blossom_user_server_list.dart" language="dart" range="54-58" title="" :::
