import 'package:ndk/domain_layer/entities/wallet/wallet_balance.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet_transaction.dart';
import 'package:rxdart/rxdart.dart';

import '../../usecases/nwc/nwc_connection.dart';
import '../cashu/cashu_mint_info.dart';
import 'wallet_type.dart';

/// compatitability layer for generic wallets usecase as well as storage.
/// [metadata] is used to store additional information required for the specific wallet type
abstract class Wallet {
  /// local wallet identifier
  final String id;

  final WalletType type;

  /// unit like sat, usd, etc.
  final Set<String> supportedUnits;

  /// user defined name for the wallet
  String name;

  /// metadata to store additional information for the specific wallet type
  /// e.g. for Cashu store mintUrl
  final Map<String, dynamic> metadata;

  Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.supportedUnits,
    required this.metadata,
  });

  /// constructs the concrete wallet type based on the type string \
  /// metadata is used to provide additional information required for the wallet type
  static Wallet toWalletType({
    required String id,
    required String name,
    required WalletType type,
    required Set<String> supportedUnits,
    required Map<String, dynamic> metadata,
  }) {
    switch (type) {
      case WalletType.CASHU:
        final mintUrl = metadata['mintUrl'] as String?;
        if (mintUrl == null || mintUrl.isEmpty) {
          throw ArgumentError('CashuWallet requires metadata["mintUrl"]');
        }
        return CashuWallet(
          id: id,
          name: name,
          type: type,
          supportedUnits: supportedUnits,
          metadata: metadata,
          mintUrl: mintUrl,
          mintInfo: CashuMintInfo.fromJson(
            metadata['mintInfo'] as Map<String, dynamic>,
          ),
        );
      case WalletType.NWC:
        final nwcUrl = metadata['nwcUrl'] as String?;
        if (nwcUrl == null || nwcUrl.isEmpty) {
          throw ArgumentError('NwcWallet requires metadata["nwcUrl"]');
        }
        return NwcWallet(
          id: id,
          name: name,
          type: type,
          supportedUnits: supportedUnits,
          metadata: metadata,
          nwcUrl: nwcUrl,
        );
    }
  }
}

class CashuWallet extends Wallet {
  final String mintUrl;
  final CashuMintInfo mintInfo;

  CashuWallet({
    required super.id,
    required super.name,
    super.type = WalletType.CASHU,
    required super.supportedUnits,
    required this.mintUrl,
    required this.mintInfo,
    Map<String, dynamic>? metadata,
  }) : super(
          /// update metadata to include mintUrl
          metadata: Map.unmodifiable({
            ...(metadata ?? const {}),
            'mintUrl': mintUrl,
            'mintInfo': mintInfo.toJson(),
          }),
        );
}

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
}
