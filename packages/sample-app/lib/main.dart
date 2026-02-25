import 'package:amberflutter/amberflutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ndk_flutter/l10n/app_localizations.dart' as ndk_flutter;
import 'package:ndk_flutter/ndk_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_demo/accounts_page.dart';
import 'package:ndk_demo/blossom_page.dart';
import 'package:ndk_demo/nwc_page.dart';
import 'package:ndk_demo/relays_page.dart';
import 'package:ndk_demo/verifiers_performance.dart';
import 'package:ndk_demo/widgets_demo_page.dart';
import 'package:ndk_demo/pending_requests_page.dart';
import 'package:protocol_handler/protocol_handler.dart';


bool amberAvailable = false;

final ndk = Ndk(
  NdkConfig(
    eventVerifier: Bip340EventVerifier(),
    cache: MemCacheManager(),
    logLevel: Logger.logLevels.trace,
  ),
);

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

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final GlobalKey<_MyHomePageState> _homePageKey =
      GlobalKey<_MyHomePageState>();

  // final _router = GoRouter(
  //   routes: [
  //     GoRoute(
  //       path: '/',
  //       builder: (context, state) => const HomePage(),
  //     ),
  //   ],
  // );

  @override
  Widget build(BuildContext context) {
    // return ProviderScope(
    //   child: HomePage()
    //   // child: AppBase(
    //   //   title: 'NDK Demo',
    //   //   routerConfig: _router,
    //   //   appLogo: Icon(Icons.add),
    //   //   // Image.asset(
    //   //   //   'assets/images/logo.png',
    //   //   //   fit: BoxFit.contain,
    //   //   // ),
    //   //   darkAppLogo: Icon(Icons.add),
    //   //
    //   // // Image.asset(
    //   //   //   'assets/images/logo_dark.png',
    //   //   //   fit: BoxFit.contain,
    //   //   // ),
    //   // ),
    // );

    return MaterialApp(
      title: 'Nostr Developer Kit Demo',
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
            child: MyHomePage(key: _homePageKey),
          ),
          NPendingRequests(ndkFlutter: ndkFlutter),
        ],
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  // Removed static GlobalKey. The key is now passed via constructor by MyApp.
  // The constructor now implicitly uses super.key for the key passed by MyApp.
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with TickerProviderStateMixin, ProtocolListener {
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

    // _tabs and _tabPages will be more dynamically defined in the build method
    // to ensure they use the latest context and state.
    // Initialize _tabController with a fixed length or a length derived from a preliminary _tabs definition.
    // For now, assuming a fixed number of tabs (e.g., 6) as per previous structure.
    // If tab count is dynamic (e.g. with amberAvailable), this needs careful management.
    _tabs = <Tab>[
      // Define _tabs here for TabController length
      const Tab(text: 'Accounts'),
      const Tab(text: 'Metadata'),
      const Tab(text: 'Relays'),
      const Tab(text: nwcTabName),
      const Tab(text: "Blossom"),
      const Tab(text: 'Verifiers'),
      const Tab(text: 'Widgets'),
      const Tab(text: 'Pending'),
    ];
    // If amberAvailable leads to a 6th tab, it should be consistently defined.
    // Let's assume 5 base tabs and Amber is conditional, making length 5 or 6.
    // For simplicity with TabController, let's assume a fixed number of main tabs, e.g., 5,
    // and handle conditional ones by adjusting TabController length or having placeholder.
    // The original code had 5 non-commented tabs + conditional Amber.
    // Let's stick to the 5 main tabs for TabController length initially,
    // and adjust if Amber is included.
    // The provided code snippet for _tabs has 5 items.

    // Re-evaluating the original _tabs list:
    // 1. Accounts, 2. Metadata, 3. Relays, 4. NWC, 5. Blossom. That's 5.
    // If Amber is added, it becomes 6.
    // The TabController was initialized with _tabs.length.

    // Let's define _tabs consistently for initState and build.
    // The main change is how _tabPages is constructed in build() to pass the callback.

    _tabController = TabController(
        length: 8,
        vsync:
            this); // Fixed length to 8 (Accounts, Metadata, Relays, NWC, Blossom, Verifiers, Widgets)
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
      print(
          "_MyHomePageState: ndk://nwc URI received, switching to NwcPage tab.");
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
    // Find the index of the NWC tab using the centralized _tabs list.
    int nwcPageIndex = -1;
    for (int i = 0; i < _tabs.length; i++) {
      // Tab.text can be null if a child widget is used instead.
      // We are assuming Tab(text: 'NWC') is used.
      if (_tabs[i].text == nwcTabName) {
        // Use the constant
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
      print(
          "_MyHomePageState: NWC tab not found by name '$nwcTabName'. Cannot switch.");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define _tabs and _tabPages here to ensure they are reconstructed with the latest state.
    _tabs = <Tab>[
      const Tab(text: 'Accounts'),
      const Tab(text: 'Metadata'),
      const Tab(text: 'Relays'),
      const Tab(text: nwcTabName),
      const Tab(text: "Blossom"),
      const Tab(text: 'Verifiers'),
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
      WidgetsDemoPage(onAccountChanged: _handleAccountChange),
      const PendingRequestsPage(),
    ];

    // Ensure TabController length matches dynamic _tabs list if it changed since initState
    // This can be tricky. If length changes, TabController might need re-initialization.
    // For this specific fix, the primary goal is updating metadata tab.
    // A common pattern is to initialize TabController with a fixed max length or update it.
    // If _tabController.length doesn't match _tabs.length here, it will error.
    // The TabController was initialized in initState with a potentially dynamic length.
    // It's safer if TabController's length is determined once or its recreation is handled.

    // Assuming TabController length is correctly managed based on amberAvailable from initState.
    // If not, _tabController = TabController(length: _tabs.length, vsync: this); would be needed here,
    // but that re-creates it on every build, losing tab state.
    // The current initState correctly sets the length based on amberAvailable.

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nostr Development Kit Demo'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabPages,
      ),
    );
  }
}

/// how to fetch metadata info
Widget metadata(Ndk ndk, BuildContext context) {
  // Added BuildContext for potential theme access
  final loggedInAccount = ndk.accounts.getLoggedAccount();
  final String? pubkey = loggedInAccount?.pubkey;

  if (pubkey == null) {
    return const Center(
        child: Padding(
      padding: EdgeInsets.all(16.0),
      child: Text('Please log in via the "Accounts" tab to view your metadata.',
          textAlign: TextAlign.center),
    ));
  }

  // The Future is created here. If pubkey changes, a new Future will be passed to FutureBuilder.
  final Future<Metadata?> response = ndk.metadata.loadMetadata(pubkey);

  return FutureBuilder<Metadata?>(
    future: response,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError) {
        return Center(
            child: Text('Error fetching metadata: ${snapshot.error}'));
      } else if (snapshot.hasData && snapshot.data != null) {
        final metadata = snapshot.data!;
        return SingleChildScrollView(
          // Added for scrollability if content is long
          padding: const EdgeInsets.all(16.0),
          child: Center(
            // Center the column content
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                if (metadata.picture != null && metadata.picture!.isNotEmpty)
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(metadata.picture!),
                    onBackgroundImageError: (exception, stackTrace) {
                      // This child will be shown if the image fails to load
                      print("Error loading avatar in metadata tab: $exception");
                      // Optionally, you could set a flag here and display a placeholder Icon instead
                    },
                    // Fallback child if backgroundImage is null or on error (though onBackgroundImageError is better for errors)
                    child: metadata.picture == null || metadata.picture!.isEmpty
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  )
                else
                  const CircleAvatar(
                    // Placeholder if no picture URL
                    radius: 50,
                    child: Icon(Icons.person, size: 50),
                  ),
                const SizedBox(height: 16),
                Text('Name: ${metadata.name ?? 'N/A'}',
                    style: Theme.of(context).textTheme.titleLarge),
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
                // Add more fields as desired
              ],
            ),
          ),
        );
      } else {
        // No data, but not an error and not waiting -> metadata not found for pubkey
        return Center(
            child: Text(
                'Metadata not found for this account. You might need to set it in a Nostr client.'));
      }
    },
  );
}
