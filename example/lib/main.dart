import 'dart:convert';

import 'package:amberflutter/amberflutter.dart';
import 'package:dart_ndk/dart_ndk.dart';
import 'package:dart_ndk/nips/nip01/acinq_event_verifier.dart';
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final amber = Amberflutter();
  AcinqSecp256k1EventVerifier acinqSecp256k1EventVerifier = AcinqSecp256k1EventVerifier();
  Bip340EventVerifier bip340eventVerifier = Bip340EventVerifier();

  String _npub = '';
  String _pubkeyHex = '';
  String _text = '';
  int? verifyAcinqTime;
  int? verifyBip340Time;

  String _cipherText = '';

  @override
  Widget build(BuildContext context) {
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
                  Nip01Event event = Nip01Event.fromJson(jsonDecode(value!));
                  final startTime = DateTime.now();
                  bool? validSig = await acinqSecp256k1EventVerifier.verify(event);
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
                  Nip01Event event = Nip01Event.fromJson(jsonDecode(value!));
                  final startTime = DateTime.now();
                  bool validSig = await bip340eventVerifier.verify(event);
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
