import '../cashu/cashu_keyset.dart';
import '../cashu/cashu_quote.dart';
import 'wallet_type.dart';

abstract class WalletTransaction {
  final String id;
  final String walletId;
  int changeAmount;
  String unit;
  WalletType walletType;
  WalletTransactionState state;
  String? completionMsg;

  /// Date in milliseconds since epoch
  int? transactionDate;

  /// Date in milliseconds since epoch
  int? initiatedDate;

  WalletTransaction({
    required this.id,
    required this.walletId,
    required this.changeAmount,
    required this.unit,
    required this.walletType,
    required this.state,
    this.completionMsg,
    this.transactionDate,
    this.initiatedDate,
  });
}

class CashuWalletTransaction extends WalletTransaction {
  String mintUrl;
  String? note;
  CashuQuote? qoute;
  String? method;
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
  });

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
