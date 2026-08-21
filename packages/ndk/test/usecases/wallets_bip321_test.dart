import 'package:ndk/data_layer/repositories/wallets/mem_wallets_repo.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet_balance.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet_provider.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet_transaction.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet_type.dart';
import 'package:ndk/domain_layer/usecases/nwc/responses/pay_invoice_response.dart';
import 'package:ndk/domain_layer/usecases/nwc/responses/pay_response.dart';
import 'package:ndk/domain_layer/usecases/nwc/responses/receive_response.dart';
import 'package:ndk/domain_layer/usecases/wallets/wallets.dart';
import 'package:test/test.dart';

void main() {
  test('Wallets delegates BIP-321 pay and receive to the wallet provider',
      () async {
    final wallet = _TestWallet();
    final repository = MemWalletsRepo();
    await repository.storeWallet(wallet);
    repository.setDefaultWalletForSending(wallet.id);
    repository.setDefaultWalletForReceiving(wallet.id);

    final provider = _TestWalletProvider(wallet);
    final wallets = Wallets(providers: [provider], repository: repository);
    addTearDown(wallets.dispose);

    final payResponse = await wallets.payBip321(
      payment: 'bitcoin:?lightning=lnbc1invoice',
      amountMsat: 21000,
      payerNote: 'Thanks',
      metadata: {'order_id': '123'},
      timeout: const Duration(seconds: 10),
    );

    expect(payResponse, same(provider.payResponse));
    expect(provider.paidWithWallet, same(wallet));
    expect(provider.payment, 'bitcoin:?lightning=lnbc1invoice');
    expect(provider.payAmountMsat, 21000);
    expect(provider.payerNote, 'Thanks');
    expect(provider.payMetadata, {'order_id': '123'});
    expect(provider.payTimeout, const Duration(seconds: 10));

    final receiveResponse = await wallets.receiveBip321(
      amountMsat: 42000,
      description: 'Coffee',
      metadata: {'order_id': '456'},
      timeout: const Duration(seconds: 15),
    );

    expect(receiveResponse, same(provider.receiveResponse));
    expect(provider.receivedWithWallet, same(wallet));
    expect(provider.receiveAmountMsat, 42000);
    expect(provider.description, 'Coffee');
    expect(provider.receiveMetadata, {'order_id': '456'});
    expect(provider.receiveTimeout, const Duration(seconds: 15));
  });
}

class _TestWallet extends Wallet {
  _TestWallet()
      : super(
          id: 'wallet-1',
          name: 'Test wallet',
          type: WalletType.NWC,
          supportedUnits: const {'sat'},
          metadata: const {},
        );

  @override
  bool get canReceive => true;

  @override
  bool get canSend => true;

  @override
  Map<String, dynamic> toMetadata() => metadata;
}

class _TestWalletProvider extends WalletProvider {
  final Wallet wallet;

  _TestWalletProvider(this.wallet);

  final payResponse = PayResponse(
    resultType: 'pay',
    transactionId: 'pay-transaction',
    state: 'settled',
    instructionType: 'bolt11',
    amountMsat: 21000,
    feesPaid: 1000,
    createdAt: 1700000000,
  );

  final receiveResponse = ReceiveResponse(
    resultType: 'receive',
    bip321: 'bitcoin:?lightning=lnbc1invoice',
    transactionId: 'receive-transaction',
  );

  Wallet? paidWithWallet;
  String? payment;
  int? payAmountMsat;
  String? payerNote;
  Map<String, dynamic>? payMetadata;
  Duration? payTimeout;

  Wallet? receivedWithWallet;
  int? receiveAmountMsat;
  String? description;
  Map<String, dynamic>? receiveMetadata;
  Duration? receiveTimeout;

  @override
  WalletType get type => WalletType.NWC;

  @override
  Wallet createWallet({
    required String id,
    required String name,
    required Set<String> supportedUnits,
    required Map<String, dynamic> metadata,
  }) =>
      wallet;

  @override
  Stream<List<Wallet>> get discoveredWallets => Stream.value(const []);

  @override
  Stream<List<WalletBalance>> getBalances(Wallet wallet) =>
      Stream.value(const []);

  @override
  Stream<List<WalletTransaction>> getPendingTransactions(Wallet wallet) =>
      Stream.value(const []);

  @override
  Stream<List<WalletTransaction>> getRecentTransactions(Wallet wallet) =>
      Stream.value(const []);

  @override
  Future<Wallet?> initialize(Wallet wallet) async => null;

  @override
  Future<void> removeWallet(Wallet wallet) async {}

  @override
  Future<PayInvoiceResponse> send(
    Wallet wallet,
    String invoice, {
    Duration? timeout,
  }) async =>
      PayInvoiceResponse(resultType: 'pay_invoice', feesPaid: 0);

  @override
  Future<String> receive(Wallet wallet, int amountSats) async => 'invoice';

  @override
  Future<PayResponse> payBip321(
    Wallet wallet, {
    required String payment,
    int? amountMsat,
    String? payerNote,
    Map<String, dynamic>? metadata,
    Duration? timeout,
  }) async {
    paidWithWallet = wallet;
    this.payment = payment;
    payAmountMsat = amountMsat;
    this.payerNote = payerNote;
    payMetadata = metadata;
    payTimeout = timeout;
    return payResponse;
  }

  @override
  Future<ReceiveResponse> receiveBip321(
    Wallet wallet, {
    int? amountMsat,
    String? description,
    Map<String, dynamic>? metadata,
    Duration? timeout,
  }) async {
    receivedWithWallet = wallet;
    receiveAmountMsat = amountMsat;
    this.description = description;
    receiveMetadata = metadata;
    receiveTimeout = timeout;
    return receiveResponse;
  }
}
