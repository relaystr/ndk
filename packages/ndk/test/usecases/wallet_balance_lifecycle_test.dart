import 'dart:async';

import 'package:test/test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet_balance.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet_provider.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet_transaction.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet_type.dart';
import 'package:ndk/domain_layer/entities/wallet/providers/lnbits/lnbits_wallet.dart';
import 'package:ndk/domain_layer/entities/wallet/providers/lnbits/lnbits_wallet_provider.dart';
import 'package:ndk/data_layer/repositories/wallets/mem_wallets_repo.dart';

void main() {
  test(
    'background stops LNbits polling without stopping payments or NWC',
    () async {
      final lnbits = _Provider(WalletType.LNBITS);
      final nwc = _Provider(WalletType.NWC);
      final repo = MemWalletsRepo()
        ..wallets.addAll([_wallet('lnbits'), _wallet('nwc', WalletType.NWC)]);
      final wallets = Wallets(providers: [lnbits, nwc], repository: repo);
      await wallets.getWallets();
      final balanceListener = wallets.combinedBalances.listen((_) {});
      final pendingListener = wallets.combinedPendingTransactions.listen(
        (_) {},
      );
      await pumpEventQueue();
      expect(lnbits.balanceStarts, 1);
      expect(nwc.balanceStarts, 1);
      final payment = wallets.send(walletId: 'lnbits', invoice: 'invoice');
      await pumpEventQueue();

      wallets.setBackgrounded(true);
      wallets.setBackgrounded(true);
      await pumpEventQueue();
      expect(lnbits.balanceCancels, 1);
      expect(nwc.balanceCancels, 0);
      expect(lnbits.pendingCancels, 0);
      expect(wallets.getBalance('lnbits', 'sat'), 42);
      expect(lnbits.balanceStarts, 1);
      lnbits.payment.complete(
        PayInvoiceResponse(resultType: 'pay_invoice', feesPaid: 0),
      );
      expect((await payment).resultType, 'pay_invoice');
      expect((await wallets.refreshBalance('lnbits')).single.amount, 42);
      expect(lnbits.balanceStarts, 2); // Explicit refresh remains allowed.

      wallets.setBackgrounded(false);
      wallets.setBackgrounded(false);
      await pumpEventQueue();
      expect(lnbits.balanceStarts, 3);
      expect(nwc.balanceStarts, 1);
      await balanceListener.cancel();
      await pendingListener.cancel();
      final disposal = wallets.dispose();
      await pumpEventQueue();
      await disposal;
      expect(lnbits.balanceCancels, 3);
    },
  );

  test(
    'wallets loaded or discovered in background wait for foreground',
    () async {
      final provider = _Provider(WalletType.LNBITS);
      final repo = _DelayedRepo();
      final wallets = Wallets(providers: [provider], repository: repo);
      wallets.setBackgrounded(true);
      final listener = wallets.getBalancesStream('late').listen((_) {});
      repo.loaded.complete([_wallet('late')]);
      await wallets.getWallets();
      await wallets.addWallet(_wallet('added'));
      final combined = wallets.combinedBalances.listen((_) {});
      await pumpEventQueue();
      expect(provider.balanceStarts, 0);
      wallets.setBackgrounded(false);
      await pumpEventQueue();
      expect(provider.balanceStarts, 2);
      await wallets.removeWallet('added');
      wallets.setBackgrounded(true);
      wallets.setBackgrounded(false);
      await pumpEventQueue();
      expect(provider.balanceStarts, 3); // Removed wallet cannot restart.
      await listener.cancel();
      await combined.cancel();
      final disposal = wallets.dispose();
      await pumpEventQueue();
      await disposal;
    },
  );

  test(
    'LNbits cancellation removes pending timer and resumes immediately',
    () async {
      final clock = FakeAsync();
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        return http.Response('{"balance":42000,"name":"test"}', 200);
      });
      final provider = LnBitsWalletProvider(client);
      late StreamSubscription<List<WalletBalance>> subscription;
      clock.run((_) {
        subscription = provider.getBalances(_wallet('lnbits')).listen((_) {});
      });
      await _advance(clock, Duration.zero);
      expect(requests, 1);
      clock.run((_) => unawaited(subscription.cancel()));
      await _advance(clock, const Duration(minutes: 2));
      expect(requests, 1);
      clock.run((_) {
        subscription = provider.getBalances(_wallet('lnbits')).listen((_) {});
      });
      await _advance(clock, Duration.zero);
      expect(requests, 2);
      await _advance(clock, const Duration(seconds: 30));
      expect(requests, 3);
      clock.run((_) => unawaited(subscription.cancel()));
      await _advance(clock, Duration.zero);
      expect(clock.nonPeriodicTimerCount, 0);
      client.close();
    },
  );

  test('cancelling an in-flight LNbits read schedules no later poll', () async {
    final clock = FakeAsync();
    var requests = 0;
    final reply = Completer<http.Response>();
    final client = MockClient((request) {
      requests++;
      return reply.future;
    });
    final provider = LnBitsWalletProvider(client);
    final received = <List<WalletBalance>>[];
    late StreamSubscription<List<WalletBalance>> subscription;
    clock.run((_) {
      subscription =
          provider.getBalances(_wallet('lnbits')).listen(received.add);
    });
    await _advance(clock, Duration.zero);
    clock.run((_) => unawaited(subscription.cancel()));
    reply.complete(http.Response('{"balance":42000,"name":"test"}', 200));
    await _advance(clock, Duration.zero);
    await _advance(clock, const Duration(minutes: 2));
    expect(requests, 1);
    expect(received, isEmpty);
    expect(clock.nonPeriodicTimerCount, 0);
    client.close();
  });
}

// HTTP and stream cancellation can use shared futures outside the fake zone.
Future<void> _advance(FakeAsync clock, Duration duration) async {
  clock.elapse(duration);
  await pumpEventQueue(times: 2);
  clock.flushMicrotasks();
  clock.elapse(Duration.zero);
  await pumpEventQueue(times: 2);
  clock.flushMicrotasks();
}

LnBitsWallet _wallet(String id, [WalletType type = WalletType.LNBITS]) =>
    LnBitsWallet(
      id: id,
      name: id,
      type: type,
      supportedUnits: const {'sat'},
      lnbitsUrl: 'https://wallet.example',
      adminKey: 'test-key',
    );

class _DelayedRepo extends MemWalletsRepo {
  final loaded = Completer<List<Wallet>>();
  @override
  Future<List<Wallet>> getWallets({List<String>? ids}) => loaded.future;
}

class _Provider implements WalletProvider {
  @override
  final WalletType type;
  int balanceStarts = 0;
  int balanceCancels = 0;
  int pendingCancels = 0;
  final payment = Completer<PayInvoiceResponse>();
  _Provider(this.type);

  @override
  Stream<List<WalletBalance>> getBalances(Wallet wallet) {
    late StreamController<List<WalletBalance>> controller;
    controller = StreamController(
      onListen: () {
        balanceStarts++;
        controller.add([
          WalletBalance(walletId: wallet.id, unit: 'sat', amount: 42),
        ]);
      },
      onCancel: () => balanceCancels++,
    );
    return controller.stream;
  }

  @override
  Stream<List<WalletTransaction>> getPendingTransactions(Wallet wallet) {
    return StreamController<List<WalletTransaction>>(
      onCancel: () => pendingCancels++,
    ).stream;
  }

  @override
  Stream<List<Wallet>> get discoveredWallets => const Stream.empty();
  @override
  Future<Wallet?> initialize(Wallet wallet) async => null;
  @override
  Future<void> removeWallet(Wallet wallet) async {}
  @override
  Future<PayInvoiceResponse> send(
    Wallet wallet,
    String invoice, {
    Duration? timeout,
  }) =>
      payment.future;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
