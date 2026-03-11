import 'package:ndk/domain_layer/entities/wallet/wallet.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet_balance.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet_transaction.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet_type.dart';
import 'package:ndk/domain_layer/usecases/nwc/nwc_connection.dart';
import 'package:rxdart/rxdart.dart';

/// NWC (Nostr Wallet Connect) wallet implementation
/// Manages connection to a remote wallet via NWC protocol
class NwcWallet extends Wallet {
  final String nwcUrl;
  NwcConnection? connection;
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
    Map<String, dynamic>? metadata,
  }) : super(
          metadata: Map.unmodifiable({
            ...(metadata ?? const {}),
            'nwcUrl': nwcUrl,
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
      metadata: metadata,
    );
  }
}
