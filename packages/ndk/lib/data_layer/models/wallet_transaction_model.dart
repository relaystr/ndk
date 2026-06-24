import '../../domain_layer/entities/cashu/cashu_keyset.dart';
import '../../domain_layer/entities/cashu/cashu_quote.dart';
import '../../domain_layer/entities/cashu/cashu_quote_melt.dart';
import '../../domain_layer/entities/wallet/wallet_transaction.dart';
import '../../domain_layer/entities/wallet/wallet_type.dart';

/// A helper model for wallet transaction JSON serialization and deserialization.
///
class WalletTransactionModel {
  WalletTransactionModel._();

  /// Deserializes a wallet transaction from JSON.
  static WalletTransaction fromJson(Map<String, dynamic> json) {
    final walletType = WalletType.fromValue(json['walletType'] as String);

    switch (walletType) {
      case WalletType.CASHU:
        return CashuWalletTransactionModel.fromJson(json);
      case WalletType.NWC:
        return NwcWalletTransactionModel.fromJson(json);
      case WalletType.LNURL:
        return LnurlWalletTransactionModel.fromJson(json);
    }
  }

  /// Converts a domain wallet transaction to a serializable JSON map.
  static Map<String, dynamic> toJson(WalletTransaction transaction) {
    if (transaction is CashuWalletTransaction) {
      return CashuWalletTransactionModel.fromEntity(transaction).toJson();
    }
    if (transaction is NwcWalletTransaction) {
      return NwcWalletTransactionModel.fromEntity(transaction).toJson();
    }
    if (transaction is LnurlWalletTransaction) {
      return LnurlWalletTransactionModel.fromEntity(transaction).toJson();
    }

    return _baseJson(transaction);
  }

  /// Converts a domain transaction into the corresponding model variant.
  static WalletTransaction fromEntity(WalletTransaction transaction) {
    if (transaction is CashuWalletTransaction) {
      return CashuWalletTransactionModel.fromEntity(transaction);
    }
    if (transaction is NwcWalletTransaction) {
      return NwcWalletTransactionModel.fromEntity(transaction);
    }
    if (transaction is LnurlWalletTransaction) {
      return LnurlWalletTransactionModel.fromEntity(transaction);
    }
    return transaction;
  }

  static Map<String, dynamic> _baseJson(WalletTransaction transaction) {
    return {
      'id': transaction.id,
      'walletId': transaction.walletId,
      'changeAmount': transaction.changeAmount,
      'unit': transaction.unit,
      'walletType': transaction.walletType.toString(),
      'state': transaction.state.value,
      'completionMsg': transaction.completionMsg,
      'transactionDate': transaction.transactionDate,
      'initiatedDate': transaction.initiatedDate,
      'metadata': transaction.metadata,
    };
  }
}

class CashuWalletTransactionModel extends CashuWalletTransaction {
  CashuWalletTransactionModel({
    required super.id,
    required super.walletId,
    required super.changeAmount,
    required super.unit,
    required super.walletType,
    required super.state,
    required super.mintUrl,
    super.completionMsg,
    super.transactionDate,
    super.initiatedDate,
    super.note,
    super.method,
    super.qoute,
    super.qouteMelt,
    super.usedKeysets,
    super.token,
    super.proofPubKeys,
    super.metadata,
  });

  factory CashuWalletTransactionModel.fromEntity(
    CashuWalletTransaction transaction,
  ) {
    return CashuWalletTransactionModel(
      id: transaction.id,
      walletId: transaction.walletId,
      changeAmount: transaction.changeAmount,
      unit: transaction.unit,
      walletType: transaction.walletType,
      state: transaction.state,
      mintUrl: transaction.mintUrl,
      note: transaction.note,
      method: transaction.method,
      qoute: transaction.qoute,
      qouteMelt: transaction.qouteMelt,
      usedKeysets: transaction.usedKeysets,
      token: transaction.token,
      proofPubKeys: transaction.proofPubKeys,
      completionMsg: transaction.completionMsg,
      transactionDate: transaction.transactionDate,
      initiatedDate: transaction.initiatedDate,
      metadata: transaction.metadata,
    );
  }

  factory CashuWalletTransactionModel.fromJson(Map<String, dynamic> json) {
    final metadata = Map<String, dynamic>.from(json['metadata'] as Map? ?? {});

    final rawQuote = json['qoute'] as Map<String, dynamic>? ??
        metadata['qoute'] as Map<String, dynamic>?;
    final rawQuoteMelt = json['qouteMelt'] as Map<String, dynamic>? ??
        metadata['qouteMelt'] as Map<String, dynamic>?;

    final rawUsedKeysets = json['usedKeysets'] as List<dynamic>? ??
        metadata['usedKeyset'] as List<dynamic>? ??
        metadata['usedKeysets'] as List<dynamic>?;

    final rawProofPubKeys = json['proofPubKeys'] as List<dynamic>? ??
        metadata['proofPubKeys'] as List<dynamic>?;

    return CashuWalletTransactionModel(
      id: json['id'] as String,
      walletId: json['walletId'] as String,
      changeAmount: json['changeAmount'] as int,
      unit: json['unit'] as String,
      walletType: WalletType.fromValue(json['walletType'] as String),
      state: WalletTransactionState.fromValue(json['state'] as String),
      completionMsg: json['completionMsg'] as String?,
      transactionDate: json['transactionDate'] as int?,
      initiatedDate: json['initiatedDate'] as int?,
      mintUrl: json['mintUrl'] as String? ?? metadata['mintUrl'] as String,
      note: json['note'] as String? ?? metadata['note'] as String?,
      method: json['method'] as String? ?? metadata['method'] as String?,
      qoute: rawQuote != null ? CashuQuote.fromJson(rawQuote) : null,
      qouteMelt:
          rawQuoteMelt != null ? CashuQuoteMelt.fromJson(rawQuoteMelt) : null,
      usedKeysets: rawUsedKeysets
          ?.map((entry) => CahsuKeyset.fromJson(entry as Map<String, dynamic>))
          .toList(),
      token: json['token'] as String? ?? metadata['token'] as String?,
      proofPubKeys: rawProofPubKeys?.map((entry) => entry.toString()).toList(),
      metadata: metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ...WalletTransactionModel._baseJson(this),
      'metadata': metadata,
    };
  }
}

class NwcWalletTransactionModel extends NwcWalletTransaction {
  NwcWalletTransactionModel({
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

  factory NwcWalletTransactionModel.fromEntity(
    NwcWalletTransaction transaction,
  ) {
    return NwcWalletTransactionModel(
      id: transaction.id,
      walletId: transaction.walletId,
      changeAmount: transaction.changeAmount,
      unit: transaction.unit,
      walletType: transaction.walletType,
      state: transaction.state,
      metadata: transaction.metadata,
      completionMsg: transaction.completionMsg,
      transactionDate: transaction.transactionDate,
      initiatedDate: transaction.initiatedDate,
    );
  }

  factory NwcWalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return NwcWalletTransactionModel(
      id: json['id'] as String,
      walletId: json['walletId'] as String,
      changeAmount: json['changeAmount'] as int,
      unit: json['unit'] as String,
      walletType: WalletType.fromValue(json['walletType'] as String),
      state: WalletTransactionState.fromValue(json['state'] as String),
      completionMsg: json['completionMsg'] as String?,
      transactionDate: json['transactionDate'] as int?,
      initiatedDate: json['initiatedDate'] as int?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ...WalletTransactionModel._baseJson(this),
      'metadata': metadata,
    };
  }
}

class LnurlWalletTransactionModel extends LnurlWalletTransaction {
  LnurlWalletTransactionModel({
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

  factory LnurlWalletTransactionModel.fromEntity(
    LnurlWalletTransaction transaction,
  ) {
    return LnurlWalletTransactionModel(
      id: transaction.id,
      walletId: transaction.walletId,
      changeAmount: transaction.changeAmount,
      unit: transaction.unit,
      walletType: transaction.walletType,
      state: transaction.state,
      metadata: transaction.metadata,
      completionMsg: transaction.completionMsg,
      transactionDate: transaction.transactionDate,
      initiatedDate: transaction.initiatedDate,
    );
  }

  factory LnurlWalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return LnurlWalletTransactionModel(
      id: json['id'] as String,
      walletId: json['walletId'] as String,
      changeAmount: json['changeAmount'] as int,
      unit: json['unit'] as String,
      walletType: WalletType.fromValue(json['walletType'] as String),
      state: WalletTransactionState.fromValue(json['state'] as String),
      completionMsg: json['completionMsg'] as String?,
      transactionDate: json['transactionDate'] as int?,
      initiatedDate: json['initiatedDate'] as int?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ...WalletTransactionModel._baseJson(this),
      'metadata': metadata,
    };
  }
}
