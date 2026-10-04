import 'dart:async';

import 'package:ndk/domain_layer/entities/connection_source.dart';
import 'package:ndk/domain_layer/entities/global_state.dart';
import 'package:ndk/domain_layer/entities/relay_connection_key.dart';
import 'package:ndk/domain_layer/entities/relay_connectivity.dart';
import 'package:ndk/domain_layer/entities/relay_info.dart';
import 'package:ndk/domain_layer/repositories/nostr_transport.dart';
import 'package:ndk/domain_layer/usecases/relay_manager.dart';
import 'package:test/test.dart';

class _Transport implements NostrTransport {
  bool open = true;
  bool closed = false;
  int closes = 0;
  Completer<void>? closeGate;
  final Function? reconnect;
  final Function(int?, Object?, String?)? disconnect;
  final controller = StreamController<dynamic>.broadcast();
  _Transport(this.reconnect, this.disconnect);
  @override
  Future<void> ready = Future.value();
  @override
  bool isOpen() => open && !closed;
  @override
  bool isConnecting() => false;
  @override
  Future<void> close() async {
    closes++;
    closed = true;
    await closeGate?.future;
  }

  void recover() {
    if (closed) return;
    open = true;
    reconnect?.call();
  }

  @override
  StreamSubscription listen(
    void Function(dynamic) onData, {
    Function? onError,
    Function()? onDone,
  }) => controller.stream.listen(onData, onError: onError, onDone: onDone);
  @override
  void send(dynamic data) {}
  @override
  int? closeCode() => null;
  @override
  String? closeReason() => null;
}

class _Factory implements NostrTransportFactory {
  final created = <_Transport>[];
  bool openNext = true;
  Completer<void>? readyGate;
  @override
  NostrTransport call(
    String url, {
    Function? onReconnect,
    Function(int?, Object?, String?)? onDisconnect,
  }) {
    if (created.isNotEmpty) {
      expect(
        created.last.closed,
        isTrue,
        reason: 'retire old reconnecting transport before replacement',
      );
    }
    final transport = _Transport(onReconnect, onDisconnect)..open = openNext;
    if (readyGate != null) transport.ready = readyGate!.future;
    created.add(transport);
    return transport;
  }
}

class _Manager extends RelayManager {
  int resubscriptions = 0;
  _Manager(GlobalState state, _Factory factory)
    : super(
        globalState: state,
        nostrTransportFactory: factory,
        bootstrapRelays: [],
      );
  @override
  Future<RelayInfo?> getRelayInfo(String url) async => null;
  @override
  void reSubscribeInFlightSubscriptions(RelayConnectivity relay) {
    resubscriptions++;
  }
}

void main() {
  const url = 'wss://relay.example';
  final key = RelayConnectionKey.anonymous(url);
  late GlobalState state;
  late _Factory factory;
  late _Manager manager;
  Future<bool> connect() async => (await manager.connectRelay(
    dirtyUrl: url,
    connectionSource: ConnectionSource.explicit,
    connectTimeout: 1,
  )).first;
  setUp(() {
    state = GlobalState();
    factory = _Factory();
    manager = _Manager(state, factory);
  });
  tearDown(() async {
    await manager.closeAllTransports();
    for (final transport in factory.created) {
      await transport.close();
      await transport.controller.close();
    }
  });

  test(
    'replacement retires old transport so recovery cannot orphan a socket',
    () async {
      expect(await connect(), isTrue);
      final old = factory.created.single;
      old.open = false;
      expect(await connect(), isTrue);
      old.recover();
      expect(factory.created.where((t) => t.isOpen()).length, 1);
      expect(state.relays.length, 1);
      await manager.closeAllTransports();
      old.recover();
      expect(factory.created.where((t) => t.isOpen()), isEmpty);
      expect(state.relays, isEmpty);
    },
  );

  test(
    'concurrent replacement waits for one old close and creates one transport',
    () async {
      await connect();
      final old = factory.created.single..open = false;
      old.closeGate = Completer<void>();
      final first = connect();
      final second = connect();
      await pumpEventQueue();
      expect(factory.created.length, 1);
      expect(old.closes, 1);
      old.closeGate!.complete();
      expect(await Future.wait([first, second]), [true, true]);
      expect(factory.created.length, 2);
    },
  );

  test(
    'removal during retirement never creates an untracked replacement',
    () async {
      await connect();
      final old = factory.created.single..open = false;
      old.closeGate = Completer<void>();
      final replacing = connect();
      await pumpEventQueue();
      await manager.closeConnection(key);
      old.closeGate!.complete();
      expect(await replacing, isFalse);
      expect(factory.created.length, 1);
      expect(state.relays, isEmpty);
    },
  );

  test(
    'callbacks from retired transport cannot mutate current ownership',
    () async {
      await connect();
      final old = factory.created.single..open = false;
      await connect();
      final current = state.relays[key]!;
      current.stats.openRequestIds.add('live-request');
      final errors = current.stats.connectionErrors;
      old.disconnect?.call(1006, null, 'late disconnect');
      old.reconnect?.call();
      expect(current.stats.openRequestIds, {'live-request'});
      expect(current.stats.connectionErrors, errors);
      expect(manager.resubscriptions, 0);
      await manager.closeAllTransports();
      old.reconnect?.call();
      expect(manager.resubscriptions, 0);
      expect(state.relays, isEmpty);
    },
  );

  test(
    'close during pending handshake prevents late connect success',
    () async {
      factory.openNext = false;
      factory.readyGate = Completer<void>();
      final connecting = connect();
      await pumpEventQueue();
      final transport = factory.created.single;
      await manager.closeAllTransports();
      transport.open = true;
      factory.readyGate!.complete();
      expect(await connecting.timeout(const Duration(seconds: 2)), isFalse);
      transport.reconnect?.call();
      expect(state.relays, isEmpty);
      expect(transport.closed, isTrue);
      expect(manager.resubscriptions, 0);
    },
  );
}
