import 'dart:convert';

import 'package:amberflutter/amberflutter.dart';
import 'package:dart_ndk/dart_ndk.dart';
import 'package:dart_ndk/nips/nip01/bip340_event_verifier.dart';
import 'package:dart_ndk/nips/nip01/event.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dart NDK DEMO',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final amber = Amberflutter();
  String _npub = '';
  String _pubkeyHex = '';
  String _text = '';
  int? verifyAcinqTime;
  int? verifyBip340Time;

  String _cipherText = '';
  int _counter = 0;
  DartNdk dartNdk = DartNdk();

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        title: Text('Dartk NDK Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FilledButton(
              onPressed: () {
                amber.getPublicKey().then((value) {
                  _npub = value ?? '';
//                  _pubkeyHex = Nip19.decodePubkey(_npub);
                  setState(() {
                    //                  _text = value ?? '';
                  });
                });
              },
              child: const Text('Get Public Key from Amber'),
            ),
            FilledButton(
              onPressed: () {
                final eventJson = jsonEncode({
                  'kind': 1,
                  'content': 'Hello from Amber Flutter!',
                  'created_at': DateTime.now().millisecondsSinceEpoch / 1000,
                });

                amber.signEvent(_npub, eventJson).then((value) {
                  setState(() {
                    _text = value ?? '';
                  });
                });
              },
              child: const Text('Sign Event'),
            ),
            FilledButton(
              onPressed: () async {
                final eventJson = jsonEncode({
                  'kind': 2,
                  'content': 'Hello from Amber Flutter!!!!!!!!',
                  'created_at': DateTime.now().millisecondsSinceEpoch / 1000,
                });
                amber.signEvent(_npub, eventJson).then((value) async {
                  var jsonObj2 = jsonDecode(value!);
                  final startTime = DateTime.now();
                  bool? validSig = await dartNdk.verifySignature(jsonObj2['sig'], jsonObj2['id'], jsonObj2['pubkey']);
                  final endTime = DateTime.now();
                  final duration = endTime.difference(startTime);
                  setState(() {
                    verifyAcinqTime = duration.inMilliseconds;
                    _text = '$_text -> ${validSig != null && validSig! ? "✅" : "❌"}';
                  });
                });
              },
              child: Text('Verify with fr.acinq.secp256k1 ${verifyAcinqTime??""}'),
            ),
            FilledButton(
              onPressed: () async {
                final eventJson = jsonEncode({
                  'kind': 2,
                  'content': 'Hello from Amber Flutter!!!!!!!!',
                  'created_at': DateTime.now().millisecondsSinceEpoch / 1000,
                });
                amber.signEvent(_npub, eventJson).then((value) async {
                  Bip340EventVerifier verifier = Bip340EventVerifier();
                  Nip01Event event = Nip01Event.fromJson(jsonDecode(value!));
                  final startTime = DateTime.now();
                  bool validSig = await verifier.verify(event);
                  final endTime = DateTime.now();
                  final duration = endTime.difference(startTime);
                  setState(() {
                    verifyBip340Time = duration.inMilliseconds;
                    _text = '$_text -> ${validSig != null && validSig! ? "✅" : "❌"}';
                  });
                });
              },
              child: Text('Verify with Bip340 ${verifyBip340Time??""}'),
            ),
            FilledButton(
              onPressed: () {
                amber
                    .nip04Encrypt(
                  "Hello from Amber Flutter, Nip 04!",
                  _npub,
                  _pubkeyHex,
                )
                    .then((value) {
                  _cipherText = value ?? '';
                  setState(() {
                    _text = value ?? '';
                  });
                });
              },
              child: const Text('Nip 04 Encrypt'),
            ),
            FilledButton(
              onPressed: () {
                amber
                    .nip04Decrypt(
                  _cipherText,
                  _npub,
                  _pubkeyHex,
                )
                    .then((value) {
                  setState(() {
                    _text = value ?? '';
                  });
                });
              },
              child: const Text('Nip 04 Decrypt'),
            ),
            FilledButton(
              onPressed: () {
                amber
                    .nip44Encrypt(
                  "Hello from Amber Flutter, Nip 44!",
                  _npub,
                  _pubkeyHex,
                )
                    .then((value) {
                  _cipherText = value ?? '';
                  setState(() {
                    _text = value ?? '';
                  });
                });
              },
              child: const Text('Nip 44 Encrypt'),
            ),
            FilledButton(
              onPressed: () {
                amber
                    .nip44Decrypt(
                  _cipherText,
                  _npub,
                  _pubkeyHex,
                )
                    .then((value) {
                  setState(() {
                    _text = value ?? '';
                  });
                });
              },
              child: const Text('Nip 44 Decrypt'),
            ),
            Text(_text),
          ],
        ),
      ),
    );
  }
}
