import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/l10n/app_localizations.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

class _UnusedAccounts implements Accounts {
  @override
  bool get canSign => false;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Accounts are not needed for this layout test');
}

class _UnusedMetadatas implements Metadatas {
  @override
  Future<Metadata?> loadMetadata(
    String pubKey, {
    bool forceRefresh = false,
    Duration idleTimeout = Duration.zero,
  }) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected metadata call: ${invocation.memberName}');
}

class _UnusedNdk implements Ndk {
  @override
  final Accounts accounts = _UnusedAccounts();

  @override
  final Metadatas metadata = _UnusedMetadatas();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('NDK is not needed for this layout test');
}

class _DialogController extends ChangeNotifier implements NAppUpdateController {
  _DialogController(this.state) : ndkFlutter = NdkFlutter(ndk: _UnusedNdk());

  @override
  final NAppUpdateState state;

  @override
  final NdkFlutter ndkFlutter;

  @override
  bool get hasExternalUpdate => false;

  @override
  bool get installationEnabled => false;

  @override
  String get currentVersion => '1.0.0';

  @override
  List<String> get relays => const [];

  @override
  SoftwareAppRef? get zapTargetApp => null;

  @override
  Duration get engagementQueryTimeout => Duration.zero;

  @override
  Duration get engagementMetadataTimeout => Duration.zero;

  @override
  SoftwareAsset? assetForRelease(SoftwareRelease release) => null;

  @override
  Future<void> checkNow({bool allowDuringInstaller = false}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected call: ${invocation.memberName}');
}

SoftwareRelease _release() => SoftwareRelease(
  identifier: 'app',
  version: '1.0.0',
  channel: 'main',
  releaseNotes: '',
  assets: const [],
  event: Nip01Event(
    id: 'release',
    pubKey: '0000000000000000000000000000000000000000000000000000000000000000',
    kind: softwareReleaseKind,
    tags: const [],
    content: '',
    createdAt: 1,
  ),
);

_DialogController _controller() {
  final release = _release();
  return _DialogController(
    NAppUpdateState(
      status: NAppUpdateStatus.upToDate,
      currentRelease: release,
      latestRelease: release,
      releases: [release],
    ),
  );
}

Widget _app(_DialogController controller) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('de'),
  home: NAppUpdateDialog(controller: controller),
);

void main() {
  testWidgets('release summary navigation tile fits narrow dialog', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(300, 640);
    addTearDown(tester.view.reset);

    final controller = _controller();

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsOneWidget);
    expect(find.text('1.0.0'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
    expect(find.byIcon(Icons.bolt), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(tester.widget<ListTile>(find.byType(ListTile)).onTap, isNotNull);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('release details use bounded dialog with persistent close', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 800);
    addTearDown(tester.view.reset);
    final controller = _controller();

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    final dialogContent = find.byKey(
      const ValueKey('release-details-dialog-content'),
    );
    expect(dialogContent, findsOneWidget);
    expect(tester.getSize(dialogContent).width, lessThanOrEqualTo(640));
    expect(tester.getSize(dialogContent).height, lessThanOrEqualTo(720));
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.close), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('release details use full-screen dialog on compact width', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final controller = _controller();

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('release-details-dialog-content')),
      findsNothing,
    );
    final dialog = find.ancestor(
      of: find.byIcon(Icons.close),
      matching: find.byType(Dialog),
    );
    expect(dialog, findsOneWidget);
    expect(tester.getSize(dialog), const Size(390, 844));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.close), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}
