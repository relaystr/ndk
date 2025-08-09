import 'package:objectbox/objectbox.dart';
import 'package:ndk/entities.dart' as ndk_entities;

@Entity()
class DbWalletCashuProof {
  @Id()
  int dbId = 0;

  @Property()
  String keysetId;
  @Property()
  int amount;

  @Property()
  String secret;

  @Property()
  String unblindedSig;

  DbWalletCashuProof({
    required this.keysetId,
    required this.amount,
    required this.secret,
    required this.unblindedSig,
  });

  factory DbWalletCashuProof.fromNdk(ndk_entities.CashuProof ndkM) {
    final dbM = DbWalletCashuProof(
      keysetId: ndkM.keysetId,
      amount: ndkM.amount,
      secret: ndkM.secret,
      unblindedSig: ndkM.unblindedSig,
    );

    return dbM;
  }

  ndk_entities.CashuProof toNdk() {
    final ndkM = ndk_entities.CashuProof(
      keysetId: keysetId,
      amount: amount,
      secret: secret,
      unblindedSig: unblindedSig,
    );

    return ndkM;
  }
}
