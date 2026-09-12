import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import '../mocks/mock_event_verifier.dart';
import '../mocks/mock_relay.dart';

class _WatchRequests implements Requests {
  final NdkResponse response;
  String? closedRequestId;

  _WatchRequests(Stream<Nip01Event> events)
      : response = NdkResponse('software-watch-test', events);

  @override
  Future<void> closeSubscription(String subId, {String debugLabel = ''}) async {
    closedRequestId = subId;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #subscription) return response;
    return super.noSuchMethod(invocation);
  }
}

class _QueryRequests implements Requests {
  final NdkResponse response;

  _QueryRequests(RelayRequestStatus status)
      : response = NdkResponse(
          'software-query-test',
          const Stream<Nip01Event>.empty(),
          relayOutcomes: () => {
            'wss://relay.example': RelayRequestOutcome(status),
          },
        );

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #query) return response;
    return super.noSuchMethod(invocation);
  }
}

void main() {
  const publisher =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const hash =
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
  const certificate =
      'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
  const appRef = SoftwareAppRef(
    publisher: publisher,
    identifier: 'com.example.app',
  );

  Nip01Event event(
    int kind,
    List<List<String>> tags, {
    String content = '',
    String id = hash,
    String pubKey = publisher,
    int createdAt = 100,
  }) =>
      Nip01Event(
        id: id,
        pubKey: pubKey,
        kind: kind,
        tags: tags,
        content: content,
        createdAt: createdAt,
      );

  Nip01Event networkEvent(
    int kind,
    List<List<String>> tags, {
    String content = '',
    String pubKey = publisher,
    int createdAt = 100,
  }) =>
      Nip01Event(
        pubKey: pubKey,
        kind: kind,
        tags: tags,
        content: content,
        createdAt: createdAt,
      );

  test('getApp distinguishes missing application from relay failure', () async {
    final missing = Software(
      requests: _QueryRequests(RelayRequestStatus.eose),
    );
    expect(await missing.getApp(app: appRef), isNull);

    final failed = Software(
      requests: _QueryRequests(RelayRequestStatus.timedOut),
    );
    expect(
      failed.getApp(app: appRef),
      throwsA(isA<SoftwareDiscoveryException>()),
    );
  });

  test('watch emits only changed releases and closes its subscription',
      () async {
    Nip01Event release({
      int createdAt = 100,
      String version = '1.0.0',
      String identifier = 'com.example.app',
      String author = publisher,
      String channel = 'main',
    }) =>
        networkEvent(
            softwareReleaseKind,
            [
              ['i', identifier],
              ['version', version],
              ['d', '$identifier@$version'],
              ['c', channel],
              ['e', hash],
            ],
            pubKey: author,
            createdAt: createdAt);

    final first = release();
    final newer = release(createdAt: 200);
    final otherVersion = release(createdAt: 150, version: '2.0.0');
    final requests = _WatchRequests(Stream.fromIterable([
      event(softwareReleaseKind, []),
      release(author: hash),
      release(identifier: 'com.other.app'),
      release(channel: 'beta'),
      first,
      first,
      release(createdAt: 99),
      release(channel: 'beta'),
      event(softwareReleaseKind, []),
      release(author: hash),
      release(identifier: 'com.other.app'),
      newer,
      otherVersion,
      release(createdAt: 200),
    ]));
    final snapshots = await Software(requests: requests)
        .watchReleases(
          app: const SoftwareAppRef(
            publisher: publisher,
            identifier: 'com.example.app',
          ),
        )
        .toList();

    expect(
      snapshots.map((releases) => releases.map((release) => release.event.id)),
      [
        [first.id],
        [newer.id],
        [newer.id, otherVersion.id],
      ],
    );
    expect(requests.closedRequestId, requests.response.requestId);
  });

  test('parses current NIP-82 application, release, and Android asset tags',
      () {
    final app = SoftwareApp.fromEvent(event(
        softwareApplicationKind,
        [
          ['d', 'com.example.app'],
          ['name', 'Example'],
          ['summary', 'Small summary'],
        ],
        content: 'Description'));
    expect(app.ref.identifier, 'com.example.app');
    expect(app.name, 'Example');

    final release = SoftwareRelease.fromEvent(event(
        softwareReleaseKind,
        [
          ['i', 'com.example.app'],
          ['version', '1.2.0'],
          ['d', 'com.example.app@1.2.0'],
          ['c', 'main'],
          ['e', hash, 'wss://example.com'],
        ],
        content: 'Changes'));
    expect(release.assets.single.relayHint, 'wss://example.com');

    final asset = SoftwareAsset.fromEvent(event(softwareAssetKind, [
      ['i', 'com.example.app'],
      ['version', '1.2.0'],
      ['m', androidPackageMimeType],
      ['x', hash],
      ['url', 'https://example.com/app.apk'],
      ['version_code', '12'],
      ['f', 'android-arm64-v8a'],
      ['min_platform_version', '24'],
      ['apk_certificate_hash', certificate],
    ]));
    expect(asset.versionCode, 12);
    expect(asset.certificateHashes, [certificate]);
  });

  test('rejects malformed release coordinate and incomplete Android asset', () {
    expect(
      () => SoftwareRelease.fromEvent(event(softwareReleaseKind, [
        ['i', 'com.example.app'],
        ['version', '1.2.0'],
        ['d', 'wrong'],
        ['c', 'main'],
        ['e', hash],
      ])),
      throwsA(isA<SoftwareParseException>()),
    );
    expect(
      () => SoftwareAsset.fromEvent(event(softwareAssetKind, [
        ['i', 'com.example.app'],
        ['version', '1.2.0'],
        ['m', androidPackageMimeType],
        ['x', hash],
      ])),
      throwsA(isA<SoftwareParseException>()),
    );
  });

  test('selects only newer compatible Android asset', () {
    final releaseEvent = event(softwareReleaseKind, [
      ['i', 'com.example.app'],
      ['version', '1.2.0'],
      ['d', 'com.example.app@1.2.0'],
      ['c', 'main'],
      ['e', hash],
    ]);
    final release = SoftwareRelease.fromEvent(releaseEvent);
    final asset = SoftwareAsset.fromEvent(event(softwareAssetKind, [
      ['i', 'com.example.app'],
      ['version', '1.2.0'],
      ['m', androidPackageMimeType],
      ['x', hash],
      ['url', 'https://updates.example/app.apk'],
      ['version_code', '12'],
      ['f', 'android-arm64-v8a'],
      ['min_platform_version', '24'],
      ['apk_certificate_hash', certificate],
    ]));
    final unusableNewerAsset = SoftwareAsset.fromEvent(
      event(softwareAssetKind, [
        ['i', 'com.example.app'],
        ['version', '1.3.0'],
        ['m', androidPackageMimeType],
        ['x', hash],
        ['version_code', '13'],
        ['f', 'android-arm64-v8a'],
        ['apk_certificate_hash', certificate],
      ]),
    );
    final ndk = Ndk.emptyBootstrapRelaysConfig();
    addTearDown(ndk.destroy);
    final update = ndk.software.selectUpdate(
      releases: [release],
      assetsByReleaseId: {
        release.event.id: [unusableNewerAsset, asset],
      },
      installed: const InstalledSoftware(
        packageId: 'com.example.app',
        version: '1.1.0',
        versionCode: 11,
        platformVersion: 35,
        platforms: ['android-arm64-v8a'],
        certificateHashes: [certificate],
      ),
    );
    expect(update?.asset.versionCode, 12);

    const newerInstalled = InstalledSoftware(
      packageId: 'com.example.app',
      version: '1.3.0-dev',
      versionCode: 13,
      platformVersion: 35,
      platforms: ['android-arm64-v8a'],
      certificateHashes: [certificate],
    );
    final latestPublished = ndk.software.selectLatestCompatible(
      releases: [release],
      assetsByReleaseId: {
        release.event.id: [asset],
      },
      installed: newerInstalled,
    );
    expect(latestPublished?.asset.versionCode, 12);
    expect(
      ndk.software.selectUpdate(
        releases: [release],
        assetsByReleaseId: {
          release.event.id: [asset],
        },
        installed: newerInstalled,
      ),
      isNull,
    );
  });

  group('software discovery', () {
    late MockRelay relay;
    late Ndk ndk;

    setUp(() async {
      relay = MockRelay(name: 'software discovery');
      await relay.startServer();
      ndk = Ndk(
        NdkConfig(
          cache: MemCacheManager(),
          eventVerifier: MockEventVerifier(),
          bootstrapRelays: [relay.url],
        ),
      );
    });

    tearDown(() async {
      await ndk.destroy();
      await relay.stopServer();
    });

    test('gets application and sorted valid releases', () async {
      relay.textNotes = {
        Bip340.generatePrivateKey(): networkEvent(
          softwareApplicationKind,
          [
            ['d', 'com.example.app'],
            ['name', 'Example'],
          ],
          content: 'Description',
        ),
      };

      final ref = SoftwareAppRef(
        publisher: publisher,
        identifier: 'com.example.app',
      );
      final app = await ndk.software.getApp(app: ref, relays: [relay.url]);
      expect(app?.name, 'Example');

      relay.textNotes = {
        Bip340.generatePrivateKey(): networkEvent(
          softwareReleaseKind,
          [
            ['i', 'com.example.app'],
            ['version', '1.0.0'],
            ['d', 'com.example.app@1.0.0'],
            ['c', 'main'],
            ['e', hash],
          ],
          createdAt: 100,
        ),
        Bip340.generatePrivateKey(): networkEvent(
          softwareReleaseKind,
          [
            ['i', 'com.example.app'],
            ['version', '2.0.0'],
            ['d', 'com.example.app@2.0.0'],
            ['c', 'main'],
            ['e', hash],
          ],
          createdAt: 200,
        ),
        Bip340.generatePrivateKey(): networkEvent(
          softwareReleaseKind,
          [
            ['i', 'com.example.app'],
            ['version', 'broken'],
            ['d', 'wrong'],
            ['c', 'main'],
            ['e', hash],
          ],
        ),
      };

      final releases = await ndk.software.getReleases(
        app: ref,
        relays: [relay.url],
      );
      expect(releases.map((release) => release.version), ['2.0.0', '1.0.0']);
    });

    test('resolves only valid referenced assets', () async {
      final assetEvent = networkEvent(
        softwareAssetKind,
        [
          ['i', 'com.example.app'],
          ['version', '2.0.0'],
          ['m', androidPackageMimeType],
          ['x', hash],
          ['version_code', '20'],
          ['apk_certificate_hash', certificate],
        ],
      );
      final wrongAppAsset = networkEvent(
        softwareAssetKind,
        [
          ['i', 'com.example.other'],
          ['version', '2.0.0'],
          ['m', androidPackageMimeType],
          ['x', hash],
          ['version_code', '20'],
          ['apk_certificate_hash', certificate],
        ],
      );
      final wrongVersionAsset = networkEvent(
        softwareAssetKind,
        [
          ['i', 'com.example.app'],
          ['version', '3.0.0'],
          ['m', androidPackageMimeType],
          ['x', hash],
          ['version_code', '30'],
          ['apk_certificate_hash', certificate],
        ],
      );
      final release = SoftwareRelease.fromEvent(event(
        softwareReleaseKind,
        [
          ['i', 'com.example.app'],
          ['version', '2.0.0'],
          ['d', 'com.example.app@2.0.0'],
          ['c', 'main'],
          ['e', assetEvent.id, relay.url],
          ['e', wrongAppAsset.id, relay.url],
          ['e', wrongVersionAsset.id, relay.url],
        ],
        id: 'release',
      ));
      relay.textNotes = {
        Bip340.generatePrivateKey(): assetEvent,
        Bip340.generatePrivateKey(): wrongAppAsset,
        Bip340.generatePrivateKey(): wrongVersionAsset,
      };

      final assets = await ndk.software.resolveAssets(
        release,
        relays: [relay.url],
      );
      expect(assets.map((asset) => asset.event.id), [assetEvent.id]);
    });

    test('resolves assets for multiple releases in one request', () async {
      final firstAsset = networkEvent(
        softwareAssetKind,
        [
          ['i', 'com.example.app'],
          ['version', '1.0.0'],
          ['m', androidPackageMimeType],
          ['x', hash],
          ['version_code', '10'],
          ['apk_certificate_hash', certificate],
        ],
        createdAt: 100,
      );
      final secondAsset = networkEvent(
        softwareAssetKind,
        [
          ['i', 'com.example.app'],
          ['version', '2.0.0'],
          ['m', androidPackageMimeType],
          ['x', hash],
          ['version_code', '20'],
          ['apk_certificate_hash', certificate],
        ],
        createdAt: 200,
      );
      final firstRelease = SoftwareRelease.fromEvent(
        event(
          softwareReleaseKind,
          [
            ['i', 'com.example.app'],
            ['version', '1.0.0'],
            ['d', 'com.example.app@1.0.0'],
            ['c', 'main'],
            ['e', firstAsset.id, relay.url],
          ],
          id: 'release-1',
        ),
      );
      final secondRelease = SoftwareRelease.fromEvent(
        event(
          softwareReleaseKind,
          [
            ['i', 'com.example.app'],
            ['version', '2.0.0'],
            ['d', 'com.example.app@2.0.0'],
            ['c', 'main'],
            ['e', secondAsset.id, relay.url],
          ],
          id: 'release-2',
        ),
      );
      relay.textNotes = {
        Bip340.generatePrivateKey(): firstAsset,
        Bip340.generatePrivateKey(): secondAsset,
      };
      final requestsBefore = relay.totalRequestedSubscriptionCount;

      final assets = await ndk.software.resolveAssetsForReleases(
        [firstRelease, secondRelease],
        relays: [relay.url],
      );

      expect(
        assets[firstRelease.event.id]?.single.event.id,
        firstAsset.id,
      );
      expect(
        assets[secondRelease.event.id]?.single.event.id,
        secondAsset.id,
      );
      expect(relay.totalRequestedSubscriptionCount - requestsBefore, 1);
    });
  });
}
