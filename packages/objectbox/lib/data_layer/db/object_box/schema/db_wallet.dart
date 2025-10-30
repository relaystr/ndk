import 'dart:convert';

import 'package:objectbox/objectbox.dart';
import 'package:ndk/entities.dart' as ndk_entities;

@Entity()
class DbWallet {
  @Id()
  int dbId = 0;

  @Property()
  String id;

  @Property()
  String type;

  @Property()
  List<String> supportedUnits;

  @Property()
  String name;

  @Property()
  String metadataJsonString;

  DbWallet({
    required this.id,
    required this.type,
    required this.supportedUnits,
    required this.name,
    required this.metadataJsonString,
  });

  factory DbWallet.fromNdk(ndk_entities.Wallet ndkM) {
    final dbM = DbWallet(
      id: ndkM.id,
      type: ndkM.type.toString(),
      supportedUnits: ndkM.supportedUnits.toList(),
      name: ndkM.name,
      metadataJsonString: jsonEncode(ndkM.metadata),
    );

    return dbM;
  }

  ndk_entities.Wallet toNdk() {
    final ndkM = ndk_entities.Wallet.toWalletType(
      id: id,
      name: name,
      type: ndk_entities.WalletType.fromValue(type),
      supportedUnits: supportedUnits.toSet(),
      metadata: jsonDecode(metadataJsonString),
    );

    return ndkM;
  }
}
