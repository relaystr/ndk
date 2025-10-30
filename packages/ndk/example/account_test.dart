// ignore_for_file: avoid_print

import 'package:ndk/config/bootstrap_relays.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';
import 'package:ndk/ndk.dart';

void main() async {
  test(
    'account',
    () async {
      // Create an instance of Ndk
      // It's recommended to keep this instance global as it holds critical application state
      final ndk = Ndk.defaultConfig();

      // generate a new key
      KeyPair key1 = Bip340.generatePrivateKey();

      // login using private key
      ndk.accounts
          .loginPrivateKey(privkey: key1.privateKey!, pubkey: key1.publicKey);

      // broadcast a new event using the logged in account with it's signer to sign
      NdkBroadcastResponse response = ndk.broadcast.broadcast(
          nostrEvent: Nip01Event(
              pubKey: key1.publicKey,
              kind: Nip01Event.kTextNodeKind,
              tags: [],
              content: "test"),
          specificRelays: DEFAULT_BOOTSTRAP_RELAYS);
      await response.broadcastDoneFuture;

      // logout
      ndk.accounts.logout();

      // destroy ndk instance
      ndk.destroy();
    },
    skip: true,
  );
}
