import 'package:amberflutter/amberflutter.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_demo/accounts_page.dart';
import 'package:ndk_demo/blossom_page.dart';
import 'package:ndk_demo/nwc_page.dart';
import 'package:ndk_demo/relays_page.dart';
import 'package:ndk_demo/zaps_page.dart';
import 'package:protocol_handler/protocol_handler.dart';

import 'amber_page.dart';

bool amberAvailable = false;

final ndk = Ndk(
  NdkConfig(
    eventVerifier: Bip340EventVerifier(),
    cache: MemCacheManager(),
    logLevel: Logger.logLevels.trace,
  ),
);

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
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SafeArea(
          top: false,
          child: MyHomePage(key: _homePageKey)), // Pass the instance key
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

    // Define tabs and their corresponding pages
    // This centralizes the tab definitions.
    _tabs = <Tab>[
      const Tab(text: 'Accounts'),
      const Tab(text: 'Metadata'),
      const Tab(text: 'Relays'),
      const Tab(text: nwcTabName), // Use the constant
      // const Tab(text: 'Zaps'),
      const Tab(text: "Blossom"),
      // if (amberAvailable) const Tab(text: 'Amber'), // Conditionally add Amber tab
    ];

    _tabPages = <Widget>[
      const AccountsPage(),
      metadata(ndk, context), // Pass context, assuming metadata is a function
      const RelaysPage(),
      const NwcPage(),
      // const ZapsPage(),
      BlossomMediaPage(ndk: ndk),
      // if (amberAvailable) const AmberPage(), // Conditionally add Amber page
    ];

    // Ensure _tabs and _tabPages have the same length if conditional tabs are complex.
    // For now, assuming Amber is handled consistently or not included for simplicity of this refactor.
    // If Amber was included, the TabController length and lists would need to adjust.
    // Let's stick to the original 6 tabs for this refactor to match the problem description.

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nostr Development Kit Demo'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs, // Use the centralized list
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabPages, // Use the centralized list
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
