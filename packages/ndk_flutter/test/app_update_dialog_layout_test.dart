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

class _UnusedNdk implements Ndk {
  @override
  final Accounts accounts = _UnusedAccounts();

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

void main() {
  testWidgets('release summary navigation tile fits narrow dialog', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(300, 640);
    addTearDown(tester.view.reset);

    final release = SoftwareRelease(
      identifier: 'app',
      version: '1.0.0',
      channel: 'main',
      releaseNotes: '',
      assets: const [],
      event: Nip01Event(
        id: 'release',
        pubKey:
            '0000000000000000000000000000000000000000000000000000000000000000',
        kind: softwareReleaseKind,
        tags: const [],
        content: '',
        createdAt: 1,
      ),
    );
    final controller = _DialogController(
      NAppUpdateState(
        status: NAppUpdateStatus.upToDate,
        currentRelease: release,
        latestRelease: release,
        releases: [release],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('de'),
        home: NAppUpdateDialog(controller: controller),
      ),
    );
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
}
