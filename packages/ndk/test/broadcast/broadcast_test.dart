import 'package:test/test.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';

void main() {
  test(
    'broadcast should complete quickly even with one offline relay',
    () async {
      final ndk = Ndk(
        NdkConfig(
          eventVerifier: Bip340EventVerifier(),
          cache: MemCacheManager(),
          bootstrapRelays: ["ws://localhost:25565"],
        ),
      );
      
      addTearDown(() async => ndk.destroy());

      final keyPair = Bip340.generatePrivateKey();
      ndk.accounts.loginPrivateKey(
        privkey: keyPair.privateKey!,
        pubkey: keyPair.publicKey,
      );

      final event = Nip01Event(
        pubKey: keyPair.publicKey,
        kind: 1,
        content: '',
        tags: [],
      );

      final stopwatch = Stopwatch()..start();

      final broadcast = ndk.broadcast.broadcast(nostrEvent: event);
      await broadcast.broadcastDoneFuture;

      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(5000),
      );
    },
  );

  test(
    'broadcast to 0 relay should not time out',
    () async {
      final ndk = Ndk.emptyBootstrapRelaysConfig();
      addTearDown(() async => ndk.destroy());

      final keyPair = Bip340.generatePrivateKey();
      ndk.accounts.loginPrivateKey(
        privkey: keyPair.privateKey!,
        pubkey: keyPair.publicKey,
      );

      final event = Nip01Event(
        pubKey: keyPair.publicKey,
        kind: 1,
        content: '',
        tags: [],
      );

      final stopwatch = Stopwatch()..start();

      final broadcast = ndk.broadcast.broadcast(
        nostrEvent: event,
        specificRelays: [],
      );
      await broadcast.broadcastDoneFuture;

      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(5000),
      );
    },
  );
}
