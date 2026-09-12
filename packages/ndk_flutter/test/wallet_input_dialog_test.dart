import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/l10n/app_localizations.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

const offer =
    'lno1pqqq5xj5wajkcan9gdshx6pq23jhxarfdenjqstyv3ex2umnzcss80xkrjkyrjk43u5dgu8f6a450fg2cnjtg7lhg76c3gtk5gdhshns';

class UnusedNdk implements Ndk {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected NDK access');
}

class RecordingAuthCoordinator extends NwcWalletAuthCoordinator {
  Uri? endpoint;
  String? app;
  String? relay;
  String? callbackUrl;
  String? provider;
  String? servicePubkey;
  NdkFlutter? discoveryNdkFlutter;
  bool? allowUntaggedInfoEvent;
  Map<String, String>? query;

  @override
  Future<void> connectWebWalletAuth(
    BuildContext context, {
    required Uri authorizationEndpoint,
    required String appName,
    required String discoveryRelay,
    required String callback,
    required String walletName,
    String? providerId,
    String? walletServicePubkey,
    NdkFlutter? waitForDiscoveryNdkFlutter,
    bool allowUntaggedInfoEvent = false,
    Map<String, String> additionalQueryParameters = const {},
  }) async {
    endpoint = authorizationEndpoint;
    app = appName;
    relay = discoveryRelay;
    callbackUrl = callback;
    provider = providerId;
    servicePubkey = walletServicePubkey;
    discoveryNdkFlutter = waitForDiscoveryNdkFlutter;
    query = additionalQueryParameters;
    this.allowUntaggedInfoEvent = allowUntaggedInfoEvent;
  }
}

class FakeCamera extends StatefulWidget {
  final ValueChanged<String> onScan;
  final VoidCallback onDispose;
  const FakeCamera({super.key, required this.onScan, required this.onDispose});
  @override
  State<FakeCamera> createState() => _FakeCameraState();
}

class _FakeCameraState extends State<FakeCamera> {
  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => widget.onScan(offer),
    child: const Text('Decode QR'),
  );
}

Future<AppLocalizations> openWalletInput(
  WidgetTester tester, {
  WalletQrScannerBuilder? camera,
  NwcWalletAuthCoordinator? coordinator,
  List<NwcConnectionOption>? options,
}) async {
  tester.view.physicalSize = const Size(1200, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  late AppLocalizations l10n;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context)!;
            return TextButton(
              onPressed: () => showAddWalletTypeDialog(
                context,
                NdkFlutter(ndk: UnusedNdk()),
                walletQrScannerBuilder: camera,
                nwcWalletAuthCoordinator: coordinator,
                nwcConnectionOptions: options,
              ),
              child: const Text('Add wallet'),
            );
          },
        ),
      ),
    ),
  );
  await tester.tap(find.text('Add wallet'));
  await tester.pumpAndSettle();
  return l10n;
}

void main() {
  testWidgets('camera-free default supports manual BOLT12 confirmation', (
    tester,
  ) async {
    final l10n = await openWalletInput(tester);
    expect(find.text(l10n.cameraNotAvailable), findsOneWidget);
    await tester.tap(find.text(l10n.pasteOrEnter));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, offer);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.reviewWallet));
    await tester.pumpAndSettle();
    expect(find.text(l10n.confirm), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('camera decoding reaches confirmation and releases camera', (
    tester,
  ) async {
    var disposals = 0;
    final l10n = await openWalletInput(
      tester,
      camera: (_, onScan, onError) =>
          FakeCamera(onScan: onScan, onDispose: () => disposals++),
    );
    tester.widget<FakeCamera>(find.byType(FakeCamera)).onScan(offer);
    await tester.pumpAndSettle();
    expect(disposals, 1);
    expect(find.text(l10n.confirm), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'nested manual dialog disposes camera and cancellation resumes it',
    (tester) async {
      var disposals = 0;
      final l10n = await openWalletInput(
        tester,
        camera: (_, onScan, onError) =>
            FakeCamera(onScan: onScan, onDispose: () => disposals++),
      );
      await tester.tap(find.text(l10n.pasteOrEnter));
      await tester.pumpAndSettle();
      expect(disposals, 1);
      expect(find.byType(FakeCamera), findsNothing);
      await tester.tap(find.text(l10n.cancel).last);
      await tester.pumpAndSettle();
      expect(find.byType(FakeCamera), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('wallet chooser and nested NWC scanner share host camera', (
    tester,
  ) async {
    var disposals = 0;
    final l10n = await openWalletInput(
      tester,
      camera: (_, onScan, onError) =>
          FakeCamera(onScan: onScan, onDispose: () => disposals++),
    );
    await tester.tap(find.text(l10n.chooseWallet));
    await tester.pumpAndSettle();
    expect(disposals, 1);
    expect(find.text('Coinos'), findsOneWidget);
    await tester.tap(find.text('NWC'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.scanWalletQrCode).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(FakeCamera), findsOneWidget);
    tester.widget<FakeCamera>(find.byType(FakeCamera)).onScan(offer);
    await tester.pumpAndSettle();
    expect(disposals, 2);
    expect(find.byType(FakeCamera), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller!.text,
      offer,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('camera failure stays visible and manual input remains usable', (
    tester,
  ) async {
    final l10n = await openWalletInput(
      tester,
      camera: (_, onScan, onError) => TextButton(
        onPressed: () => onError(StateError('Camera denied')),
        child: const Text('Fail camera'),
      ),
    );
    await tester.tap(find.text('Fail camera'));
    await tester.pumpAndSettle();
    expect(find.text('Bad state: Camera denied'), findsOneWidget);
    await tester.tap(find.text(l10n.pasteOrEnter));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('connection status releases camera and idle resumes it', (
    tester,
  ) async {
    final coordinator = NwcWalletAuthCoordinator();
    var disposals = 0;
    final l10n = await openWalletInput(
      tester,
      coordinator: coordinator,
      camera: (_, onScan, onError) =>
          FakeCamera(onScan: onScan, onDispose: () => disposals++),
    );
    coordinator.connectionState.value =
        const WalletConnectionState.awaitingReturn('Coinos');
    await tester.pump();
    expect(disposals, 1);
    expect(find.byType(FakeCamera), findsNothing);
    expect(find.widgetWithText(OutlinedButton, l10n.cancel), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, l10n.cancel));
    await tester.pumpAndSettle();
    expect(coordinator.connectionState.value.phase, WalletConnectionPhase.idle);
    expect(find.byType(FakeCamera), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('connected status closes scanner with nested chooser open', (
    tester,
  ) async {
    final coordinator = NwcWalletAuthCoordinator();
    final l10n = await openWalletInput(
      tester,
      coordinator: coordinator,
      options: [
        NwcConnectionOption(
          id: 'custom',
          label: 'Connected wallet',
          connect: (_, _, _) async {
            coordinator.connectionState.value =
                const WalletConnectionState.connected('Coinos');
          },
        ),
      ],
    );
    await tester.tap(find.text(l10n.chooseWallet));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Connected wallet'));
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle), findsNothing);
    expect(find.text(l10n.walletConnectionConnected('Coinos')), findsNothing);
    expect(find.text('Add wallet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('provider overrides replace presets in shared chooser', (
    tester,
  ) async {
    final l10n = await openWalletInput(
      tester,
      options: [
        NwcConnectionOption(
          id: 'custom',
          label: 'My wallet',
          connect: (_, _, _) async {},
        ),
      ],
    );
    await tester.tap(find.text(l10n.chooseWallet));
    await tester.pumpAndSettle();
    expect(find.text('Coinos'), findsNothing);
    expect(find.text('My wallet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('desktop wallet chooser enables Alby Go QR connection', (
    tester,
  ) async {
    final l10n = await openWalletInput(tester);
    await tester.tap(find.text(l10n.chooseWallet));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.albyWalletOption));
    await tester.pumpAndSettle();

    final albyGoTile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, l10n.albyGoOption),
    );
    expect(albyGoTile.enabled, isTrue);
    await tester.tap(find.widgetWithText(ListTile, l10n.albyGoOption));
    await tester.pumpAndSettle();
    expect(find.text(l10n.walletConnectionFinishIn('Alby Go')), findsOneWidget);
    expect(find.text(l10n.albyGoQrScanInstructions), findsOneWidget);
    expect(find.text(l10n.confirm), findsNothing);
    await tester.tap(find.text(l10n.cancel).last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('web presets preserve host callback and provider discovery', (
    tester,
  ) async {
    const config = AlbyGoConnectConfig(
      appName: 'BitBlik',
      appIconUrl: 'https://example.com/icon.png',
      callback: 'bitblik://nwc-callback',
      discoveryRelay: 'wss://example.com',
    );
    final coordinator = RecordingAuthCoordinator();
    final options = defaultNwcConnectionOptions(config: config);
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    final context = tester.element(find.byType(Scaffold));
    final ndkFlutter = NdkFlutter(ndk: UnusedNdk());

    await options.first.connect(context, ndkFlutter, coordinator);
    expect(coordinator.endpoint.toString(), 'https://my.albyhub.com/apps/new');
    expect(coordinator.app, config.appName);
    expect(coordinator.callbackUrl, config.callback);
    expect(coordinator.relay, config.discoveryRelay);
    expect(coordinator.query, {'return_to': config.callback});
    expect(coordinator.provider, 'alby');
    expect(coordinator.discoveryNdkFlutter, same(ndkFlutter));
    expect(coordinator.allowUntaggedInfoEvent, isFalse);

    await options.last.connect(context, ndkFlutter, coordinator);
    expect(coordinator.endpoint.toString(), 'https://coinos.io/apps/new');
    expect(coordinator.app, config.appName);
    expect(coordinator.callbackUrl, config.callback);
    expect(coordinator.relay, 'wss://relay.coinos.io');
    expect(
      coordinator.servicePubkey,
      'ba80990666ef0b6f4ba5059347beb13242921e54669e680064ca755256a1e3a6',
    );
    expect(coordinator.provider, 'coinos');
    expect(coordinator.discoveryNdkFlutter, same(ndkFlutter));
    expect(coordinator.allowUntaggedInfoEvent, isTrue);
  });
}
