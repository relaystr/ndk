import 'package:ndk/data_layer/repositories/wallets/mem_wallets_repo.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/domain_layer/usecases/nwc/responses/pay_invoice_response.dart';
import 'package:ndk/domain_layer/usecases/nwc/responses/pay_response.dart';
import 'package:ndk/domain_layer/usecases/nwc/responses/receive_response.dart';
import 'package:test/test.dart';

void main() {
  test('transfers to a BOLT12-only wallet through BIP-321', () async {
    final source = _TestWallet(
      id: 'nwc-source',
      type: WalletType.NWC,
      canSendValue: true,
      sendProtocols: const {WalletPaymentProtocol.bolt12},
      supportsBip321PayValue: true,
    );
    final destination = _TestWallet(
      id: 'bolt12-destination',
      type: WalletType.BOLT12,
      canReceiveValue: true,
      receiveProtocols: const {WalletPaymentProtocol.bolt12},
      supportsBip321ReceiveValue: true,
      supportsBolt11InvoiceReceiveValue: false,
    );
    final sourceProvider = _TestWalletProvider(source.type);
    final destinationProvider = _TestWalletProvider(destination.type)
      ..bip321ToReceive = 'bitcoin:?lno=lno1offer';
    final wallets = await _wallets(
      [source, destination],
      [sourceProvider, destinationProvider],
    );
    addTearDown(wallets.dispose);

    expect(
      wallets.compatibleTransferProtocol(
        source: source,
        destination: destination,
      ),
      WalletPaymentProtocol.bolt12,
    );

    final result = await wallets.transfer(
      sourceWalletId: source.id,
      destinationWalletId: destination.id,
      amountMsat: 21000,
    );

    expect(result.protocol, WalletPaymentProtocol.bolt12);
    expect(destinationProvider.receivedAmountMsat, 21000);
    expect(destinationProvider.receivedMetadata, isNull);
    expect(sourceProvider.paidPayment, 'bitcoin:?lno=lno1offer');
    expect(sourceProvider.paidAmountMsat, 21000);
    expect(sourceProvider.paidMetadata, isNull);
  });

  test('transfers between legacy wallets with a fresh BOLT11 invoice',
      () async {
    final source = _TestWallet(
      id: 'cashu-source',
      type: WalletType.CASHU,
      canSendValue: true,
    );
    final destination = _TestWallet(
      id: 'lnurl-destination',
      type: WalletType.LNURL,
      canReceiveValue: true,
    );
    final sourceProvider = _TestWalletProvider(source.type);
    final destinationProvider = _TestWalletProvider(destination.type)
      ..invoiceToReceive = 'lnbc1internaltransfer';
    final wallets = await _wallets(
      [source, destination],
      [sourceProvider, destinationProvider],
    );
    addTearDown(wallets.dispose);

    final result = await wallets.transfer(
      sourceWalletId: source.id,
      destinationWalletId: destination.id,
      amountMsat: 42000,
    );

    expect(result.protocol, WalletPaymentProtocol.bolt11);
    expect(destinationProvider.receivedAmountSats, 42);
    expect(sourceProvider.paidInvoice, 'lnbc1internaltransfer');
    expect(
      result.payment,
      'bitcoin:?lightning=lnbc1internaltransfer',
    );
  });

  test('does not offer a BOLT12 destination to a legacy-only sender', () {
    final source = _TestWallet(
      id: 'legacy-source',
      type: WalletType.CASHU,
      canSendValue: true,
    );
    final destination = _TestWallet(
      id: 'bolt12-destination',
      type: WalletType.BOLT12,
      canReceiveValue: true,
      receiveProtocols: const {WalletPaymentProtocol.bolt12},
      supportsBip321ReceiveValue: true,
      supportsBolt11InvoiceReceiveValue: false,
    );
    final wallets = Wallets(
      providers: const [],
      repository: MemWalletsRepo(),
    );
    addTearDown(wallets.dispose);

    expect(
      wallets.compatibleTransferProtocol(
        source: source,
        destination: destination,
      ),
      isNull,
    );
  });
}

Future<Wallets> _wallets(
  List<Wallet> walletList,
  List<WalletProvider> providers,
) async {
  final repository = MemWalletsRepo();
  for (final wallet in walletList) {
    await repository.storeWallet(wallet);
  }
  final wallets = Wallets(providers: providers, repository: repository);
  await wallets.getWallets();
  return wallets;
}

class _TestWallet extends Wallet {
  final bool canSendValue;
  final bool canReceiveValue;
  final Set<WalletPaymentProtocol>? sendProtocols;
  final Set<WalletPaymentProtocol>? receiveProtocols;
  final bool supportsBip321PayValue;
  final bool supportsBip321ReceiveValue;
  final bool? supportsBolt11InvoiceReceiveValue;

  _TestWallet({
    required super.id,
    required super.type,
    this.canSendValue = false,
    this.canReceiveValue = false,
    this.sendProtocols,
    this.receiveProtocols,
    this.supportsBip321PayValue = false,
    this.supportsBip321ReceiveValue = false,
    this.supportsBolt11InvoiceReceiveValue,
  }) : super(
          name: id,
          supportedUnits: const {'sat'},
          metadata: const {},
        );

  @override
  bool get canReceive => canReceiveValue;

  @override
  bool get canSend => canSendValue;

  @override
  Set<WalletPaymentProtocol> get sendPaymentProtocols =>
      sendProtocols ?? super.sendPaymentProtocols;

  @override
  Set<WalletPaymentProtocol> get receivePaymentProtocols =>
      receiveProtocols ?? super.receivePaymentProtocols;

  @override
  bool get supportsBip321Pay => supportsBip321PayValue;

  @override
  bool get supportsBip321Receive => supportsBip321ReceiveValue;

  @override
  bool get supportsBolt11InvoiceReceive =>
      supportsBolt11InvoiceReceiveValue ?? super.supportsBolt11InvoiceReceive;

  @override
  Map<String, dynamic> toMetadata() => metadata;
}

class _TestWalletProvider implements WalletProvider {
  @override
  final WalletType type;

  String invoiceToReceive = 'lnbc1invoice';
  String bip321ToReceive = 'bitcoin:?lightning=lnbc1invoice';
  int? receivedAmountSats;
  int? receivedAmountMsat;
  String? paidInvoice;
  String? paidPayment;
  int? paidAmountMsat;
  Map<String, dynamic>? paidMetadata;
  Map<String, dynamic>? receivedMetadata;

  _TestWalletProvider(this.type);

  @override
  Wallet createWallet({
    required String id,
    required String name,
    required Set<String> supportedUnits,
    required Map<String, dynamic> metadata,
  }) =>
      throw UnimplementedError();

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
  }) async {
    paidInvoice = invoice;
    return PayInvoiceResponse(resultType: 'pay_invoice', feesPaid: 0);
  }

  @override
  Future<String> receive(Wallet wallet, int amountSats) async {
    receivedAmountSats = amountSats;
    return invoiceToReceive;
  }

  @override
  Future<PayResponse> payBip321(
    Wallet wallet, {
    required String payment,
    int? amountMsat,
    String? payerNote,
    Map<String, dynamic>? metadata,
    Duration? timeout,
  }) async {
    paidPayment = payment;
    paidAmountMsat = amountMsat;
    paidMetadata = metadata;
    return PayResponse(
      resultType: 'pay',
      transactionId: 'transfer',
      state: 'settled',
      instructionType: payment.contains('lno=') ? 'bolt12' : 'bolt11',
      amountMsat: amountMsat ?? 0,
      feesPaid: 0,
      createdAt: 1700000000,
    );
  }

  @override
  Future<ReceiveResponse> receiveBip321(
    Wallet wallet, {
    int? amountMsat,
    String? description,
    Map<String, dynamic>? metadata,
    Duration? timeout,
  }) async {
    receivedAmountMsat = amountMsat;
    receivedMetadata = metadata;
    return ReceiveResponse(resultType: 'receive', bip321: bip321ToReceive);
  }
}
