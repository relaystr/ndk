// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:typed_data';

import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';
import 'package:ndk/ndk.dart';

void main() async {
  test('account', () async {
    // Create an instance of Ndk
    // It's recommended to keep this instance global as it holds critical application state
    final ndk = Ndk(
      // Configure the Ndk instance using NdkConfig
      NdkConfig(
        // Use Bip340EventVerifier for event verification
        // in production RustEventVerifier() is recommended
        eventVerifier: Bip340EventVerifier(),

        // Use in-memory cache for storing Nostr data
        cache: MemCacheManager(),
      ),
    );
    // KeyPair key2ReadOnly = Bip340.generatePrivateKey();
    // ndk.accounts.loginPublicKey(pubkey: key2ReadOnly.publicKey);


    KeyPair key1 = Bip340.generatePrivateKey();
    ndk.accounts.loginPrivateKey(privkey: key1.privateKey!, pubkey: key1.publicKey);

    Nip01Event event = Nip01Event(pubKey: key1.publicKey, kind: Nip01Event.kTextNodeKind, tags: [], content: "test");
    await ndk.accounts.sign(event);

    ndk.accounts.logout();

    ndk.destroy();
  });
}
