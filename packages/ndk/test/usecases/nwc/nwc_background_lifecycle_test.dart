import 'dart:async';
import 'dart:convert';

import 'package:ndk/ndk.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip04/nip04.dart';
import 'package:test/test.dart';

const _walletSecret =
    '0000000000000000000000000000000000000000000000000000000000000001';
const _clientSecret =
    '0000000000000000000000000000000000000000000000000000000000000002';
final _walletPubkey = Bip340.getPublicKey(_walletSecret);
final _uri =
    'nostr+walletconnect://$_walletPubkey?relay=wss://wallet.example&secret=$_clientSecret';

class _Requests implements Requests {
  final active = <String, (List<Filter>, StreamController<Nip01Event>)>{};
  int opened = 0;
  bool failSubscription = false;
  bool failClose = false;
  Completer<void>? queryGate;

  @override
  dynamic noSuchMethod(Invocation call) {
    if (call.memberName == #query) {
      return NdkResponse(
        'info',
        (() async* {
          await queryGate?.future;
          yield Nip01Event(
            pubKey: _walletPubkey,
            kind: 13194,
            tags: [],
            content: 'get_info get_balance pay_invoice',
          );
        })(),
      );
    }
    if (call.memberName == #subscription) {
      if (failSubscription) throw StateError('subscription failed');
      final filters = call.namedArguments[#filters] as List<Filter>;
      final id = 'nwc-${opened++}';
      final controller = StreamController<Nip01Event>();
      active[id] = (filters, controller);
      return NdkResponse(id, controller.stream);
    }
    return super.noSuchMethod(call);
  }

  @override
  Future<void> closeSubscription(String id, {String debugLabel = ''}) async {
    await active.remove(id)?.$2.close();
    if (failClose) throw StateError('cleanup failed');
  }

  void deliver(Nip01Event event) {
    for (final entry in active.values.toList()) {
      // Deliberately do not enforce `since`: listener must reject history too.
      if (entry.$1.any(
        (f) =>
            f.kinds!.contains(event.kind) &&
            (f.eTags == null || f.eTags!.contains(event.getEId())),
      )) {
        entry.$2.add(event);
      }
    }
  }
}

class _Broadcast implements Broadcast {
  final _Requests requests;
  final sent = <Nip01Event>[];
  bool fail = false;
  bool autoReply = true;
  Completer<void>? ackGate;
  _Broadcast(this.requests);

  @override
  dynamic noSuchMethod(Invocation call) {
    if (call.memberName == #broadcast) {
      final event = call.namedArguments[#nostrEvent] as Nip01Event;
      expect(
        requests.active.values.any(
          (entry) => entry.$1.any((f) => f.kinds!.contains(23195)),
        ),
        isTrue,
        reason: 'response subscription must exist before publication',
      );
      sent.add(event);
      if (fail) throw StateError('broadcast failed');
      if (autoReply) reply(event);
      return NdkBroadcastResponse(
        publishEvent: event,
        broadcastDoneStream: const Stream.empty(),
        broadcastDoneFuture: (() async {
          await ackGate?.future;
          return <RelayBroadcastResponse>[];
        })(),
      );
    }
    return super.noSuchMethod(call);
  }

  void reply(Nip01Event event) {
    final request =
        jsonDecode(
              Nip04.decrypt(
                _walletSecret,
                Bip340.getPublicKey(_clientSecret),
                event.content,
              ),
            )
            as Map;
    final method = request['method'];
    final result = switch (method) {
      'get_balance' => {'balance': 12000},
      'pay_invoice' => {'preimage': 'preimage'},
      _ => {
        'methods': ['get_info', 'get_balance', 'pay_invoice'],
        'notifications': [],
        'alias': 'Test',
        'color': '',
        'pubkey': _walletPubkey,
        'network': 'regtest',
        'block_height': 0,
        'block_hash': '',
      },
    };
    requests.deliver(
      Nip01Event(
        pubKey: _walletPubkey,
        kind: 23195,
        tags: [
          ['e', event.id],
        ],
        content: Nip04.encrypt(
          _walletSecret,
          Bip340.getPublicKey(_clientSecret),
          jsonEncode({'result_type': method, 'result': result}),
        ),
      ),
    );
  }
}

Future<void> _flush() => pumpEventQueue(times: 30);

void main() {
  late _Requests requests;
  late _Broadcast broadcast;
  late Nwc nwc;
  late int idleCalls;
  setUp(() {
    requests = _Requests();
    broadcast = _Broadcast(requests);
    idleCalls = 0;
    nwc = Nwc(
      requests: requests,
      broadcast: broadcast,
      eventSignerFactory: Bip340EventSignerFactory(),
      onIdle: () async {
        idleCalls++;
      },
    );
  });
  tearDown(() async => nwc.disconnectAll());

  test(
    'idle suspension preserves streams and resumes one fresh listener',
    () async {
      final connection = await nwc.connect(_uri);
      var streamClosed = false;
      final listener = connection.notificationStream.stream.listen(
        (_) {},
        onDone: () => streamClosed = true,
      );
      await nwc.setBackgrounded(true);
      expect(requests.active, isEmpty);
      expect(streamClosed, isFalse);
      expect(idleCalls, 1);
      await nwc.setBackgrounded(false);
      await nwc.setBackgrounded(false);
      expect(requests.active.length, 1);
      final filters = requests.active.values.single.$1;
      expect(filters.first.since, isNotNull);
      expect(
        filters.last.since,
        isNull,
        reason: 'wallet clock skew must not filter RPC replies',
      );
      await listener.cancel();
    },
  );

  test(
    'background RPC reopens then closes only its own subscription',
    () async {
      final connection = await nwc.connect(_uri);
      await nwc.setBackgrounded(true);
      final unrelated = requests.subscription(
        filters: [
          Filter(kinds: [1]),
        ],
      );
      final unrelatedListener = unrelated.stream.listen((_) {});
      expect((await nwc.getBalance(connection)).balanceSats, 12);
      expect(requests.active.keys, [unrelated.requestId]);
      await unrelatedListener.cancel();
      await requests.closeSubscription(unrelated.requestId);
    },
  );

  test(
    'in-flight payment survives background and closes after response',
    () async {
      final connection = await nwc.connect(_uri);
      broadcast.autoReply = false;
      final payment = nwc.payInvoice(connection, invoice: 'lnbc-test');
      await _flush();
      await nwc.setBackgrounded(true);
      expect(requests.active.length, 1);
      broadcast.reply(broadcast.sent.single);
      expect((await payment).preimage, 'preimage');
      expect(requests.active, isEmpty);
    },
  );

  test('concurrent requests retain listener until last reply', () async {
    final connection = await nwc.connect(_uri);
    await nwc.setBackgrounded(true);
    broadcast.autoReply = false;
    final first = nwc.getBalance(connection);
    final second = nwc.payInvoice(connection, invoice: 'lnbc-test');
    await _flush();
    broadcast.reply(
      broadcast.sent.firstWhere(
        (event) =>
            (jsonDecode(
                  Nip04.decrypt(
                    _walletSecret,
                    Bip340.getPublicKey(_clientSecret),
                    event.content,
                  ),
                )
                as Map)['method'] ==
            'get_balance',
      ),
    );
    await first;
    expect(requests.active.length, 1);
    broadcast.reply(
      broadcast.sent.firstWhere(
        (event) =>
            (jsonDecode(
                  Nip04.decrypt(
                    _walletSecret,
                    Bip340.getPublicKey(_clientSecret),
                    event.content,
                  ),
                )
                as Map)['method'] ==
            'pay_invoice',
      ),
    );
    await second;
    expect(requests.active, isEmpty);
  });

  test('broadcast failure and timeout release request ownership', () async {
    final connection = await nwc.connect(_uri);
    await nwc.setBackgrounded(true);
    broadcast.fail = true;
    await expectLater(nwc.getBalance(connection), throwsStateError);
    expect(requests.active, isEmpty);
    broadcast.fail = false;
    broadcast.autoReply = false;
    await expectLater(
      nwc.getBalance(connection, timeout: const Duration(milliseconds: 10)),
      throwsA(isA<String>()),
    );
    expect(requests.active, isEmpty);
    broadcast.autoReply = true;
    expect((await nwc.getBalance(connection)).balanceSats, 12);
    expect(requests.active, isEmpty);
  });

  test(
    'subscription failure releases pin and later requests recover',
    () async {
      final connection = await nwc.connect(_uri);
      await nwc.setBackgrounded(true);
      requests.failSubscription = true;
      await expectLater(nwc.getBalance(connection), throwsStateError);
      requests.failSubscription = false;
      expect((await nwc.getBalance(connection)).balanceSats, 12);
      expect(requests.active, isEmpty);
    },
  );

  test(
    'background during connection initialization keeps get_info reliable',
    () async {
      requests.queryGate = Completer<void>();
      final connectionFuture = nwc.connect(
        _uri,
        doGetInfoMethod: true,
        requireGetInfoResponse: true,
      );
      await nwc.setBackgrounded(true);
      requests.queryGate!.complete();
      final connection = await connectionFuture;
      expect(connection.info, isNotNull);
      expect(requests.active, isEmpty);
      await nwc.setBackgrounded(false);
      expect(requests.active.values.single.$1.first.since, isNotNull);
    },
  );

  test(
    'tagged request remains live when notification listener closes',
    () async {
      final connection = await nwc.connect(_uri, useETagForEachRequest: true);
      broadcast.autoReply = false;
      final payment = nwc.payInvoice(connection, invoice: 'lnbc-test');
      await _flush();
      expect(requests.active.length, 2);
      await nwc.setBackgrounded(true);
      expect(requests.active.length, 1);
      broadcast.reply(broadcast.sent.single);
      await payment;
      expect(requests.active, isEmpty);
    },
  );

  test(
    'tagged background RPC releases socket after dedicated listener closes',
    () async {
      final connection = await nwc.connect(_uri, useETagForEachRequest: true);
      await nwc.setBackgrounded(true);
      final before = idleCalls;
      await nwc.getBalance(connection);
      expect(requests.active, isEmpty);
      expect(idleCalls, greaterThan(before));
    },
  );

  test('cleanup failure does not replace successful payment', () async {
    final connection = await nwc.connect(_uri, useETagForEachRequest: true);
    await nwc.setBackgrounded(true);
    requests.failClose = true;
    expect(
      (await nwc.payInvoice(connection, invoice: 'lnbc-test')).preimage,
      'preimage',
    );
    requests.failClose = false;
  });

  test('cold request waits until its exact subscription is sent', () async {
    var ready = false;
    final checkedIds = <String>[];
    nwc = Nwc(
      requests: requests,
      broadcast: broadcast,
      eventSignerFactory: Bip340EventSignerFactory(),
      isSubscriptionReady: (id) {
        checkedIds.add(id);
        return ready;
      },
    );
    final connection = await nwc.connect(_uri);
    await nwc.setBackgrounded(true);
    final payment = nwc.payInvoice(connection, invoice: 'lnbc-test');
    await _flush();
    expect(broadcast.sent, isEmpty);
    expect(checkedIds, isNotEmpty);
    expect(checkedIds.toSet(), {requests.active.keys.single});
    ready = true;
    expect((await payment).preimage, 'preimage');
    expect(requests.active, isEmpty);
  });

  test('subscription readiness timeout releases idle connection', () async {
    nwc = Nwc(
      requests: requests,
      broadcast: broadcast,
      eventSignerFactory: Bip340EventSignerFactory(),
      isSubscriptionReady: (_) => false,
    );
    final connection = await nwc.connect(_uri);
    await nwc.setBackgrounded(true);
    await expectLater(
      nwc.getBalance(connection, timeout: const Duration(milliseconds: 10)),
      throwsA(isA<TimeoutException>()),
    );
    expect(broadcast.sent, isEmpty);
    expect(requests.active, isEmpty);
  });

  test(
    'valid reply releases background connection before delayed ACK',
    () async {
      final connection = await nwc.connect(_uri);
      await nwc.setBackgrounded(true);
      broadcast.ackGate = Completer<void>();
      expect(
        (await nwc.payInvoice(connection, invoice: 'lnbc-test')).preimage,
        'preimage',
      );
      expect(requests.active, isEmpty);
      broadcast.ackGate!.completeError(StateError('late ACK failure'));
      await _flush();
    },
  );

  test('same-second notification replay emits once across resume', () async {
    final connection = await nwc.connect(_uri);
    final notifications = <Object>[];
    final listener = connection.notificationStream.stream.listen(
      notifications.add,
    );
    final event = Nip01Event(
      pubKey: _walletPubkey,
      kind: 23196,
      tags: [],
      content: Nip04.encrypt(
        _walletSecret,
        Bip340.getPublicKey(_clientSecret),
        jsonEncode({
          'notification_type': 'payment_received',
          'notification': {
            'type': 'incoming',
            'invoice': 'lnbc',
            'preimage': 'preimage',
            'payment_hash': 'hash',
            'amount': 1000,
            'fees_paid': 0,
            'created_at': 1,
          },
        }),
      ),
    );
    requests.deliver(event);
    await _flush();
    expect(notifications.length, 1);
    await nwc.setBackgrounded(true);
    await nwc.setBackgrounded(false);
    requests.deliver(event);
    await _flush();
    expect(notifications.length, 1);
    await listener.cancel();
  });

  test('historical notifications do not replay after resume', () async {
    final connection = await nwc.connect(_uri);
    final notifications = <Object>[];
    final listener = connection.notificationStream.stream.listen(
      notifications.add,
    );
    await nwc.setBackgrounded(true);
    await nwc.setBackgrounded(false);
    requests.deliver(
      Nip01Event(
        pubKey: _walletPubkey,
        kind: 23196,
        createdAt: 1,
        tags: [],
        content: 'must not decrypt old history',
      ),
    );
    await _flush();
    expect(notifications, isEmpty);
    await listener.cancel();
  });
}
