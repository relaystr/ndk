import 'dart:async';

import 'package:ndk/data_layer/repositories/nostr_transport/websocket_nostr_transport_factory.dart';
import 'package:ndk/data_layer/repositories/signers/bip340_event_signer.dart';
import 'package:ndk/domain_layer/repositories/nostr_transport.dart';
import 'package:ndk/domain_layer/usecases/accounts/accounts.dart';
import 'package:ndk/domain_layer/usecases/relay_manager.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import '../mocks/mock_relay.dart';

/// A transport that loses its connection the way web_socket_client does: the
/// message stream stays open across the outage, so only onDisconnect fires.
class _FlakyTransport implements NostrTransport {
  _FlakyTransport(this._inner, {this.onDisconnect});

  final NostrTransport _inner;
  final Function(int?, Object?, String?)? onDisconnect;
  bool _down = false;

  void dropConnection() {
    _down = true;
    onDisconnect?.call(1006, null, "connection lost");
  }

  @override
  StreamSubscription listen(
    void Function(dynamic) onData, {
    Function? onError,
    void Function()? onDone,
  }) => _inner.listen(onData, onError: onError, onDone: onDone);

  @override
  Future<void> close() => _inner.close();

  @override
  Future<void> get ready => _inner.ready;

  @override
  set ready(Future<void> value) => _inner.ready = value;

  @override
  bool isOpen() => !_down && _inner.isOpen();

  @override
  bool isConnecting() => _down || _inner.isConnecting();

  @override
  void send(data) {
    if (_down) return;
    _inner.send(data);
  }

  @override
  int? closeCode() => _down ? 1006 : _inner.closeCode();

  @override
  String? closeReason() => _down ? "connection lost" : _inner.closeReason();
}

class _FlakyTransportFactory implements NostrTransportFactory {
  final _inner = WebSocketNostrTransportFactory();
  final List<_FlakyTransport> created = [];

  @override
  NostrTransport call(
    String url, {
    Function? onReconnect,
    Function(int?, Object?, String?)? onDisconnect,
  }) {
    final transport = _FlakyTransport(
      _inner(url, onReconnect: onReconnect, onDisconnect: onDisconnect),
      onDisconnect: onDisconnect,
    );
    created.add(transport);
    return transport;
  }
}

void main() {
  late KeyPair key;
  late Accounts accounts;

  setUp(() {
    key = Bip340.generatePrivateKey();
    accounts = Accounts(const Bip340EventSignerFactory());
    accounts.loginPrivateKey(pubkey: key.publicKey, privkey: key.privateKey!);
  });

  test('an authentication does not survive a transient disconnect', () async {
    final relay = MockRelay(
      name: "relay requiring auth",
      requireAuthForRequests: true,
      signEvents: false,
      challengePerConnection: true,
    );
    await relay.startServer();

    final factory = _FlakyTransportFactory();
    final manager = RelayManager(
      globalState: GlobalState(),
      bootstrapRelays: [],
      nostrTransportFactory: factory,
      accounts: accounts,
    );

    final account = accounts.getLoggedAccount()!;
    final connectivity = await manager.openConnectionAs(relay.url, account);
    expect(await manager.authenticateConnection(connectivity!.key), true);
    expect(relay.acceptedAuths, 1);

    factory.created.last.dropConnection();

    expect(manager.isConnectionOpen(connectivity.key), false);
    expect(
      await manager.authenticateConnection(connectivity.key),
      false,
      reason:
          'the connection is down, so it cannot still claim the AUTH the relay '
          'accepted on it',
    );

    await manager.closeAllTransports();
    await relay.stopServer();
  }, timeout: const Timeout(Duration(seconds: 60)));

  test('an in-flight AUTH fails with the socket it was sent on', () async {
    final relay = MockRelay(
      name: "relay going quiet mid auth",
      requireAuthForRequests: true,
      signEvents: false,
      challengePerConnection: true,
      silenceFirstAuths: 1,
    );
    await relay.startServer();

    final factory = _FlakyTransportFactory();
    final manager = RelayManager(
      globalState: GlobalState(),
      bootstrapRelays: [],
      nostrTransportFactory: factory,
      accounts: accounts,
      authCallbackTimeout: const Duration(seconds: 10),
    );

    final account = accounts.getLoggedAccount()!;
    final connectivity = await manager.openConnectionAs(relay.url, account);
    final authenticating = manager.authenticateConnection(connectivity!.key);

    while (relay.receivedAuths < 1) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    final elapsed = Stopwatch()..start();
    factory.created.last.dropConnection();
    expect(await authenticating, false);
    elapsed.stop();

    expect(
      elapsed.elapsed,
      lessThan(const Duration(seconds: 5)),
      reason:
          'the AUTH waited for its callback timeout instead of failing with '
          'the socket it was sent on',
    );

    await manager.closeAllTransports();
    await relay.stopServer();
  }, timeout: const Timeout(Duration(seconds: 60)));
}
