import 'dart:convert';

import 'package:amberflutter/amberflutter.dart';
import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip19/nip19.dart';
import 'package:ndk_rust_verifier/ndk_rust_verifier.dart';

class AmberPage extends StatefulWidget {
  const AmberPage({super.key});

  @override
  State<AmberPage> createState() => _AmberPageState();
}

class _AmberPageState extends State<AmberPage> {
  String _npub = '';
  String _pubkeyHex = '';
  String _text = '';
  String _cipherText = '';
  final amber = Amberflutter();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        FilledButton(
          onPressed: () async {
            amber.getPublicKey(
              permissions: [
                const Permission(
                  type: "nip04_encrypt",
                ),
                const Permission(
                  type: "nip04_decrypt",
                ),
              ],
            ).then((value) {
              _npub = value['signature'] ?? '';
              _pubkeyHex = Nip19.decode(_npub);
              setState(() {
                _text = '$value';
              });
            });
          },
          child: const Text('Get Public Key'),
        ),
        FilledButton(
          onPressed: () {
            final eventJson = jsonEncode({
              'id': '',
              'pubkey': Nip19.decode(_npub),
              'kind': 1,
              'content': 'Hello from Amber Flutter!',
              'created_at':
                  (DateTime.now().millisecondsSinceEpoch / 1000).round(),
              'tags': [],
              'sig': '',
            });

            amber
                .signEvent(
              currentUser: _npub,
              eventJson: eventJson,
            )
                .then((value) {
              setState(() {
                _text = '$value';
              });
            });
          },
          child: const Text('Sign Event'),
        ),
        FilledButton(
          onPressed: () async {
            final eventJson = jsonEncode({
              'id': '',
              'pubkey': Nip19.decode(_npub),
              'kind': 1,
              'content': 'Hello from Amber Flutter!',
              'created_at':
                  (DateTime.now().millisecondsSinceEpoch / 1000).round(),
              'tags': [],
              'sig': '',
            });

            var value = await amber.signEvent(
              currentUser: _npub,
              eventJson: eventJson,
            );
            EventVerifier eventVerifier = RustEventVerifier();
            eventVerifier
                .verify(Nip01EventModel.fromJson(json.decode(value['event'])))
                .then((valid) {
              setState(() {
                _text = valid ? "✅ Valid" : "❌ Invalid";
              });
            });
          },
          child: const Text('Verify signature'),
        ),
        FilledButton(
          onPressed: () {
            amber
                .nip04Encrypt(
              plaintext: "Hello from Amber Flutter, Nip 04!",
              currentUser: _npub,
              pubKey: _pubkeyHex,
            )
                .then((value) {
              _cipherText = value['signature'] ?? '';
              setState(() {
                _text = '$value';
              });
            });
          },
          child: const Text('Nip 04 Encrypt'),
        ),
        FilledButton(
          onPressed: () async {
            amber
                .nip04Decrypt(
              ciphertext: _cipherText,
              currentUser: _npub,
              pubKey: _pubkeyHex,
            )
                .then((value) {
              setState(() {
                _text = '$value 1';
              });
            });
            // ;
            amber
                .nip04Decrypt(
              ciphertext: _cipherText,
              currentUser: _npub,
              pubKey: _pubkeyHex,
            )
                .then((value) {
              setState(() {
                _text = '$value 2';
              });
            });
            //   ,
            amber
                .nip04Decrypt(
              ciphertext: _cipherText,
              currentUser: _npub,
              pubKey: _pubkeyHex,
            )
                .then((value) {
              setState(() {
                _text = '$value 3';
              });
            });
          },
          child: const Text('Nip 04 Decrypt'),
        ),
        FilledButton(
          onPressed: () {
            amber
                .nip44Encrypt(
              plaintext: "Hello from Amber Flutter, Nip 44!",
              currentUser: _npub,
              pubKey: _pubkeyHex,
            )
                .then((value) {
              _cipherText = value['signature'] ?? '';
              setState(() {
                _text = '$value';
              });
            });
          },
          child: const Text('Nip 44 Encrypt'),
        ),
        FilledButton(
          onPressed: () {
            amber
                .nip44Decrypt(
              ciphertext: _cipherText,
              currentUser: _npub,
              pubKey: _pubkeyHex,
            )
                .then((value) {
              setState(() {
                _text = '$value';
              });
            });
          },
          child: const Text('Nip 44 Decrypt'),
        ),
        Text(_text),
      ],
    );
  }
}
