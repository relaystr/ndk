import 'dart:async';

import 'package:test/test.dart';
import 'package:ndk/domain_layer/entities/account.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart';
import 'package:ndk/domain_layer/entities/connection_source.dart';
import 'package:ndk/domain_layer/entities/filter.dart';
import 'package:ndk/domain_layer/entities/global_state.dart';
import 'package:ndk/domain_layer/entities/ndk_request.dart';
import 'package:ndk/domain_layer/entities/nip77_state.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/domain_layer/entities/relay.dart';
import 'package:ndk/domain_layer/entities/relay_connection_key.dart';
import 'package:ndk/domain_layer/entities/relay_connectivity.dart';
import 'package:ndk/domain_layer/entities/request_state.dart';
import 'package:ndk/domain_layer/repositories/event_signer.dart';
import 'package:ndk/domain_layer/repositories/nostr_transport.dart';
import 'package:ndk/domain_layer/usecases/relay_manager.dart';

class _Transport implements NostrTransport {
  bool closed = false;
  bool connecting = false;
  void Function()? onClose;
  final controller = StreamController<dynamic>();

  @override
  Future<void> ready = Future.value();
  @override
  bool isOpen() => !closed;
  @override
  bool isConnecting() => connecting;
  @override
  Future<void> close() async {
    closed = true;
    onClose?.call();
  }

  @override
  void send(dynamic data) {}
  @override
  StreamSubscription<dynamic> listen(
    void Function(dynamic) onData, {
    Function? onError,
    void Function()? onDone,
  }) =>
      controller.stream.listen(onData, onError: onError, onDone: onDone);
  @override
  int? closeCode() => null;
  @override
  String? closeReason() => null;
}

class _NoConnections implements NostrTransportFactory {
  @override
  NostrTransport call(
    String url, {
    Function? onReconnect,
    Function(int?, Object?, String?)? onDisconnect,
  }) =>
      throw StateError('Tests must not open network connections');
}

class _Signer implements EventSigner {
  @override
  bool canSign() => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late GlobalState state;
  late RelayManager manager;
  final requests = <RequestState>[];
  final broadcasts = <BroadcastState>[];
  final anonymous = RelayConnectionKey.anonymous('wss://relay.example');
  final authenticated = RelayConnectionKey.authenticated(
    'wss://relay.example',
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  );
  final other = RelayConnectionKey.anonymous('wss://other.example');

  _Transport connect(RelayConnectionKey key) {
    final transport = _Transport();
    state.relays[key] = RelayConnectivity(
      key: key,
      relay: Relay(url: key.url, connectionSource: ConnectionSource.explicit),
      relayTransport: transport,
    );
    return transport;
  }

  RequestState request(
    String id, {
    RelayConnectionKey? key,
    bool query = false,
  }) {
    final filters = [
      Filter(kinds: [1]),
    ];
    final request = RequestState(
      query
          ? NdkRequest.query(id, filters: filters, timeoutDuration: null)
          : NdkRequest.subscription(id, filters: filters),
    );
    request.networkController.stream.listen((_) {});
    request.cacheController.stream.listen((_) {});
    if (key != null) request.registerRequest(key, filters);
    state.inFlightRequests[id] = request;
    requests.add(request);
    return request;
  }

  BroadcastState broadcast(String id, {String? url}) {
    final broadcast = BroadcastState(timeout: const Duration(minutes: 1));
    state.inFlightBroadcasts[id] = broadcast;
    broadcasts.add(broadcast);
    if (url != null) {
      manager.registerRelayBroadcast(
        relayUrl: url,
        eventToPublish: Nip01Event(
          id: id,
          pubKey:
              'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          kind: 1,
          tags: [],
          content: '',
        ),
      );
    }
    return broadcast;
  }

  setUp(() {
    state = GlobalState();
    manager = RelayManager(
      globalState: state,
      nostrTransportFactory: _NoConnections(),
      bootstrapRelays: [],
    );
  });

  tearDown(() async {
    for (final request in requests) {
      await request.close();
    }
    requests.clear();
    for (final broadcast in broadcasts) {
      if (broadcast.broadcasts.isEmpty) {
        broadcast.closeIfNoRelays();
      } else if (!broadcast.networkController.isClosed) {
        for (final url in broadcast.broadcasts.keys.toList()) {
          broadcast.networkController.add(
            RelayBroadcastResponse(
              relayUrl: url,
              okReceived: true,
              broadcastSuccessful: true,
            ),
          );
        }
      }
      await broadcast.publishDoneFuture;
    }
    broadcasts.clear();
    for (final negotiation in state.inFlightNegotiations.values) {
      negotiation.close();
    }
    await manager.closeAllTransports();
  });

  test('idle anonymous and authenticated transports are removed', () async {
    final anonTransport = connect(anonymous);
    final authTransport = connect(authenticated);
    await manager.closeIdleConnections();
    expect(state.relays, isEmpty);
    expect(anonTransport.closed, isTrue);
    expect(authTransport.closed, isTrue);
  });

  test('live subscription retains exact key after EOSE', () async {
    final anonTransport = connect(anonymous);
    final authTransport = connect(authenticated);
    final subscription = request('subscription', key: authenticated);
    subscription.requests[authenticated]!.receivedEOSE = true;
    await manager.closeIdleConnections();
    expect(anonTransport.closed, isTrue);
    expect(authTransport.closed, isFalse);
    expect(state.relays.keys, [authenticated]);
  });

  test('both identities stay when separate subscriptions own them', () async {
    connect(anonymous);
    connect(authenticated);
    request('anonymous', key: anonymous);
    request('authenticated', key: authenticated);
    await manager.closeIdleConnections();
    expect(state.relays.keys, unorderedEquals([anonymous, authenticated]));
  });

  test(
    'closed request frees connection but auth retry keeps its key',
    () async {
      final anonTransport = connect(anonymous);
      final authTransport = connect(authenticated);
      final subscription = request('subscription', key: anonymous);
      subscription.requests[anonymous]!.markClosed('auth-required');
      subscription.registerRequest(authenticated, [
        Filter(kinds: [1]),
      ]);
      subscription.requests[authenticated]!.markClosed('auth-required');
      subscription.requests[authenticated]!.retryingAuth = true;
      await manager.closeIdleConnections();
      expect(anonTransport.closed, isTrue);
      expect(authTransport.closed, isFalse);
    },
  );

  test('unfinished query stays; EOSE query frees its connection', () async {
    connect(anonymous);
    connect(authenticated);
    request('pending-query', key: anonymous, query: true);
    final done = request('done-query', key: authenticated, query: true);
    done.requests[authenticated]!.receivedEOSE = true;
    await manager.closeIdleConnections();
    expect(state.relays.keys, [anonymous]);
  });

  test(
    'broadcast conservatively keeps both identities at target URL',
    () async {
      connect(anonymous);
      connect(authenticated);
      final unrelated = connect(other);
      broadcast('event', url: anonymous.url);
      await manager.closeIdleConnections();
      expect(state.relays.keys, unorderedEquals([anonymous, authenticated]));
      expect(unrelated.closed, isTrue);
    },
  );

  test(
    'unassigned request discovery defers pruning until keys are known',
    () async {
      connect(anonymous);
      final idle = connect(other);
      final pending = request('discovering');
      await manager.closeIdleConnections();
      expect(idle.closed, isFalse);
      pending.registerRequest(anonymous, [
        Filter(kinds: [1]),
      ]);
      await manager.closeIdleConnections();
      expect(idle.closed, isTrue);
      expect(state.relays.keys, [anonymous]);
    },
  );

  test(
    'pending connection selection defers pruning even with other known keys',
    () async {
      connect(anonymous);
      final idle = connect(other);
      final pending = request('selecting', key: anonymous);
      pending.pendingConnections = 1;
      await manager.closeIdleConnections();
      expect(idle.closed, isFalse);
      pending.pendingConnections = 0;
      await manager.closeIdleConnections();
      expect(idle.closed, isTrue);
    },
  );

  test('unassigned broadcast discovery defers pruning', () async {
    connect(anonymous);
    final idle = connect(other);
    final pending = broadcast('discovering');
    await manager.closeIdleConnections();
    expect(idle.closed, isFalse);
    pending.broadcasts[anonymous.url] = RelayBroadcastResponse(
      relayUrl: anonymous.url,
    );
    await manager.closeIdleConnections();
    expect(idle.closed, isTrue);
  });

  test('ongoing transport and relay connection setup are retained', () async {
    connect(anonymous).connecting = true;
    connect(authenticated);
    state.relays[authenticated]!.relay.connecting = true;
    await manager.closeIdleConnections();
    expect(state.relays.keys, unorderedEquals([anonymous, authenticated]));
  });

  test(
    'authentication waiting for challenge keeps its bound connection',
    () async {
      connect(anonymous);
      connect(authenticated);
      await manager.openConnectionAs(
        anonymous.url,
        Account(
          type: AccountType.privateKey,
          pubkey:
              'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          signer: _Signer(),
        ),
      );
      final attempt = manager.authenticateConnection(authenticated);
      await manager.closeIdleConnections();
      expect(state.relays.keys, [authenticated]);
      await manager.closeConnection(authenticated);
      expect(await attempt, isFalse);
    },
  );

  test('NIP77 negotiation keeps only its current connection', () async {
    connect(anonymous);
    connect(authenticated);
    state.inFlightNegotiations['negotiation'] = Nip77State(
      subscriptionId: 'negotiation',
      connectionKey: authenticated,
      filter: Filter(kinds: [1]),
      localItems: [],
    );
    await manager.closeIdleConnections();
    expect(state.relays.keys, [authenticated]);
  });

  test('ownership is rechecked after each asynchronous close', () async {
    final first = connect(anonymous);
    connect(other);
    first.onClose = () => request('new-owner', key: other);
    await manager.closeIdleConnections();
    expect(state.relays.keys, [other]);
  });
}
