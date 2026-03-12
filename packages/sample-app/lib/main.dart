import 'package:amberflutter/amberflutter.dart';
import 'package:drift_cache_manager/drift_cache_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ndk_flutter/l10n/app_localizations.dart' as ndk_flutter;
import 'package:ndk_flutter/ndk_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_demo/accounts_page.dart';
import 'package:ndk_demo/blossom_page.dart';
import 'package:ndk_demo/demo_app_config.dart';
import 'package:ndk_demo/nwc_page.dart';
import 'package:ndk_demo/relays_page.dart';
import 'package:ndk_demo/wallets.dart';
import 'package:ndk_demo/verifiers_performance.dart';
import 'package:ndk_demo/widgets_demo_page.dart';
import 'package:ndk_demo/pending_requests_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:protocol_handler/protocol_handler.dart';
import 'package:sembast_cache_manager/sembast_cache_manager.dart';

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
      : await SembastCacheManager.create(databasePath: (await getApplicationDocumentsDirectory()).path);

  final eventVerifier = kIsWeb ? WebEventVerifier() : RustEventVerifier();
  ndk = Ndk(
    NdkConfig(
      eventVerifier: Bip340EventVerifier(),
      cache: MemCacheManager(),
      logLevel: Logger.logLevels.trace,
      cashuUserSeedphrase: CashuUserSeedphrase(
        seedPhrase: DemoAppConfig.cashuSeedPhrase,
      ),
    ),
  );

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
      title: 'Nostr Developer Kit Demo',
      locale: _currentLocale,
      localizationsDelegates: const [
        ndk_flutter.AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: ndk_flutter.AppLocalizations.supportedLocales,
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

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin, ProtocolListener {
  late TabController _tabController;
  late List<Tab> _tabs;
  late List<Widget> _tabPages;

// Define a constant for the NWC tab name to avoid magic strings
  static const String nwcTabName = 'NWC';

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

    _tabs = <Tab>[
      const Tab(text: 'Accounts'),
      const Tab(text: 'Metadata'),
      const Tab(text: 'Relays'),
      const Tab(text: nwcTabName),
      const Tab(text: "Blossom"),
      const Tab(text: 'Verifiers'),
      const Tab(text: "Wallets"),
      const Tab(text: 'Widgets'),
      const Tab(text: 'Pending'),
    ];

    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
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
      print("_MyHomePageState: ndk://nwc URI received, switching to NwcPage tab.");
      switchToNwcTab();
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
    _tabController.dispose();
    protocolHandler.removeListener(this);
    super.dispose();
  }

  void switchToNwcTab() {
    int nwcPageIndex = -1;
    for (int i = 0; i < _tabs.length; i++) {
      if (_tabs[i].text == nwcTabName) {
        nwcPageIndex = i;
        break;
      }
    }

    if (nwcPageIndex != -1) {
      if (_tabController.index != nwcPageIndex) {
        _tabController.animateTo(nwcPageIndex);
        print("_MyHomePageState: Switched to NWC tab (index $nwcPageIndex).");
      } else {
        print("_MyHomePageState: Already on NWC tab (index $nwcPageIndex).");
      }
    } else {
      print("_MyHomePageState: NWC tab not found by name '$nwcTabName'. Cannot switch.");
    }
  }

  @override
  Widget build(BuildContext context) {
    _tabs = <Tab>[
      const Tab(text: 'Accounts'),
      const Tab(text: 'Metadata'),
      const Tab(text: 'Relays'),
      const Tab(text: nwcTabName),
      const Tab(text: "Blossom"),
      const Tab(text: 'Verifiers'),
      const Tab(text: "Wallets"),
      const Tab(text: 'Widgets'),
      const Tab(text: 'Pending'),
    ];

    _tabPages = <Widget>[
      AccountsPage(onAccountChanged: _handleAccountChange),
      metadata(ndk, context),
      const RelaysPage(),
      const NwcPage(),
      BlossomMediaPage(ndk: ndk),
      VerifiersPerformancePage(ndk: ndk),
      WalletsPage(ndk: ndk),
      WidgetsDemoPage(onAccountChanged: _handleAccountChange),
      const PendingRequestsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nostr Development Kit Demo'),
        actions: [
          NLocaleSwitcher(
            currentLocale: widget.currentLocale,
            onLocaleChanged: widget.onLocaleChanged,
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

/// how to fetch metadata info
Widget metadata(Ndk ndk, BuildContext context) {
  final loggedInAccount = ndk.accounts.getLoggedAccount();
  final String? pubkey = loggedInAccount?.pubkey;

  if (pubkey == null) {
    return const Center(
        child: Padding(
      padding: EdgeInsets.all(16.0),
      child: Text('Please log in via the "Accounts" tab to view your metadata.', textAlign: TextAlign.center),
    ));
  }

  final Future<Metadata?> response = ndk.metadata.loadMetadata(pubkey);

  return FutureBuilder<Metadata?>(
    future: response,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError) {
        return Center(child: Text('Error fetching metadata: ${snapshot.error}'));
      } else if (snapshot.hasData && snapshot.data != null) {
        final metadata = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                if (metadata.picture != null && metadata.picture!.isNotEmpty)
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(metadata.picture!),
                    onBackgroundImageError: (exception, stackTrace) {
                      print("Error loading avatar in metadata tab: $exception");
                    },
                    child: metadata.picture == null || metadata.picture!.isEmpty
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  )
                else
                  const CircleAvatar(
                    radius: 50,
                    child: Icon(Icons.person, size: 50),
                  ),
                const SizedBox(height: 16),
                Text('Name: ${metadata.name ?? 'N/A'}', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Display Name: ${metadata.displayName ?? 'N/A'}'),
                Text('NIP-05: ${metadata.nip05 ?? 'N/A'}'),
                const SizedBox(height: 8),
                Text('About:', style: Theme.of(context).textTheme.titleMedium),
                Text(metadata.about ?? 'N/A', textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('Website: ${metadata.website ?? 'N/A'}'),
                Text('Lud06: ${metadata.lud06 ?? 'N/A'}'),
                Text('Lud16: ${metadata.lud16 ?? 'N/A'}'),
              ],
            ),
          ),
        );
      } else {
        return const Center(
            child: Text('Metadata not found for this account. You might need to set it in a Nostr client.'));
      }
    },
  );
}
