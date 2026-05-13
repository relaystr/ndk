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

  @Property()
  String state;

  DbWalletCashuProof({
    required this.keysetId,
    required this.amount,
    required this.secret,
    required this.unblindedSig,
    required this.state,
  });

  factory DbWalletCashuProof.fromNdk(ndk_entities.CashuProof ndkM) {
    final dbM = DbWalletCashuProof(
      keysetId: ndkM.keysetId,
      amount: ndkM.amount,
      secret: ndkM.secret,
      unblindedSig: ndkM.unblindedSig,
      state: ndkM.state.toString(),
    );

    return dbM;
  }

  ndk_entities.CashuProof toNdk() {
    final ndkM = ndk_entities.CashuProof(
      keysetId: keysetId,
      amount: amount,
      secret: secret,
      unblindedSig: unblindedSig,
      state: ndk_entities.CashuProofState.fromValue(state),
    );

    return ndkM;
  }
}
