import 'dart:convert';

import 'package:objectbox/objectbox.dart';
import 'package:ndk/entities.dart' as ndk_entities;

@Entity()
class DbWalletTransaction {
  @Id()
  int dbId = 0;

  @Property()
  String id;

  @Property()
  String walletId;

  @Property()
  int changeAmount;

  @Property()
  String unit;

  @Property()
  String walletType;

  @Property()
  String state;

  @Property()
  String? completionMsg;

  @Property()
  int? transactionDate;
  @Property()
  int? initiatedDate;

  @Property()
  String metadataJsonString;

  DbWalletTransaction({
    required this.id,
    required this.walletId,
    required this.changeAmount,
    required this.unit,
    required this.walletType,
    required this.state,
    this.completionMsg,
    this.transactionDate,
    this.initiatedDate,
    required this.metadataJsonString,
  });

  factory DbWalletTransaction.fromNdk(ndk_entities.WalletTransaction ndkM) {
    final dbM = DbWalletTransaction(
        id: ndkM.id,
        walletId: ndkM.walletId,
        changeAmount: ndkM.changeAmount,
        unit: ndkM.unit,
        walletType: ndkM.walletType.toString(),
        state: ndkM.state.toString(),
        completionMsg: ndkM.completionMsg,
        transactionDate: ndkM.transactionDate,
        initiatedDate: ndkM.initiatedDate,
        // Note: metadata is stored as a JSON string
        metadataJsonString: jsonEncode(ndkM.metadata));

    return dbM;
  }

  ndk_entities.WalletTransaction toNdk() {
    final ndkM = ndk_entities.WalletTransaction.toTransactionType(
      id: id,
      walletId: walletId,
      changeAmount: changeAmount,
      unit: unit,
      walletType: ndk_entities.WalletType.fromValue(walletType),
      state: ndk_entities.WalletTransactionState.fromValue(state),
      completionMsg: completionMsg,
      transactionDate: transactionDate,
      initiatedDate: initiatedDate,
      metadata: jsonDecode(metadataJsonString) as Map<String, dynamic>,
    );

    return ndkM;
  }
}
