import '../cashu/cashu_keyset.dart';
import '../cashu/cashu_quote.dart';
import 'wallet_type.dart';

abstract class WalletTransaction {
  final String id;
  final String walletId;

  /// positive for incoming, negative for outgoing
  final int changeAmount;
  final String unit;
  final WalletType walletType;
  final WalletTransactionState state;
  final String? completionMsg;

  /// Date in milliseconds since epoch
  int? transactionDate;

  /// Date in milliseconds since epoch
  int? initiatedDate;

  /// metadata to store additional information for the specific transaction type
  final Map<String, dynamic> metadata;

  WalletTransaction({
    required this.id,
    required this.walletId,
    required this.changeAmount,
    required this.unit,
    required this.walletType,
    required this.state,
    required this.metadata,
    this.completionMsg,
    this.transactionDate,
    this.initiatedDate,
  });

  /// constructs the concrete wallet type based on the type string \
  /// metadata is used to provide additional information required for the wallet type
  static WalletTransaction toWalletType({
    required String id,
    required String walletId,
    required int changeAmount,
    required String unit,
    required WalletType walletType,
    required WalletTransactionState state,
    required String typeUnparsed,
    required Map<String, dynamic> metadata,
    String? completionMsg,
    int? transactionDate,
    int? initiatedDate,
  }) {
    final type = WalletType.fromValue(typeUnparsed);

    switch (type) {
      case WalletType.CASHU:
        return CashuWalletTransaction(
          id: id,
          walletId: walletId,
          changeAmount: changeAmount,
          unit: unit,
          walletType: walletType,
          state: state,
          mintUrl: metadata['mintUrl'] as String,
          completionMsg: completionMsg,
          transactionDate: transactionDate,
          initiatedDate: initiatedDate,
          note: metadata['note'] as String?,
          method: metadata['method'] as String?,
          qoute: metadata['qoute'] != null
              ? CashuQuote.fromJson(metadata['qoute'] as Map<String, dynamic>)
              : null,
          usedKeyset: metadata['usedKeyset'] != null
              ? CahsuKeyset.fromJson(
                  metadata['usedKeyset'] as Map<String, dynamic>)
              : null,
        );
      case WalletType.NWC:
        return NwcWalletTransaction(
          id: id,
          walletId: walletId,
          changeAmount: changeAmount,
          unit: unit,
          walletType: walletType,
          state: state,
          metadata: metadata,
          completionMsg: completionMsg,
          transactionDate: transactionDate,
          initiatedDate: initiatedDate,
        );
    }
  }
}

class CashuWalletTransaction extends WalletTransaction {
  String mintUrl;
  String? note;
  String? method;
  CashuQuote? qoute;
  CahsuKeyset? usedKeyset;

  CashuWalletTransaction({
    required super.id,
    required super.walletId,
    required super.changeAmount,
    required super.unit,
    required super.walletType,
    required super.state,
    required this.mintUrl,
    super.completionMsg,
    this.note,
    this.method,
    this.qoute,
    this.usedKeyset,
    super.transactionDate,
    super.initiatedDate,
    Map<String, dynamic>? metadata,
  }) : super(
          metadata: metadata ??
              {
                'mintUrl': mintUrl,
                'note': note,
                'method': method,
                'qoute': qoute?.toJson(),
                'usedKeyset': usedKeyset?.toJson(),
              },
        );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CashuWalletTransaction &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  CashuWalletTransaction copyWith({
    String? id,
    String? walletId,
    int? changeAmount,
    String? unit,
    WalletType? walletType,
    WalletTransactionState? state,
    String? mintUrl,
    String? note,
    String? method,
    CashuQuote? qoute,
    CahsuKeyset? usedKeyset,
    int? transactionDate,
    int? initiatedDate,
    String? completionMsg,
  }) {
    return CashuWalletTransaction(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      changeAmount: changeAmount ?? this.changeAmount,
      unit: unit ?? this.unit,
      walletType: walletType ?? this.walletType,
      state: state ?? this.state,
      mintUrl: mintUrl ?? this.mintUrl,
      note: note ?? this.note,
      method: method ?? this.method,
      qoute: qoute ?? this.qoute,
      usedKeyset: usedKeyset ?? this.usedKeyset,
      transactionDate: transactionDate ?? this.transactionDate,
      initiatedDate: initiatedDate ?? this.initiatedDate,
      completionMsg: completionMsg ?? this.completionMsg,
    );
  }
}

class NwcWalletTransaction extends WalletTransaction {
  NwcWalletTransaction({
    required super.id,
    required super.walletId,
    required super.changeAmount,
    required super.unit,
    required super.walletType,
    required super.state,
    required super.metadata,
    super.completionMsg,
    super.transactionDate,
    super.initiatedDate,
  });
}

enum WalletTransactionState {
  /// pending states

  /// draft requires user confirmation
  draft('DRAFT'),

  /// payment is in flight
  pending('PENDING'),

  /// done states
  /// transaction went through
  completed('SUCCESS'),

  /// canceld by user - usually a canceld draft, or not sufficient funds
  canceled('CANCELED'),

  /// transaction failed
  failed('FAILED');

  bool get isPending => this == draft || this == pending;

  bool get isDone => this == completed || this == canceled || this == failed;

  final String value;

  const WalletTransactionState(this.value);

  factory WalletTransactionState.fromValue(String value) {
    return WalletTransactionState.values.firstWhere(
      (state) => state.value == value,
      orElse: () =>
          throw ArgumentError('Invalid pending transaction state: $value'),
    );
  }
}
