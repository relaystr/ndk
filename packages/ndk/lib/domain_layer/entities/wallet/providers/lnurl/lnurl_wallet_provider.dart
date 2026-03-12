import 'dart:async';

import 'package:ndk/domain_layer/usecases/lnurl/lnurl.dart';
import 'package:ndk/domain_layer/usecases/lnurl/lnurl_response.dart';
import 'package:ndk/shared/logger/logger.dart';
import 'package:ndk/domain_layer/usecases/nwc/responses/pay_invoice_response.dart';
import '../../wallet.dart';
import '../../wallet_balance.dart';
import '../../wallet_provider.dart';
import '../../wallet_transaction.dart';
import '../../wallet_type.dart';
import 'lnurl_wallet.dart';

/// Provider for LNURL wallets
/// Implements receive-only functionality for LNURL-pay endpoints
/// Supports user@domain.com format only
class LnurlWalletProvider implements WalletProvider {
  final Lnurl _lnurlUseCase;

  /// Cache for LNURL metadata (identifier -> LnurlResponse)
  final Map<String, _CachedMetadata> _metadataCache = {};

  LnurlWalletProvider(this._lnurlUseCase);

  @override
  WalletType get type => WalletType.LNURL;

  @override
  Wallet createWallet({
    required String id,
    required String name,
    required Set<String> supportedUnits,
    required Map<String, dynamic> metadata,
  }) {
    final identifier = metadata['identifier'] as String?;
    if (identifier == null || identifier.isEmpty) {
      throw ArgumentError(
          'LnurlWallet requires metadata["identifier"] in user@domain.com format');
    }

    // Validate identifier format (user@domain.com)
    if (!_isValidIdentifier(identifier)) {
      throw ArgumentError(
          'LnurlWallet identifier must be in user@domain.com format');
    }

    // Resolve to LNURL endpoint
    final lnurlPayUrl = Lnurl.getLud16LinkFromLud16(identifier);
    if (lnurlPayUrl == null) {
      throw ArgumentError(
          'Could not resolve LNURL endpoint from identifier: $identifier');
    }

    return LnurlWallet(
      id: id,
      name: name,
      supportedUnits: supportedUnits,
      identifier: identifier,
      lnurlPayUrl: lnurlPayUrl,
      metadata: metadata,
    );
  }

  @override
  Future<void> initialize(Wallet wallet) async {
    final lnurlWallet = wallet as LnurlWallet;
    // Pre-fetch metadata if not cached or expired
    if (!lnurlWallet.isMetadataValid) {
      await _fetchAndCacheMetadata(lnurlWallet);
    }
  }

  @override
  Future<void> dispose(Wallet wallet) async {
    final lnurlWallet = wallet as LnurlWallet;
    // Clear metadata cache for this wallet
    _metadataCache.remove(lnurlWallet.identifier);
  }

  @override
  Stream<List<WalletBalance>> getBalances(Wallet wallet) {
    // LNURL is read-only, cannot query balance
    return Stream.value([]);
  }

  @override
  Stream<List<WalletTransaction>> getPendingTransactions(Wallet wallet) {
    // LNURL is stateless, no pending transactions
    return Stream.value([]);
  }

  @override
  Stream<List<WalletTransaction>> getRecentTransactions(Wallet wallet) {
    // LNURL is stateless, no transaction history
    return Stream.value([]);
  }

  @override
  Future<PayInvoiceResponse> payInvoice(Wallet wallet, String invoice) async {
    // LNURL wallet is receive-only, cannot pay invoices
    throw UnsupportedError(
        'LNURL wallet is receive-only and cannot pay invoices');
  }

  @override
  Future<String> receive(Wallet wallet, int amountSats) async {
    final lnurlWallet = wallet as LnurlWallet;

    // Get metadata (from cache or fetch fresh)
    LnurlResponse metadata;
    final cached = _metadataCache[lnurlWallet.identifier];
    if (cached != null && !cached.isExpired) {
      metadata = cached.response;
      Logger.log
          .d(() => 'Using cached LNURL metadata for ${lnurlWallet.identifier}');
    } else {
      metadata = await _fetchAndCacheMetadata(lnurlWallet);
    }

    // Validate amount is within allowed range
    final amountMillisats = amountSats * 1000;
    if (metadata.minSendable != null &&
        amountMillisats < metadata.minSendable!) {
      throw ArgumentError(
          'Amount $amountSats sats is below minimum ${metadata.minSendable! ~/ 1000} sats');
    }
    if (metadata.maxSendable != null &&
        amountMillisats > metadata.maxSendable!) {
      throw ArgumentError(
          'Amount $amountSats sats exceeds maximum ${metadata.maxSendable! ~/ 1000} sats');
    }

    // Generate invoice via callback
    final invoiceResponse = await _lnurlUseCase.fetchInvoice(
      lnurlResponse: metadata,
      amountSats: amountSats,
    );

    if (invoiceResponse == null || invoiceResponse.invoice.isEmpty) {
      throw Exception('Failed to generate invoice from LNURL endpoint');
    }

    return invoiceResponse.invoice;
  }

  @override
  Stream<List<Wallet>> get discoveredWallets {
    // LNURL wallets are not auto-discovered
    return Stream.value([]);
  }

  /// Validates identifier is in user@domain.com format
  bool _isValidIdentifier(String identifier) {
    // Must contain exactly one @
    final parts = identifier.split('@');
    if (parts.length != 2) return false;

    final user = parts[0];
    final domain = parts[1];

    // User part must not be empty
    if (user.isEmpty) return false;

    // Domain part must contain at least one dot (e.g., domain.com)
    if (!domain.contains('.')) return false;

    // No spaces allowed
    if (identifier.contains(' ')) return false;

    return true;
  }

  /// Fetches metadata from LNURL endpoint and caches it
  Future<LnurlResponse> _fetchAndCacheMetadata(LnurlWallet wallet) async {
    Logger.log.d(() => 'Fetching LNURL metadata for ${wallet.identifier}');

    final response = await _lnurlUseCase.getLnurlResponse(wallet.lnurlPayUrl);
    if (response == null) {
      throw Exception(
          'Failed to fetch LNURL metadata from ${wallet.lnurlPayUrl}');
    }

    // Cache the metadata
    _metadataCache[wallet.identifier] = _CachedMetadata(
      response: response,
      fetchedAt: DateTime.now(),
    );

    // Update wallet with new metadata
    // Note: In a real implementation, you might want to persist this
    // For now, we just use the cache

    return response;
  }
}

/// Helper class to cache metadata with expiration
class _CachedMetadata {
  final LnurlResponse response;
  final DateTime fetchedAt;

  _CachedMetadata({
    required this.response,
    required this.fetchedAt,
  });

  /// Check if cache is expired (10 minutes)
  bool get isExpired {
    final tenMinutesAgo = DateTime.now().subtract(const Duration(minutes: 10));
    return fetchedAt.isBefore(tenMinutesAgo);
  }
}
