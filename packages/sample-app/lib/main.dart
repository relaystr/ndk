import 'package:amberflutter/amberflutter.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_demo/accounts_page.dart';
import 'package:ndk_demo/nwc_page.dart';
import 'package:ndk_demo/relays_page.dart';
import 'package:ndk_rust_verifier/ndk_rust_verifier.dart';

import 'amber_page.dart';
import 'blossom_page.dart';

bool amberAvailable = false;

final ndk = Ndk(
  NdkConfig(
    eventVerifier: RustEventVerifier(),
    cache: MemCacheManager(),
    logLevel: Logger.logLevels.trace,
  ),
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  try {
    final amber = Amberflutter();
    amberAvailable = await amber.isAppInstalled();
  } catch (e) {
    // not on android or amber not installed
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nostr Developer Kit Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SafeArea(child: const MyHomePage(), top: false),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nostr Development Kit Demo'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Accounts'),
              Tab(text: 'Metadata'),
              Tab(text: 'Amber'),
              Tab(text: 'Relays'),
              Tab(text: 'NWC'),
              // Tab(text: 'Zaps'),
              Tab(text: "Blossom")
            ],
          ),
        ),
        body: TabBarView(
          children: [
            AccountsPage(),
            metadata(ndk),
            !amberAvailable
                ? const Center(child: Text("Amber not available"))
                : const AmberPage(),
            const RelaysPage(),
            const NwcPage(),
            // const ZapsPage()
            BlossomMediaPage(ndk: ndk),
          ],
        ),
      ),
    );
  }
}

/// how to fetch metadata info
Widget metadata(Ndk ndk) {
  final Future<Metadata?> response = ndk.metadata.loadMetadata(
      '3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d');

  return FutureBuilder<Metadata?>(
    future: response,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Name: ${snapshot.data?.name ?? 'not found'}'),
            Text('nip05: ${snapshot.data?.nip05 ?? 'not found'}'),
            Text('Picture: ${snapshot.data?.picture ?? 'not found'}'),
            Text('About: ${snapshot.data?.about ?? 'not found'}'),
          ],
        );
      } else if (snapshot.hasError) {
        return Text('Error: ${snapshot.error}');
      } else {
        return const Center(child: CircularProgressIndicator());
      }
    },
  );
}
