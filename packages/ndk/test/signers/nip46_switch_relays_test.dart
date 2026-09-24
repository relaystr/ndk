import 'package:ndk/data_layer/repositories/signers/nip46_event_signer.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

import '../mocks/mock_relay.dart';

void main() {
  late MockRelay relayA;
  late MockRelay relayB;
  late Ndk ndk;
  late Nip46EventSigner signer;

  int bunkerRequestsOn(MockRelay relay) =>
      relay.receivedEvents.where((e) => e.kind == MockRelay.kNip46Kind).length;

  setUp(() async {
    relayA = MockRelay(name: 'nip46-switch-relay-a');
    relayB = MockRelay(name: 'nip46-switch-relay-b');
    await relayA.startServer();
    await relayB.startServer();

    ndk = Ndk(
      NdkConfig(
        cache: MemCacheManager(),
        eventVerifier: Bip340EventVerifier(),
        bootstrapRelays: [relayA.url, relayB.url],
      ),
    );
    await ndk.relays.seedRelaysConnected;

    signer = Nip46EventSigner(
      connection: BunkerConnection(
        privateKey:
            "7a8317f947fff0526749e9fe53f79def8eb0afd378c01058f37140cc8732fecc",
        remotePubkey: MockRelay.remoteSignerPublicKey,
        relays: [relayA.url],
      ),
      requests: ndk.requests,
      broadcast: ndk.broadcast,
      eventSignerFactory: Bip340EventSignerFactory(),
    );
  });

  tearDown(() async {
    await signer.dispose();
    await ndk.destroy();
    await relayA.stopServer();
    await relayB.stopServer();
  });

  test('switches to the relays sent by the remote signer', () async {
    relayA.switchRelaysResult = [relayB.url];

    final relays = await signer.switchRelays();

    expect(relays, equals([relayB.url]));
    expect(signer.connection.relays, equals([relayB.url]));

    final requestsOnA = bunkerRequestsOn(relayA);
    expect(await signer.ping(), equals('pong'));
    expect(bunkerRequestsOn(relayA), equals(requestsOnA));
    expect(bunkerRequestsOn(relayB), equals(1));
  });

  test('keeps the relays when the remote signer answers null', () async {
    expect(await signer.switchRelays(), isNull);
    expect(signer.connection.relays, equals([relayA.url]));
    expect(await signer.ping(), equals('pong'));
  });
}
