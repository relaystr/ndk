import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:media_kit/media_kit.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_demo/accounts_page.dart';
import 'package:ndk_demo/blossom_page.dart';
import 'package:ndk_demo/demo_app_config.dart';
import 'package:ndk_demo/l10n/app_localizations_context.dart';
import 'package:ndk_demo/l10n/generated/sample_app_localizations.dart';
import 'package:ndk_demo/login_popup.dart';
import 'package:ndk_demo/profile_page.dart';
import 'package:ndk_demo/relays_page.dart';
import 'package:ndk_demo/wallets.dart';
import 'package:ndk_demo/widgets_demo_page.dart';
import 'package:ndk_drift/ndk_drift.dart';
import 'package:ndk_flutter/l10n/app_localizations.dart' as ndk_flutter;
import 'package:ndk_flutter/ndk_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:protocol_handler/protocol_handler.dart';

import 'quantum_secure_page.dart';

bool amberAvailable = false;

late Ndk ndk;
final ndkFlutter = NdkFlutter(ndk: ndk);

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

  final eventVerifier = kIsWeb ? WebEventVerifier() : RustEventVerifier();
  ndk = Ndk(
    NdkConfig(
      eventVerifier: eventVerifier,
      cache: cacheManager,
      walletsRepo: FlutterSecureStorageWalletsRepo(),
      logLevel: Logger.logLevels.info,
      cashuUserSeedphrase: CashuUserSeedphrase(
        seedPhrase: DemoAppConfig.cashuSeedPhrase,
      ),
    ),
  );

  await ndkFlutter.restoreAccountsState();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _currentLocale = const Locale('en');

  void _handleLocaleChanged(Locale locale) {
    setState(() {
      _currentLocale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appName,
      locale: _currentLocale,
      localizationsDelegates: const [
        SampleAppLocalizations.delegate,
        ndk_flutter.AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: SampleAppLocalizations.supportedLocales,
      home: Stack(
        children: [
          SafeArea(
            top: false,
            child: MyHomePage(
              onLocaleChanged: _handleLocaleChanged,
              currentLocale: _currentLocale,
            ),
          ),
          NPendingRequests(ndkFlutter: ndkFlutter),
        ],
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final ValueChanged<Locale> onLocaleChanged;
  final Locale currentLocale;

  const MyHomePage({
    super.key,
    required this.onLocaleChanged,
    required this.currentLocale,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with TickerProviderStateMixin, ProtocolListener {
  late TabController _tabController;
  static const int _profileTabIndex = 1;
  static const int _walletsTabIndex = 4;
  StreamSubscription<Account?>? _authSub;
  late List<Tab> _tabs;
  late List<Widget> _tabPages;
  final GlobalKey<WalletsPageState> _walletsPageKey =
      GlobalKey<WalletsPageState>();
  late final WalletsPage _walletsPage;

// Define a constant for the NWC tab name to avoid magic strings
  static const String nwcTabName = 'NWC';
  static const String quantumSecureTabName = 'Quantum Secure';
  List<Tab> _buildTabs(BuildContext context) {
    final l10n = context.l10n;
    return <Tab>[
      Tab(text: l10n.tabAccounts),
      Tab(text: l10n.tabProfile),
      Tab(text: l10n.tabRelays),
      Tab(text: l10n.tabBlossom),
      Tab(text: l10n.tabWallets),
      Tab(text: l10n.tabWidgets),
      const Tab(text: quantumSecureTabName),
    ];
  }

// Callback method to be passed to AccountsPage
  void _handleAccountChange() {
    if (mounted) {
      setState(() {
// This will trigger a rebuild of _MyHomePageState,
// which in turn rebuilds its children, including the TabBarView
// and the metadata widget with the new account context.
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _walletsPage = WalletsPage(key: _walletsPageKey);

    _tabs = const <Tab>[
      Tab(text: 'Accounts'),
      Tab(text: 'Profile'),
      Tab(text: 'Relays'),
      Tab(text: 'Blossom'),
      Tab(text: 'Wallets'),
      Tab(text: 'Widgets'),
      Tab(text: quantumSecureTabName),
    ];

    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _authSub = ndk.accounts.authStateChanges.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });

    protocolHandler.addListener(this);
    _handleInitialUri();
  }

  Future<void> _handleInitialUri() async {
    try {
      final String? initialUrl = await protocolHandler.getInitialUrl();
      if (initialUrl != null && initialUrl.isNotEmpty) {
        print("_MyHomePageState: Initial URL: $initialUrl");
        onProtocolUrlReceived(initialUrl);
      }
    } catch (e) {
      print("_MyHomePageState: Error getting initial URL: $e");
    }
  }

  void _processUri(Uri uri) {
    if (uri.scheme == 'ndk' && uri.host == 'nwc') {
      print(
          "_MyHomePageState: ndk://nwc URI received, switching to wallets tab.");
      switchToWalletsTab();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _walletsPageKey.currentState?.onProtocolUrlReceived(uri.toString());
      });
    }
  }

  @override
  void onProtocolUrlReceived(String url) {
    print("_MyHomePageState: Received protocol URL: $url");
    if (!mounted) return;
    try {
      final Uri receivedUri = Uri.parse(url);
      _processUri(receivedUri);
    } catch (e) {
      print("_MyHomePageState: Error parsing received protocol URL: $e");
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _tabController.dispose();
    protocolHandler.removeListener(this);
    super.dispose();
  }

  void switchToWalletsTab() {
    if (_tabController.index != _walletsTabIndex) {
      _tabController.animateTo(_walletsTabIndex);
      print(
          "_MyHomePageState: Switched to wallets tab (index $_walletsTabIndex).");
    } else {
      print(
          "_MyHomePageState: Already on wallets tab (index $_walletsTabIndex).");
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    _tabs = _buildTabs(context);

    _tabPages = <Widget>[
      AccountsPage(onAccountChanged: _handleAccountChange),
      ProfilePage(
        ndkFlutter: ndkFlutter,
        getLoggedPubkey: () => ndk.accounts.getPublicKey(),
        onAccountChanged: _handleAccountChange,
      ),
      const RelaysPage(),
      BlossomMediaPage(ndk: ndk),
      _walletsPage,
      WidgetsDemoPage(onAccountChanged: _handleAccountChange),
      const QuantumSecurePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.appBarTitle),
            const SizedBox(width: 8),
            Text(
              'v$packageVersion',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          NLocaleSwitcher(
            currentLocale: widget.currentLocale,
            onLocaleChanged: widget.onLocaleChanged,
          ),
          const SizedBox(width: 4),
          Builder(
            builder: (context) {
              final loggedPubkey = ndk.accounts.getPublicKey();
              final profileIcon = loggedPubkey == null
                  ? CircleAvatar(
                      radius: 14,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    )
                  : NPicture(
                      ndkFlutter: ndkFlutter,
                      circleAvatarRadius: 14,
                    );

              return IconButton(
                tooltip: l10n.profileTooltip,
                onPressed: () {
                  if (loggedPubkey != null) {
                    _tabController.animateTo(_profileTabIndex);
                    return;
                  }

                  showNLoginPopup(
                    context: context,
                    ndkFlutter: ndkFlutter,
                    onLoggedIn: () {
                      _handleAccountChange();
                      _tabController.animateTo(_profileTabIndex);
                    },
                  );
                },
                icon: profileIcon,
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs,
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: _tabPages,
        ),
      ),
    );
  }
}
