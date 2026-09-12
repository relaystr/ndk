import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/ndk_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _UnusedNdk implements Ndk {
  int calls = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    throw StateError('NDK must not be used after disposal');
  }
}

class _PendingInstaller extends UpdateInstaller {
  final installed = Completer<InstalledSoftware>();
  final requested = Completer<void>();
  final events = StreamController<double>.broadcast();

  @override
  Stream<double> get progress => events.stream;

  @override
  Future<InstalledSoftware> getInstalledSoftware() {
    requested.complete();
    return installed.future;
  }

  @override
  Future<UpdateInstallResult> downloadAndInstall(SoftwareAsset asset) =>
      throw UnimplementedError();
}

class _UnusedRequests implements Requests {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Requests must not be called directly');
}

class _ReleaseSoftware extends Software {
  final List<SoftwareRelease> releases;

  _ReleaseSoftware(this.releases) : super(requests: _UnusedRequests());

  @override
  Future<List<SoftwareRelease>> getReleases({
    required SoftwareAppRef app,
    String channel = 'main',
    Iterable<String>? relays,
    Duration? timeout,
  }) async => releases;
}

class _ReleaseNdk implements Ndk {
  @override
  final Software software;

  _ReleaseNdk(List<SoftwareRelease> releases)
    : software = _ReleaseSoftware(releases);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected NDK call: ${invocation.memberName}');
}

class _ReadOnlyInstaller extends UpdateInstaller {
  bool packageLookupCalled = false;

  @override
  Stream<double> get progress => const Stream.empty();

  @override
  Future<InstalledSoftware> getInstalledSoftware() {
    packageLookupCalled = true;
    throw StateError('Package lookup must stay Android-only');
  }

  @override
  Future<UpdateInstallResult> downloadAndInstall(SoftwareAsset asset) =>
      throw StateError('Install must stay Android-only');
}

SoftwareRelease _release(String version, int createdAt) => SoftwareRelease(
  identifier: 'app',
  version: version,
  channel: 'main',
  releaseNotes: 'Changes in $version',
  assets: const [SoftwareAssetRef(eventId: 'asset')],
  event: Nip01Event(
    id: 'release-$version',
    pubKey: 'publisher',
    kind: softwareReleaseKind,
    tags: const [],
    content: '',
    createdAt: createdAt,
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _UnusedNdk ndk;
  late _PendingInstaller installer;
  late NAppUpdateController controller;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ndk = _UnusedNdk();
    installer = _PendingInstaller();
    controller = NAppUpdateController(
      ndkFlutter: NdkFlutter(ndk: ndk),
      app: const SoftwareAppRef(publisher: 'publisher', identifier: 'app'),
      installer: installer,
      installationEnabled: true,
    );
  });

  tearDown(() async {
    await installer.events.close();
  });

  test('disposal during startup prevents new subscriptions', () async {
    final startup = controller.acquireReleaseWatch();
    controller.dispose();
    await startup;

    expect(installer.events.hasListener, isFalse);
    expect(installer.requested.isCompleted, isFalse);
    expect(ndk.calls, 0);
  });

  test(
    'pending check failure after disposal does not notify or watch',
    () async {
      final startup = controller.acquireReleaseWatch();
      await installer.requested.future;
      final state = controller.state;
      controller.dispose();
      installer.installed.completeError(StateError('package lookup failed'));
      await startup;

      expect(controller.state, same(state));
      expect(installer.events.hasListener, isFalse);
      expect(ndk.calls, 0);
    },
  );

  test('read-only platforms discover releases without package APIs', () async {
    final releases = [_release('2.0.0', 2), _release('1.0.0', 1)];
    final readOnlyInstaller = _ReadOnlyInstaller();
    final readOnlyController = NAppUpdateController(
      ndkFlutter: NdkFlutter(ndk: _ReleaseNdk(releases)),
      app: const SoftwareAppRef(publisher: 'publisher', identifier: 'app'),
      installer: readOnlyInstaller,
      currentVersion: '1.0.0',
      externalUpdateUrl: Uri.parse('https://github.com/relaystr/ndk/'),
      installationEnabled: false,
    );

    await readOnlyController.start();

    expect(readOnlyInstaller.packageLookupCalled, isFalse);
    expect(readOnlyController.state.releases, releases);
    expect(readOnlyController.state.currentRelease?.version, '1.0.0');
    expect(readOnlyController.state.latestRelease?.version, '2.0.0');
    expect(readOnlyController.hasExternalUpdate, isTrue);
    expect(readOnlyController.state.update, isNull);
    readOnlyController.dispose();
  });

  test('Android installer sends every asset URL in publisher order', () async {
    const channel = MethodChannel('ndk/app_updates');
    MethodCall? capturedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          capturedCall = call;
          return 'awaitingUserAction';
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final asset = SoftwareAsset.fromEvent(
      Nip01Event(
        id: 'asset',
        pubKey: 'publisher',
        kind: softwareAssetKind,
        tags: const [
          ['i', 'app'],
          ['version', '2.0.0'],
          ['m', androidPackageMimeType],
          [
            'x',
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          ],
          ['url', 'https://github.example/app.apk'],
          ['url', 'https://cdn.example/app.apk'],
          ['version_code', '2'],
          [
            'apk_certificate_hash',
            'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
          ],
        ],
        content: '',
        createdAt: 1,
      ),
    );

    final result = await AndroidPackageInstaller().downloadAndInstall(asset);

    expect(result, UpdateInstallResult.awaitingUserAction);
    expect(capturedCall?.method, 'downloadAndInstall');
    expect(capturedCall?.arguments['urls'], [
      'https://github.example/app.apk',
      'https://cdn.example/app.apk',
    ]);
  });
}
