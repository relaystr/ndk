import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

class Nip55SignerPage extends StatefulWidget {
  const Nip55SignerPage({super.key});

  @override
  State<Nip55SignerPage> createState() => _Nip55SignerPageState();
}

class _Nip55SignerPageState extends State<Nip55SignerPage> {
  String _npub = '';
  String _pubkeyHex = '';
  String _text = '';
  String _cipherText = '';
  final nip55Signer = const Nip55Signer();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        FilledButton(
          onPressed: () async {
            nip55Signer.getPublicKey(
              permissions: [
                const Nip55Permission(
                  type: "nip04_encrypt",
                ),
                const Nip55Permission(
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
              'content': 'Hello from NDK Flutter!',
              'created_at':
                  (DateTime.now().millisecondsSinceEpoch / 1000).round(),
              'tags': [],
              'sig': '',
            });

            nip55Signer
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
              'content': 'Hello from NDK Flutter!',
              'created_at':
                  (DateTime.now().millisecondsSinceEpoch / 1000).round(),
              'tags': [],
              'sig': '',
            });

            var value = await nip55Signer.signEvent(
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
            nip55Signer
                .nip04Encrypt(
              plaintext: "Hello from NDK Flutter, Nip 04!",
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
            nip55Signer
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
            nip55Signer
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
            nip55Signer
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
            nip55Signer
                .nip44Encrypt(
              plaintext: "Hello from NDK Flutter, Nip 44!",
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
            nip55Signer
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
