import 'package:objectbox/objectbox.dart';
import 'package:ndk/entities.dart' as ndk_entities;

@Entity()
class DbWalletCahsuKeyset {
  @Id()
  int dbId = 0;

  @Property()
  String id;

  @Property()
  String mintUrl;

  @Property()
  String unit;
  @Property()
  bool active;

  @Property()
  int inputFeePPK;

  @Property()
  List<String> mintKeyPairs;

  @Property()
  int? fetchedAt;

  DbWalletCahsuKeyset({
    required this.id,
    required this.mintUrl,
    required this.unit,
    required this.active,
    required this.inputFeePPK,
    required this.mintKeyPairs,
    this.fetchedAt,
  });

  factory DbWalletCahsuKeyset.fromNdk(ndk_entities.WalletCahsuKeyset ndkM) {
    final dbM = DbWalletCahsuKeyset(
      id: ndkM.id,
      mintUrl: ndkM.mintUrl,
      unit: ndkM.unit,
      active: ndkM.active,
      inputFeePPK: ndkM.inputFeePPK,
      mintKeyPairs: ndkM.mintKeyPairs
          .map((pair) => '${pair.amount}:${pair.pubkey}')
          .toList(),
      fetchedAt:
          ndkM.fetchedAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    return dbM;
  }

  ndk_entities.WalletCahsuKeyset toNdk() {
    final ndkM = ndk_entities.WalletCahsuKeyset(
      id: id,
      mintUrl: mintUrl,
      unit: unit,
      active: active,
      inputFeePPK: inputFeePPK,
      mintKeyPairs: mintKeyPairs.map((pair) {
        final parts = pair.split(':');
        return ndk_entities.WalletCahsuMintKeyPair(
          amount: int.parse(parts[0]),
          pubkey: parts[1],
        );
      }).toSet(),
      fetchedAt: fetchedAt,
    );

    return ndkM;
  }
}
