import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/l10n/app_localizations.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

class _VersionController extends ChangeNotifier
    implements NAppUpdateController {
  @override
  final NAppUpdateState state;
  @override
  final bool hasExternalUpdate;

  _VersionController(this.state, {this.hasExternalUpdate = false});

  @override
  String get currentVersion => '1.0.0';
  @override
  Future<void> acquireReleaseWatch() async {}
  @override
  Future<void> releaseReleaseWatch() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected call: ${invocation.memberName}');
}

class _UnusedAsset implements SoftwareAsset {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Version badge must not read asset details');
}

void main() {
  final release = SoftwareRelease(
    identifier: 'app',
    version: '2.0.0',
    channel: 'main',
    releaseNotes: '',
    assets: const [],
    event: Nip01Event(
      pubKey: 'publisher',
      kind: softwareReleaseKind,
      tags: const [],
      content: '',
    ),
  );
  final update = SoftwareUpdate(release: release, asset: _UnusedAsset());
  for (final brightness in Brightness.values) {
    for (final (name, state, external, visible) in [
      ('external', NAppUpdateState(latestRelease: release), true, true),
      (
        'install',
        NAppUpdateState(status: NAppUpdateStatus.available, update: update),
        false,
        true,
      ),
      (
        'cancelled',
        NAppUpdateState(status: NAppUpdateStatus.cancelled, update: update),
        false,
        true,
      ),
      (
        'current',
        const NAppUpdateState(status: NAppUpdateStatus.upToDate),
        false,
        false,
      ),
      (
        'downloading',
        NAppUpdateState(status: NAppUpdateStatus.downloading, update: update),
        false,
        false,
      ),
    ]) {
      testWidgets('$name release badge in ${brightness.name} theme', (
        tester,
      ) async {
        final controller = _VersionController(
          state,
          hasExternalUpdate: external,
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(body: NAppVersion(controller: controller)),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('v1.0.0'), findsOneWidget);
        final icon = find.byIcon(Icons.download_rounded);
        expect(icon, visible ? findsOneWidget : findsNothing);
        expect(find.byIcon(Icons.open_in_new), findsNothing);
        if (visible) {
          expect(tester.widget<Icon>(icon).size, 14);
          expect(tester.widget<Icon>(icon).color, Colors.white);
          final badge = find
              .ancestor(of: icon, matching: find.byType(Container))
              .first;
          expect(tester.getSize(badge), const Size(20, 20));
          final decoration =
              tester.widget<Container>(badge).decoration! as BoxDecoration;
          expect(decoration.color, const Color(0xFF15803D));
          expect(decoration.borderRadius, BorderRadius.circular(6));
          expect(
            tester.widget<Tooltip>(find.byType(Tooltip)).message,
            contains('2.0.0'),
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
      });
    }
  }
}
