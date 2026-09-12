import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../usecases/nwc/responses/pay_invoice_response.dart';
import '../../../../usecases/nwc/responses/pay_response.dart';
import '../../../../usecases/nwc/responses/receive_response.dart';
import '../../bip321.dart';
import '../../wallet.dart';
import '../../wallet_balance.dart';
import '../../wallet_provider.dart';
import '../../wallet_transaction.dart';
import '../../wallet_type.dart';
import 'lnbits_wallet.dart';

class LnBitsWalletInfo {
  final String? id;
  final String name;
  final int balanceMsat;

  const LnBitsWalletInfo({
    required this.id,
    required this.name,
    required this.balanceMsat,
  });
}

class LnBitsApiException implements Exception {
  final int statusCode;
  final String message;

  const LnBitsApiException(this.statusCode, this.message);

  @override
  String toString() => 'LNbits API error ($statusCode): $message';
}

/// Direct LNbits REST API wallet provider.
class LnBitsWalletProvider implements WalletProvider {
  static const balanceRefreshInterval = Duration(seconds: 30);

  final http.Client _client;

  LnBitsWalletProvider([http.Client? client])
      : _client = client ?? http.Client();

  @override
  WalletType get type => WalletType.LNBITS;

  static String normalizeUrl(String value) {
    final trimmed = value.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException('Enter a valid LNbits HTTP or HTTPS URL');
    }
    return uri.toString().replaceAll(RegExp(r'/+$'), '');
  }

  /// Verifies credentials and returns wallet details without storing anything.
  static Future<LnBitsWalletInfo> probe({
    required String lnbitsUrl,
    required String adminKey,
    Duration timeout = const Duration(seconds: 10),
    http.Client? client,
  }) async {
    final ownedClient = client == null ? http.Client() : null;
    final effectiveClient = client ?? ownedClient!;
    try {
      final provider = LnBitsWalletProvider(effectiveClient);
      return await provider._getWalletInfo(
        lnbitsUrl: normalizeUrl(lnbitsUrl),
        adminKey: _validateAdminKey(adminKey),
        timeout: timeout,
      );
    } finally {
      ownedClient?.close();
    }
  }

  @override
  Wallet createWallet({
    required String id,
    required String name,
    required Set<String> supportedUnits,
    required Map<String, dynamic> metadata,
  }) {
    return LnBitsWallet(
      id: id,
      name: name,
      supportedUnits: supportedUnits,
      lnbitsUrl: normalizeUrl(
        metadata[LnBitsWallet.urlMetadataKey]?.toString() ?? '',
      ),
      adminKey: _validateAdminKey(
        metadata[LnBitsWallet.adminKeyMetadataKey]?.toString() ?? '',
      ),
      remoteWalletId:
          metadata[LnBitsWallet.remoteWalletIdMetadataKey]?.toString(),
      readOnly: metadata[LnBitsWallet.readOnlyMetadataKey] as bool? ?? false,
      metadata: metadata,
    );
  }

  @override
  Future<Wallet?> initialize(Wallet wallet) async {
    final lnbitsWallet = _asLnBitsWallet(wallet);
    final info = await _getWalletInfo(
      lnbitsUrl: lnbitsWallet.lnbitsUrl,
      adminKey: lnbitsWallet.adminKey,
    );
    if (info.id == lnbitsWallet.remoteWalletId) return null;
    return LnBitsWallet(
      id: lnbitsWallet.id,
      name: lnbitsWallet.name,
      supportedUnits: lnbitsWallet.supportedUnits,
      lnbitsUrl: lnbitsWallet.lnbitsUrl,
      adminKey: lnbitsWallet.adminKey,
      remoteWalletId: info.id,
      readOnly: lnbitsWallet.readOnly,
      metadata: lnbitsWallet.metadata,
    );
  }

  @override
  Future<void> removeWallet(Wallet wallet) async {}

  @override
  Stream<List<WalletBalance>> getBalances(Wallet wallet) async* {
    final lnbitsWallet = _asLnBitsWallet(wallet);
    while (true) {
      final info = await _getWalletInfo(
        lnbitsUrl: lnbitsWallet.lnbitsUrl,
        adminKey: lnbitsWallet.adminKey,
      );
      yield [
        WalletBalance(
          walletId: wallet.id,
          unit: 'sat',
          amount: info.balanceMsat ~/ 1000,
        ),
      ];
      await Future<void>.delayed(balanceRefreshInterval);
    }
  }

  @override
  Stream<List<WalletTransaction>> getPendingTransactions(Wallet wallet) {
    final lnbitsWallet = _asLnBitsWallet(wallet);
    return Stream.fromFuture(
      _getPayments(lnbitsWallet).then(
        (items) => items.where((item) => item.state.isPending).toList(),
      ),
    );
  }

  @override
  Stream<List<WalletTransaction>> getRecentTransactions(Wallet wallet) {
    final lnbitsWallet = _asLnBitsWallet(wallet);
    return Stream.fromFuture(
      _getPayments(lnbitsWallet).then(
        (items) => items.where((item) => item.state.isDone).toList(),
      ),
    );
  }

  @override
  Future<PayInvoiceResponse> send(
    Wallet wallet,
    String invoice, {
    Duration? timeout,
  }) async {
    if (_asLnBitsWallet(wallet).readOnly) {
      throw UnsupportedError('LNbits invoice/read key cannot send payments');
    }
    final result = await _pay(
      _asLnBitsWallet(wallet),
      invoice,
      timeout: timeout,
    );
    return PayInvoiceResponse(
      resultType: 'pay_invoice',
      preimage: result.preimage,
      feesPaid: result.feesPaid,
    );
  }

  @override
  Future<String> receive(Wallet wallet, int amountSats) async {
    if (amountSats <= 0) {
      throw ArgumentError.value(amountSats, 'amountSats', 'Must be positive');
    }
    final response = await _requestJson(
      _asLnBitsWallet(wallet),
      'POST',
      '/api/v1/payments',
      body: {'out': false, 'amount': amountSats, 'unit': 'sat', 'memo': ''},
    );
    final invoice = response['payment_request']?.toString();
    if (invoice == null || invoice.isEmpty) {
      throw const FormatException('LNbits returned no payment request');
    }
    return invoice;
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
    if (_asLnBitsWallet(wallet).readOnly) {
      throw UnsupportedError('LNbits invoice/read key cannot send payments');
    }
    if (payerNote?.isNotEmpty == true) {
      throw UnsupportedError(
          'LNbits BOLT11 payments do not support payer notes');
    }
    final invoice = Bip321.getBolt11(payment);
    final invoiceAmount = Bip321.getBolt11AmountMsat(invoice);
    if (invoiceAmount != null &&
        amountMsat != null &&
        invoiceAmount != amountMsat) {
      throw ArgumentError(
        'BIP-321 amount $amountMsat msats conflicts with '
        'the BOLT11 invoice amount $invoiceAmount msats',
      );
    }
    final result = await _pay(
      _asLnBitsWallet(wallet),
      invoice,
      timeout: timeout,
    );
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return PayResponse(
      resultType: 'pay',
      transactionId: result.paymentHash,
      state: 'settled',
      instructionType: 'bolt11',
      amountMsat: invoiceAmount ?? amountMsat ?? 0,
      feesPaid: result.feesPaid,
      paymentHash: result.paymentHash,
      preimage: result.preimage,
      createdAt: result.createdAt ?? now,
      settledAt: result.createdAt ?? now,
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
    if (amountMsat == null || amountMsat <= 0 || amountMsat % 1000 != 0) {
      throw ArgumentError.value(
        amountMsat,
        'amountMsat',
        'LNbits requires a positive whole-satoshi amount',
      );
    }
    final response = await _requestJson(
      _asLnBitsWallet(wallet),
      'POST',
      '/api/v1/payments',
      body: {
        'out': false,
        'amount': amountMsat ~/ 1000,
        'unit': 'sat',
        'memo': description ?? '',
      },
      timeout: timeout,
    );
    final invoice = response['payment_request']?.toString();
    if (invoice == null || invoice.isEmpty) {
      throw const FormatException('LNbits returned no payment request');
    }
    return ReceiveResponse(
      resultType: 'receive',
      bip321: Bip321.fromBolt11(invoice),
      transactionId: response['payment_hash']?.toString(),
    );
  }

  @override
  Stream<List<Wallet>> get discoveredWallets => Stream.value(const []);

  Future<LnBitsWalletInfo> _getWalletInfo({
    required String lnbitsUrl,
    required String adminKey,
    Duration? timeout,
  }) async {
    final wallet = LnBitsWallet(
      id: 'probe',
      name: 'LNbits',
      supportedUnits: const {'sat'},
      lnbitsUrl: lnbitsUrl,
      adminKey: adminKey,
    );
    final response = await _requestJson(
      wallet,
      'GET',
      '/api/v1/wallet',
      timeout: timeout,
    );
    final name = response['name']?.toString().trim();
    return LnBitsWalletInfo(
      id: response['id']?.toString(),
      name: name?.isNotEmpty == true ? name! : 'LNbits',
      balanceMsat: _asInt(response['balance']) ?? 0,
    );
  }

  Future<_LnBitsPaymentResult> _pay(
    LnBitsWallet wallet,
    String invoice, {
    Duration? timeout,
  }) async {
    final response = await _requestJson(
      wallet,
      'POST',
      '/api/v1/payments',
      body: {'out': true, 'bolt11': invoice},
      timeout: timeout,
    );
    final paymentHash = response['payment_hash']?.toString();
    if (paymentHash == null || paymentHash.isEmpty) {
      throw const FormatException('LNbits returned no payment hash');
    }
    return _LnBitsPaymentResult(
      paymentHash: paymentHash,
      preimage: response['preimage']?.toString(),
      feesPaid: (_asInt(response['fee']) ?? 0).abs(),
      createdAt: _asInt(response['time']),
    );
  }

  Future<List<WalletTransaction>> _getPayments(LnBitsWallet wallet) async {
    final response = await _request(
      wallet,
      'GET',
      '/api/v1/payments',
    );
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException('Invalid LNbits payments');
    }
    return decoded.whereType<Map>().map((raw) {
      final payment = Map<String, dynamic>.from(raw);
      final amountMsat = _asInt(payment['amount']) ?? 0;
      return LnurlWalletTransaction(
        id: payment['payment_hash']?.toString() ?? '',
        walletId: wallet.id,
        changeAmount: amountMsat ~/ 1000,
        unit: payment['unit']?.toString() ?? 'sat',
        walletType: WalletType.LNBITS,
        state: _paymentState(payment),
        completionMsg: payment['memo']?.toString(),
        transactionDate: _asInt(payment['time']),
        initiatedDate: _asInt(payment['created_at']) ?? _asInt(payment['time']),
        metadata: payment,
      );
    }).toList();
  }

  Future<Map<String, dynamic>> _requestJson(
    LnBitsWallet wallet,
    String method,
    String path, {
    Map<String, dynamic>? body,
    Duration? timeout,
  }) async {
    final response = await _request(
      wallet,
      method,
      path,
      body: body,
      timeout: timeout,
    );
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) throw const FormatException('Invalid LNbits response');
    return Map<String, dynamic>.from(decoded);
  }

  Future<http.Response> _request(
    LnBitsWallet wallet,
    String method,
    String path, {
    Map<String, dynamic>? body,
    Duration? timeout,
  }) async {
    final base = Uri.parse(wallet.lnbitsUrl);
    final uri = base.replace(
      path: '${base.path.replaceAll(RegExp(r'/+$'), '')}$path',
      query: null,
      fragment: null,
    );
    final request = http.Request(method, uri)
      ..headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Api-Key': wallet.adminKey,
      });
    if (body != null) request.body = jsonEncode(body);
    final future = _client.send(request).then(http.Response.fromStream);
    final response = await future.timeout(
      timeout ?? const Duration(seconds: 15),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      var message = response.body;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['detail'] != null) {
          message = decoded['detail'].toString();
        }
      } catch (_) {}
      throw LnBitsApiException(response.statusCode, message);
    }
    return response;
  }

  static LnBitsWallet _asLnBitsWallet(Wallet wallet) {
    if (wallet is! LnBitsWallet) {
      throw ArgumentError('Expected an LnBitsWallet');
    }
    return wallet;
  }

  static String _validateAdminKey(String value) {
    final key = value.trim();
    if (key.isEmpty) {
      throw const FormatException('LNbits Admin Key is required');
    }
    return key;
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static WalletTransactionState _paymentState(Map<String, dynamic> payment) {
    if (payment['pending'] == true || payment['status'] == 'pending') {
      return WalletTransactionState.pending;
    }
    if (payment['status'] == 'failed') return WalletTransactionState.failed;
    return WalletTransactionState.completed;
  }
}

class _LnBitsPaymentResult {
  final String paymentHash;
  final String? preimage;
  final int feesPaid;
  final int? createdAt;

  const _LnBitsPaymentResult({
    required this.paymentHash,
    required this.preimage,
    required this.feesPaid,
    required this.createdAt,
  });
}
