import 'dart:convert';

import 'package:amberflutter/amberflutter.dart';
import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip19/nip19.dart';

class AmberPage extends StatefulWidget {
  final Amberflutter amber;
  const AmberPage({super.key, required this.amber});

  @override
  State<AmberPage> createState() => _AmberPageState();
}

class _AmberPageState extends State<AmberPage> {
  String _npub = '';
  String _pubkeyHex = '';
  String _text = '';
  String _cipherText = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        FilledButton(
          onPressed: () async {
            widget.amber.getPublicKey(
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

            widget.amber
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

            var value = await widget.amber.signEvent(
              currentUser: _npub,
              eventJson: eventJson,
            );
            EventVerifier eventVerifier = RustEventVerifier();
            eventVerifier
                .verify(Nip01Event.fromJson(json.decode(value['event'])))
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
            widget.amber
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
            widget.amber
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
            widget.amber
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
            widget.amber
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
            widget.amber
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
            widget.amber
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
