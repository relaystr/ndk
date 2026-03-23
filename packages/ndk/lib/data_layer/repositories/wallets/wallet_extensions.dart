import 'package:ndk/entities.dart';

extension WalletTransactionExtension on WalletTransaction {
  Map<String, Object?> toJsonForStorage() {
    return {
      'id': id,
      'walletId': walletId,
      'changeAmount': changeAmount,
      'unit': unit,
      'walletType': walletType.toString(),
      'state': state.value,
      'completionMsg': completionMsg,
      'transactionDate': transactionDate,
      'initiatedDate': initiatedDate,
      'metadata': metadata,
    };
  }

  static WalletTransaction fromJsonStorage(Map<String, Object?> json) {
    return WalletTransaction.toTransactionType(
      id: json['id'] as String,
      walletId: json['walletId'] as String,
      changeAmount: json['changeAmount'] as int,
      unit: json['unit'] as String,
      walletType: WalletType.values.firstWhere(
        (e) => e.toString() == json['walletType'],
      ),
      state: WalletTransactionState.fromValue(json['state'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      completionMsg: json['completionMsg'] as String?,
      transactionDate: json['transactionDate'] as int?,
      initiatedDate: json['initiatedDate'] as int?,
    );
  }
}

extension WalletExtension on Wallet {
  Map<String, Object?> toJsonForStorage() {
    return {
      'id': id,
      'name': name,
      'type': type.toString(),
      'supportedUnits': supportedUnits.toList(),
      'metadata': metadata,
    };
  }

  static Wallet fromJsonStorage(Map<String, Object?> json) {
    return WalletFactory.fromStorage(
      id: json['id'] as String,
      name: json['name'] as String,
      type: WalletType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      supportedUnits: Set<String>.from(json['supportedUnits'] as List),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }
}
