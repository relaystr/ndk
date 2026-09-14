---
icon: package-dependencies
label: Software updates
---

# Software discovery and Android updates

NDK's `software` use case discovers NIP-82 application, release, and asset
events from trusted publishers. `ndk_flutter` adds a controller, reusable
widgets, and a verified Android APK installer.

## Published event requirements

Choose one publisher public key and keep it stable. Applications trust only
events authored by the configured publisher.

- Application (`kind 32267`): one `d` identifier, one `name`, optional
  `summary`, `icon`, `image`, and platform `f` tags.
- Release (`kind 30063`): `i` application identifier, `version`, channel `c`,
  `d` equal to `<identifier>@<version>`, and one or more `e` asset references.
- Asset (`kind 3063`): `i`, `version`, MIME type `m`, SHA-256 `x`, HTTPS `url`,
  optional byte `size`, and platform `f` tags.
- Android assets also require integer `version_code` and at least one
  `apk_certificate_hash` containing a SHA-256 signing-certificate digest.

Publish asset events before release events so each release reference resolves.
Use relay hints in release `e` tags when asset metadata events live on specific
relays. Relays store Nostr metadata events; Blossom servers store APK binaries.

For ABI-specific Android releases, publish a separate asset for each APK and
use one of `android-arm64-v8a`, `android-armeabi-v7a`, `android-x86`, or
`android-x86_64` as its `f` tag. `selectUpdate` chooses a compatible asset with
a newer Android version code and matching certificate.

## Core NDK API

```dart
const app = SoftwareAppRef(
  publisher: '<trusted-publisher-hex-pubkey>',
  identifier: 'com.example.app',
);

final metadata = await ndk.software.getApp(
  app: app,
  relays: const [
    'wss://catalog.example',
    'wss://catalog-backup.example',
  ],
);

final releases = await ndk.software.getReleases(
  app: app,
  channel: 'main',
  relays: const [
    'wss://catalog.example',
    'wss://catalog-backup.example',
  ],
);

final subscription = ndk.software
    .watchReleases(
      app: app,
      channel: 'main',
      relays: const [
        'wss://catalog.example',
        'wss://catalog-backup.example',
      ],
    )
    .listen((releases) {
      // Resolve assets or update application state.
    });

// Call from the owner's asynchronous cleanup path to close the relay request.
Future<void> dispose() async {
  await subscription.cancel();
}
```

Use `resolveAssets(release)` to fetch one release's referenced asset events.
When evaluating multiple releases, use `resolveAssetsForReleases(releases)`;
it resolves every referenced event ID in one relay request and returns assets
keyed by release event ID. Use `selectUpdate(...)` when integrating a platform
installer directly.

## Relay and Blossom configuration

Pass every catalog relay that should be queried through `relays`. These relays
are used to discover application and release events. `NAppUpdateController`
also uses them to resolve asset metadata, load release comments, reactions, and
zap receipts, and publish new comments.

An empty relay list does not mean “use Zapstore.” It delegates relay selection
to the configured NDK engine and bootstrap/routing data. That may be useful in
a general Nostr client, but an application updater should normally provide at
least one explicit catalog relay so release discovery remains predictable.

A release can point at an asset event on another relay by including a relay
hint in its `e` tag:

```json
["e", "<asset-event-id>", "wss://assets-relay.example"]
```

`resolveAssets` queries the union of configured relays and all relay hints from
the release. A hint locates the kind `3063` asset metadata event; it does not
identify the server hosting the APK.

Publisher selects the Blossom server. Asset event carries the final public
HTTPS URL:

```json
["url", "https://blossom.example/<sha256>"]
```

Installer downloads this signed event URL directly, so applications do not
configure a Blossom base URL. Custom or self-hosted Blossom works without
client changes when publisher uploads the APK there and publishes its HTTPS
URL, size, hash, package metadata, ABI, and certificate digest in the asset
event.

Each asset currently supports one `url` tag. Automatic retries cover the same
URL and its redirects, but there is no Blossom mirror/fallback list. Publishers
needing redundancy should use a resilient endpoint or CDN in that URL.

## Flutter controller

Create one controller for the application, start it after NDK initialization,
and dispose it with the owning widget or application service:

```dart
late final NAppUpdateController appUpdater;

void initializeUpdates(NdkFlutter ndkFlutter) {
  appUpdater = NAppUpdateController.self(
    ndkFlutter: ndkFlutter,
    app: const SoftwareAppRef(
      publisher: '<trusted-publisher-hex-pubkey>',
      identifier: 'com.example.app',
    ),
    currentVersion: packageVersion,
    externalUpdateUrl: Uri.parse('https://github.com/relaystr/ndk/'),
    channel: 'main',
    relays: const [
      'wss://catalog.example',
      'wss://catalog-backup.example',
    ],
    // Optional network budgets. Cached social data stays visible during refresh,
    // including when an engagement query times out. Initial loads commit results
    // only after both engagement queries complete.
    queryTimeout: const Duration(seconds: 5),
    engagementQueryTimeout: const Duration(seconds: 4),
    engagementMetadataTimeout: const Duration(seconds: 3),
  );
  unawaited(appUpdater.start());
}

void disposeUpdates() {
  appUpdater.dispose();
}
```

`currentVersion` enables release matching without Android package APIs.
On Android, APK installation remains enabled by default. On iOS, desktop, and
web, release discovery, changelog, release details, zaps, reactions, and
comments remain available, while APK installation is disabled. When a newer
published release exists, `externalUpdateUrl` adds an external download action;
set it to that application's download or release page. The sample app uses
`https://github.com/relaystr/ndk/`.

`publisher`, `identifier`, and `channel` must match published NIP-82 events.
Use production relay URLs and publisher keys from build configuration rather
than user input. Blossom server configuration belongs to publishing tooling,
not this controller.

## Widgets

Register `ndk_flutter` localization delegates as described in the package
README, then pass the shared controller to any update widget:

```dart
NAppVersion(controller: appUpdater);       // compact version and update icon
NAppUpdateBanner(controller: appUpdater); // actionable update banner
NAppUpdateTile(controller: appUpdater);   // settings/list entry
NReleaseHistoryScreen(controller: appUpdater); // full changelog route

NAppUpdateBuilder(
  controller: appUpdater,
  builder: (context, state) => Text(state.status.name),
);
```

`NAppVersion` acquires a live Nostr release subscription by default. A newly
published matching release therefore updates controller state and shows the
icon without waiting for restart or manual refresh. The subscription is
released when the widget is disposed; multiple version widgets share one
controller subscription safely.

Disable live watching for a widget when polling or application-owned
subscription lifecycle is preferred:

```dart
NAppVersion(
  controller: appUpdater,
  watchReleases: false,
);
```

`controller.start()` performs the initial check without keeping a live
subscription. Applications without `NAppVersion` can explicitly retain one:

```dart
await controller.start(watchReleases: true);
```

`NAppVersion` always displays the installed version. A theme-aware tertiary
icon appears when an update is available, including after the user selects
Later. Tapping the version opens `NAppUpdateDialog`, which reports either the
available update or that the installed version is current.

The dialog shows release date and a concise preview of the release event
content. Its **Changelog** action opens a newest-first release history screen.
Selecting a release opens the same details sheet used by **Release details**.
The sheet starts with a horizontally scrollable version selector. Switching
versions updates only release-specific date, notes, asset trust information,
and technical details.

Publisher identity, zap/reaction/comment counts, and discussion appear below
an **Across all releases** divider. They are application-wide and remain stable
while versions change. Release history reuses `state.releases` from update
discovery, so opening it performs no extra relay query. Social state is also
shared instead of being refetched for every selected version.

Community data starts loading when its summary actions appear. Opening release
details reuses that request and state instead of fetching it again. Counts and
comments render before optional profile metadata; cached values remain visible
during refresh. Social query failures never block update discovery, download,
verification, or installation. When NDK has a logged-in signing account, the
details sheet also publishes NIP-22 kind `1111` comments rooted at the
addressable release event. Without a signer, discussion remains read-only.

Engagement uses two concurrent, single-filter relay queries: one `#p` query for
zaps and reactions, and one NIP-22 `#A` query for comments. This avoids
deprecated multi-filter requests while keeping social loading to one parallel
network phase. Release discovery and asset resolution complete independently;
social data never delays update availability.

Zap totals are derived from parseable kind `9735` receipts addressed to the
release publisher. Treat them as community signals rather than payment proofs:
full LNURL-provider receipt validation requires recipient-specific LNURL
context that this reusable widget does not own.

`NAppVersion` also remembers the installed Android version code. First launch
only establishes a baseline. After a later launch detects a higher installed
version code and resolves its release event, it automatically opens release
details once so the user can read notes and community activity for the version
they just installed. Closing the sheet acknowledges that version. This small
cross-launch marker uses `shared_preferences`; it does not hide available
updates or suppress the update icon.

## Android configuration

Applications using `AndroidPackageInstaller` must opt into package installation
in `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />
    <application>
        <!-- application components -->
    </application>
</manifest>
```

This restricted permission is intentionally absent from the `ndk_flutter`
library manifest. Declare it only when self-updating is a core app feature and
your distribution channel permits it. Android 8 and newer also ask the user to
allow installs from the application before the first update.

The library supplies its non-exported `FileProvider` and cache path through
manifest merging. No storage permission is required for update APKs.

## Installer validation

Before handing an APK to Android, `AndroidPackageInstaller` verifies:

- HTTPS URL and a DNS check rejecting local addresses before the original
  request and every redirect;
- declared byte size when present, plus a 512 MiB hard download ceiling;
- SHA-256 file hash;
- package identifier and Android version code;
- NIP-82 certificate digest and compatibility with installed signing history;
- ABI and minimum Android version during update selection.

The DNS check does not bind the connection to the checked addresses. It is not
a guarantee against DNS rebinding between validation and connection.

Only one download may run at once. Cancellation closes the active connection,
waits for its worker to stop, and removes the partial APK.

For release builds, publish split-per-ABI APKs and derive every asset tag from
the final signed file. Never publish metadata calculated from a universal,
unsigned, or differently signed APK.
