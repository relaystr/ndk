import 'package:ndk/domain_layer/entities/broadcast_state.dart';
import 'package:ndk/domain_layer/entities/global_state.dart';
import 'package:ndk/domain_layer/usecases/broadcast/broadcast_sender.dart';
import 'package:ndk/domain_layer/usecases/engines/network_engine.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

void main() {
  test('leaves no in-flight state behind when there is no signer', () async {
    final cache = MemCacheManager();
    final sender = BroadcastSender(
      globalState: GlobalState(),
      cacheManager: cache,
      networkEngine: _UnreachableNetworkEngine(),
      accounts: Accounts(const Bip340EventSignerFactory()),
      considerDonePercent: 1,
      timeout: const Duration(seconds: 1),
      saveToCache: true,
    );
    final unsigned = Nip01Event(
      pubKey: 'pubkey',
      kind: Nip01Event.kTextNodeKind,
      tags: const [],
      content: 'note',
    );

    expect(
      () => sender.broadcast(
        nostrEvent: unsigned,
        specificRelays: const ['wss://relay.example'],
      ),
      throwsA(anything),
    );
    expect(sender.isEventInFlight(unsigned.id), isFalse);
    expect(await cache.loadEvent(unsigned.id), isNull);
  });
}

class _UnreachableNetworkEngine implements NetworkEngine {
  @override
  void handleRequest(requestState) {
    throw UnimplementedError();
  }

  @override
  NdkBroadcastResponse handleEventBroadcast({
    required Nip01Event nostrEvent,
    required EventSigner? signer,
    required BroadcastState broadcastState,
    Iterable<String>? specificRelays,
  }) {
    throw UnimplementedError();
  }
}
