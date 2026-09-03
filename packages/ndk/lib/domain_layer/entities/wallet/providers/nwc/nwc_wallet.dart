import 'package:ndk/domain_layer/entities/wallet/wallet.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet_balance.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet_transaction.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet_type.dart';
import 'package:ndk/domain_layer/usecases/nwc/consts/nwc_method.dart';
import 'package:ndk/domain_layer/usecases/nwc/nwc_connection.dart';
import 'package:rxdart/rxdart.dart';

/// NWC (Nostr Wallet Connect) wallet implementation
/// Manages connection to a remote wallet via NWC protocol
class NwcWallet extends Wallet {
  static const String kPermissionsMetadataKey = 'permissions';

  final String nwcUrl;
  final Set<String> cachedPermissions;
  NwcConnection? connection;

  /// Remaining NWC budget in sats, cached after the last `get_budget` call.
  /// null = wallet doesn't support get_budget, or not yet fetched.
  int? cachedRemainingBudgetSats;

  BehaviorSubject<List<WalletBalance>>? balanceSubject;
  BehaviorSubject<List<WalletTransaction>>? transactionsSubject;
  BehaviorSubject<List<WalletTransaction>>? pendingTransactionsSubject;

  bool isConnected() => connection != null;

  NwcWallet({
    required super.id,
    required super.name,
    super.type = WalletType.NWC,
    required super.supportedUnits,
    required this.nwcUrl,
    Set<String> cachedPermissions = const {},
    Map<String, dynamic>? metadata,
  })  : cachedPermissions = Set.unmodifiable(cachedPermissions),
        super(
          metadata: Map.unmodifiable({
            ...(metadata ?? const {}),
            'nwcUrl': nwcUrl,
            kPermissionsMetadataKey: cachedPermissions.toList(),
          }),
        );

  @override
  Map<String, dynamic> toMetadata() => metadata;

  /// Factory method for deserialization from storage
  /// Creates NwcWallet from stored metadata
  static NwcWallet fromStorage({
    required String id,
    required String name,
    required Set<String> supportedUnits,
    required Map<String, dynamic> metadata,
  }) {
    final nwcUrl = metadata['nwcUrl'] as String?;
    if (nwcUrl == null || nwcUrl.isEmpty) {
      throw ArgumentError('NwcWallet storage requires metadata["nwcUrl"]');
    }

    return NwcWallet(
      id: id,
      name: name,
      supportedUnits: supportedUnits,
      nwcUrl: nwcUrl,
      cachedPermissions: _parsePermissions(metadata[kPermissionsMetadataKey]),
      metadata: metadata,
    );
  }

  NwcWallet withCachedPermissions(Set<String> permissions) {
    final wallet = NwcWallet(
      id: id,
      name: name,
      supportedUnits: supportedUnits,
      nwcUrl: nwcUrl,
      cachedPermissions: permissions,
      metadata: metadata,
    );
    wallet.connection = connection;
    wallet.cachedRemainingBudgetSats = cachedRemainingBudgetSats;
    wallet.balanceSubject = balanceSubject;
    wallet.transactionsSubject = transactionsSubject;
    wallet.pendingTransactionsSubject = pendingTransactionsSubject;
    return wallet;
  }

  static Set<String> _parsePermissions(dynamic value) {
    if (value == null) return {};
    if (value is String) return {value};
    if (value is List) {
      return value.whereType<String>().toSet();
    }
    return {};
  }

  /// Permissions advertised by the live connection, falling back to the
  /// persisted capability snapshot while the connection initializes.
  Set<String> get effectivePermissions =>
      connection?.permissions.isNotEmpty == true
          ? connection!.permissions
          : cachedPermissions;

  bool supportsMethod(NwcMethod method) =>
      effectivePermissions.contains(method.name);

  @override
  bool get canReceive =>
      supportsMethod(NwcMethod.MAKE_INVOICE) ||
      supportsMethod(NwcMethod.RECEIVE);

  @override
  bool get canSend =>
      supportsMethod(NwcMethod.PAY_INVOICE) || supportsMethod(NwcMethod.PAY);

  @override
  Set<WalletPaymentProtocol> get sendPaymentProtocols => {
        if (supportsMethod(NwcMethod.PAY_INVOICE) ||
            supportsMethod(NwcMethod.PAY))
          WalletPaymentProtocol.bolt11,
        if (supportsMethod(NwcMethod.PAY)) WalletPaymentProtocol.bolt12,
      };

  @override
  Set<WalletPaymentProtocol> get receivePaymentProtocols => {
        if (supportsMethod(NwcMethod.MAKE_INVOICE) ||
            supportsMethod(NwcMethod.RECEIVE))
          WalletPaymentProtocol.bolt11,
        if (supportsMethod(NwcMethod.RECEIVE)) WalletPaymentProtocol.bolt12,
      };

  @override
  bool get supportsBip321Pay => supportsMethod(NwcMethod.PAY);

  @override
  bool get supportsBip321Receive => supportsMethod(NwcMethod.RECEIVE);

  @override
  bool get supportsBolt11InvoicePay => supportsMethod(NwcMethod.PAY_INVOICE);

  @override
  bool get supportsBolt11InvoiceReceive =>
      supportsMethod(NwcMethod.MAKE_INVOICE);
}
