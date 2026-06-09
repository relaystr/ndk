import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_demo/l10n/app_localizations_context.dart';
import 'package:ndk_demo/router.dart';
import 'package:ndk_drift/ndk_drift.dart';
import 'package:ndk_flutter/l10n/app_localizations.dart' as ndk_flutter;
import 'package:ndk_flutter/ndk_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:protocol_handler/protocol_handler.dart';

import 'l10n/generated/sample_app_localizations.dart';


bool amberAvailable = false;

late Ndk ndk;
final ndkFlutter = NdkFlutter(ndk: ndk);
final localeNotifier = ValueNotifier<Locale>(const Locale('en'));

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  try {
    await protocolHandler.register("ndk");
  } catch (err) {
    print(err);
  }

  try {
    final amber = Amberflutter();
    amberAvailable = await amber.isAppInstalled();
  } catch (e) {
    // not on android or amber not installed
  }

  final cacheManager = kIsWeb
      ? await DriftCacheManager.create()
      : await SembastCacheManager.create(
          databasePath: (await getApplicationDocumentsDirectory()).path);

  // Load the cashu seed phrase from secure storage, generating a fresh one on
  // first run. Never hardcode this — it controls cashu funds.
  final cashuSeedPhrase = await CashuSeedStore().loadOrCreate();

  final eventVerifier = kIsWeb ? WebEventVerifier() : RustEventVerifier();
  ndk = Ndk(
    NdkConfig(
      eventVerifier: eventVerifier,
      cache: cacheManager,
      walletsRepo: FlutterSecureStorageWalletsRepo(),
      logLevel: Logger.logLevels.info,
      cashuUserSeedphrase: CashuUserSeedphrase(
        seedPhrase: cashuSeedPhrase,
      ),
    ),
  );

  await ndkFlutter.restoreAccountsState();

  GoRouter.optionURLReflectsImperativeAPIs = true;

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with ProtocolListener {
  @override
  void initState() {
    super.initState();
    protocolHandler.addListener(this);
    _handleInitialUri();
  }

  Future<void> _handleInitialUri() async {
    try {
      final String? initialUrl = await protocolHandler.getInitialUrl();
      if (initialUrl != null && initialUrl.isNotEmpty) {
        onProtocolUrlReceived(initialUrl);
      }
    } catch (e) {
      print('MyApp: Error getting initial URL: $e');
    }
  }

  @override
  void onProtocolUrlReceived(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.scheme == 'ndk' && uri.host == 'nwc') {
        appRouter.go('/wallets', extra: url);
      }
    } catch (e) {
      print('MyApp: Error parsing protocol URL: $e');
    }
  }

  @override
  void dispose() {
    protocolHandler.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, _) => MaterialApp.router(
        onGenerateTitle: (context) => context.l10n.appName,
        locale: locale,
        localizationsDelegates: const [
          SampleAppLocalizations.delegate,
          ndk_flutter.AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // Use ndk_flutter's locale list — it's the superset that includes the
        // extra locales (fi, pt, pt_BR) translated in that package. The sample
        // app shell falls back to English for those via the delegate above.
        supportedLocales: ndk_flutter.AppLocalizations.supportedLocales,
        routerConfig: appRouter,
        builder: (context, child) => Stack(
          children: [
            child ?? const SizedBox.shrink(),
            NPendingRequests(ndkFlutter: ndkFlutter),
          ],
        ),
      ),
    );
  }
}
