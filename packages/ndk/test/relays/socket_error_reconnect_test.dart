import 'dart:async';

import 'package:ndk/data_layer/repositories/nostr_transport/websocket_nostr_transport_factory.dart';
import 'package:ndk/data_layer/repositories/signers/bip340_event_signer.dart';
import 'package:ndk/domain_layer/repositories/nostr_transport.dart';
import 'package:ndk/domain_layer/usecases/accounts/accounts.dart';
import 'package:ndk/domain_layer/usecases/relay_manager.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import '../mocks/mock_relay.dart';

Future<void> _waitUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 15),
  String reason = 'condition never became true',
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (condition()) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  fail(reason);
}

/// A real transport whose stream can be made to end with an error, the way a
/// socket that breaks instead of closing cleanly does.
class _FaultyTransport implements NostrTransport {
  _FaultyTransport(this._inner);

  final NostrTransport _inner;
  final StreamController _out = StreamController();
  StreamSubscription? _innerSubscription;

  void breakStream() => _out.addError(StateError("socket blew up"));

  @override
  StreamSubscription listen(
    void Function(dynamic) onData, {
    Function? onError,
    void Function()? onDone,
  }) {
    _innerSubscription = _inner.listen(
      _out.add,
      onError: _out.addError,
      onDone: _out.close,
    );
    return _out.stream.listen(onData, onError: onError, onDone: onDone);
  }

  @override
  Future<void> close() async {
    await _innerSubscription?.cancel();
    _innerSubscription = null;
    if (!_out.isClosed) {
      await _out.close();
    }
    await _inner.close();
  }

  @override
  Future<void> get ready => _inner.ready;

  @override
  set ready(Future<void> value) => _inner.ready = value;

  @override
  bool isOpen() => _inner.isOpen();

  @override
  bool isConnecting() => _inner.isConnecting();

  @override
  void send(data) => _inner.send(data);

  @override
  int? closeCode() => _inner.closeCode();

  @override
  String? closeReason() => _inner.closeReason();
}

class _FaultyTransportFactory implements NostrTransportFactory {
  final _inner = WebSocketNostrTransportFactory();
  final List<_FaultyTransport> created = [];

  @override
  NostrTransport call(
    String url, {
    Function? onReconnect,
    Function(int?, Object?, String?)? onDisconnect,
  }) {
    final transport = _FaultyTransport(
      _inner(url, onReconnect: onReconnect, onDisconnect: onDisconnect),
    );
    created.add(transport);
    return transport;
  }
}

void main() {
  test('a socket that ends with an error reconnects', () async {
    final relay = MockRelay(name: "relay 1");
    await relay.startServer();

    final factory = _FaultyTransportFactory();
    final manager = RelayManager(
      globalState: GlobalState(),
      bootstrapRelays: [relay.url],
      nostrTransportFactory: factory,
    );
    await manager.connectRelay(
      dirtyUrl: relay.url,
      connectionSource: ConnectionSource.seed,
    );

    final connectivity =
        manager.globalState.relays[RelayConnectionKey.anonymous(relay.url)]!;
    expect(connectivity.stats.connections, 1);

    // otherwise FAIL_RELAY_CONNECT_TRY_AFTER_SECONDS suppresses the reconnect
    connectivity.relay.lastConnectTry = 0;

    factory.created.last.breakStream();

    await _waitUntil(
      () => connectivity.stats.connections >= 2,
      reason:
          'a socket that ended with an error must be reconnected, like one '
          'that closed cleanly',
    );

    await manager.closeAllTransports();
    await relay.stopServer();
  }, timeout: const Timeout(Duration(seconds: 60)));

  test(
    'an authentication does not survive a socket that ended with an error',
    () async {
      final key = Bip340.generatePrivateKey();
      final accounts = Accounts(const Bip340EventSignerFactory());
      accounts.loginPrivateKey(pubkey: key.publicKey, privkey: key.privateKey!);

      final relay = MockRelay(
        name: "relay requiring auth",
        requireAuthForRequests: true,
        signEvents: false,
        challengePerConnection: true,
      );
      await relay.startServer();

      final factory = _FaultyTransportFactory();
      final manager = RelayManager(
        globalState: GlobalState(),
        bootstrapRelays: [],
        nostrTransportFactory: factory,
        accounts: accounts,
      );

      final account = accounts.getLoggedAccount()!;
      final connectivity = await manager.openConnectionAs(relay.url, account);
      expect(connectivity, isNotNull);
      expect(await manager.authenticateConnection(connectivity!.key), true);
      expect(relay.acceptedAuths, 1);

      connectivity.relay.lastConnectTry = 0;
      factory.created.last.breakStream();

      await _waitUntil(
        () => relay.acceptedAuths == 2,
        reason:
            'the replacement socket never answered its own challenge: the '
            'AUTH the relay accepted on the socket that broke was kept',
      );
      expect(relay.connectionsAuthenticatedAs(key.publicKey), 1);

      await manager.closeAllTransports();
      await relay.stopServer();
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
