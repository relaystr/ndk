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
      // home: HomePage()
      home: const SafeArea(top: false, child: MyHomePage()),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  // Add TickerProviderStateMixin
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Create a TabController and add a listener.
    // The number of tabs should match the length of the 'tabs' list.
    // For simplicity, let's assume the number of tabs is fixed for now.
    // We'll define the tabs list length before initializing _tabController.
    // The actual tabs list is defined in build(), so we need to ensure length consistency.
    // Let's define the tabs list here or get its length.
    final List<Tab> staticTabs = [
      // Define tabs here to get length for TabController
      const Tab(text: 'Accounts'),
      const Tab(text: 'Metadata'),
      const Tab(text: 'Relays'),
      const Tab(text: 'NWC'),
      const Tab(text: 'Zaps'),
      const Tab(text: "Blossom")
    ];
    _tabController = TabController(length: staticTabs.length, vsync: this);
    _tabController.addListener(() {
      // When the tab changes, call setState to rebuild and refresh the metadata tab
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use the tabs list defined in initState for consistency or redefine here
    // but ensure the length matches _tabController.length.
    List<Tab> tabs = [
      const Tab(text: 'Accounts'),
      const Tab(text: 'Metadata'),
      // Tab(text: 'Amber'),
      const Tab(text: 'Relays'),
      const Tab(text: 'NWC'),
      const Tab(text: 'Zaps'),
      const Tab(text: "Blossom")
    ];
    List<Widget> tabPages = [
      const AccountsPage(),
      metadata(ndk, context), // Pass context
      // !amberAvailable
      //     ? const Center(child: Text("Amber not available"))
      //     : const AmberPage(),
      const RelaysPage(),
      const NwcPage(),
      const ZapsPage(),
      BlossomMediaPage(ndk: ndk),
    ];

    // Use the same tabs list for TabBar as used for TabController length
    final List<Tab> displayTabs = [
      const Tab(text: 'Accounts'),
      const Tab(text: 'Metadata'),
      const Tab(text: 'Relays'),
      const Tab(text: 'NWC'),
      const Tab(text: 'Zaps'),
      const Tab(text: "Blossom")
    ];

    return Scaffold(
      // No longer DefaultTabController, manage it manually
      appBar: AppBar(
        title: const Text('Nostr Development Kit Demo'),
        bottom: TabBar(
          controller: _tabController, // Use the manually created controller
          tabs: displayTabs,
        ),
      ),
      body: TabBarView(
        controller: _tabController, // Use the manually created controller
        children: tabPages,
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
