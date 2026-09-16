import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/l10n/app_localizations.dart';
import 'package:ndk_flutter/main/ndk_flutter.dart';
import 'package:ndk_flutter/widgets/message_of_the_day/motd_data.dart';
import 'package:ndk_flutter/widgets/message_of_the_day/n_motd_config.dart';
import 'package:ndk_flutter/widgets/message_of_the_day/n_motd_controller.dart';
import 'package:ndk_flutter/widgets/message_of_the_day/n_motd_popup.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubRequests implements Requests {
  final List<Nip01Event> events;

  _StubRequests(this.events);

  @override
  NdkResponse query({
    Filter? filter,
    List<Filter>? filters,
    String name = '',
    RelaySet? relaySet,
    bool cacheRead = true,
    bool cacheWrite = true,
    Duration? timeout,
    Function()? timeoutCallbackUserFacing,
    Function()? timeoutCallback,
    Iterable<String>? explicitRelays,
    int? desiredCoverage,
    RelayAuth? auth,
    List<Account>? authenticateAs,
    bool paginate = false,
  }) {
    return NdkResponse(
      'query',
      Stream<Nip01Event>.fromIterable(events),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected Requests call: ${invocation.memberName}');
}

class _StubNdk implements Ndk {
  final List<Nip01Event> events;

  _StubNdk(this.events);

  @override
  Requests get requests => _StubRequests(events);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected NDK call: ${invocation.memberName}');
}

Nip01Event _motdEvent({
  required String id,
  String content = 'Hello world',
  List<List<String>> tags = const [
    ['d', 'motd'],
  ],
}) => Nip01Event(
  id: id,
  pubKey: 'author',
  kind: MotdData.kKind,
  tags: tags,
  content: content,
  createdAt: 100,
);

Future<void> _pump(
  WidgetTester tester,
  NMotdController controller, {
  String? appVersion,
  NMotdConfig config = const NMotdConfig(),
}) async {
  tester.view.physicalSize = const Size(1200, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: NMotdPopup(
          controller: controller,
          appVersion: appVersion,
          config: config,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows dialog with message and close button', (tester) async {
    final controller = NMotdController(
      ndkFlutter: NdkFlutter(
        ndk: _StubNdk([
          _motdEvent(id: 'event-1', content: 'Hello world'),
        ]),
      ),
      authorPubkey: 'author',
    );
    await controller.start();

    await _pump(tester, controller);

    expect(find.text('Hello world'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
    expect(find.text('Learn more'), findsNothing);
  });

  testWidgets('shows link button when a url tag is present', (tester) async {
    final controller = NMotdController(
      ndkFlutter: NdkFlutter(
        ndk: _StubNdk([
          _motdEvent(
            id: 'event-1',
            content: 'Visit us',
            tags: const [
              ['d', 'motd'],
              ['url', 'https://example.com'],
            ],
          ),
        ]),
      ),
      authorPubkey: 'author',
    );
    await controller.start();

    await _pump(tester, controller);

    expect(find.text('Visit us'), findsOneWidget);
    expect(find.text('Learn more'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets('dismisses on close and does not reopen', (tester) async {
    final controller = NMotdController(
      ndkFlutter: NdkFlutter(
        ndk: _StubNdk([
          _motdEvent(id: 'event-1', content: 'Hello world'),
        ]),
      ),
      authorPubkey: 'author',
    );
    await controller.start();

    await _pump(tester, controller);
    expect(find.text('Hello world'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Hello world'), findsNothing);
    expect(controller.shouldShow(), isFalse);
  });

  testWidgets('does not show when app version is not newer', (tester) async {
    final controller = NMotdController(
      ndkFlutter: NdkFlutter(
        ndk: _StubNdk([
          _motdEvent(
            id: 'event-1',
            content: 'Update needed',
            tags: const [
              ['d', 'motd'],
              ['version', '1.2.0'],
            ],
          ),
        ]),
      ),
      authorPubkey: 'author',
    );
    await controller.start();

    // App is at 2.0.0 which is newer than the event version -> no popup.
    await _pump(tester, controller, appVersion: '2.0.0');
    expect(find.text('Update needed'), findsNothing);

    // Fresh controller, app at 1.0.0 which is older -> popup shows.
    final olderApp = NMotdController(
      ndkFlutter: NdkFlutter(
        ndk: _StubNdk([
          _motdEvent(
            id: 'event-1',
            content: 'Update needed',
            tags: const [
              ['d', 'motd'],
              ['version', '1.2.0'],
            ],
          ),
        ]),
      ),
      authorPubkey: 'author',
    );
    await olderApp.start();
    await _pump(tester, olderApp, appVersion: '1.0.0');
    expect(find.text('Update needed'), findsOneWidget);
  });

  testWidgets('honors config title and button text', (tester) async {
    final controller = NMotdController(
      ndkFlutter: NdkFlutter(
        ndk: _StubNdk([
          _motdEvent(
            id: 'event-1',
            content: 'Hello',
            tags: const [
              ['d', 'motd'],
              ['url', 'https://example.com'],
            ],
          ),
        ]),
      ),
      authorPubkey: 'author',
    );
    await controller.start();

    await _pump(
      tester,
      controller,
      config: const NMotdConfig(
        title: 'Custom title',
        closeButtonText: 'Got it',
        linkButtonText: 'Read more',
      ),
    );

    expect(find.text('Custom title'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);
    expect(find.text('Read more'), findsOneWidget);
  });

  testWidgets('falls back to the localized default title without a title tag',
      (tester) async {
    final controller = NMotdController(
      ndkFlutter: NdkFlutter(
        ndk: _StubNdk([
          _motdEvent(id: 'event-1', content: 'Hello world'),
        ]),
      ),
      authorPubkey: 'author',
    );
    await controller.start();

    await _pump(tester, controller);

    expect(find.text('Message of the day'), findsOneWidget);
    expect(find.text('Hello world'), findsOneWidget);
  });

  testWidgets('uses the event title tag over the config title',
      (tester) async {
    final controller = NMotdController(
      ndkFlutter: NdkFlutter(
        ndk: _StubNdk([
          _motdEvent(
            id: 'event-1',
            content: 'Hi there',
            tags: const [
              ['d', 'motd'],
              ['title', 'Breaking news'],
            ],
          ),
        ]),
      ),
      authorPubkey: 'author',
    );
    await controller.start();

    await _pump(
      tester,
      controller,
      config: const NMotdConfig(title: 'Custom title'),
    );

    expect(find.text('Breaking news'), findsOneWidget);
    expect(find.text('Custom title'), findsNothing);
    expect(find.text('Message of the day'), findsNothing);
  });
}