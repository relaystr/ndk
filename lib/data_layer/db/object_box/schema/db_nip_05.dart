import 'package:objectbox/objectbox.dart';

import '../../../../shared/nips/nip05/nip05.dart';

@Entity()
class DbNip05 {
  DbNip05({
    required this.pubKey,
    required this.nip05,
    required this.valid,
    required this.updatedAt,
    int createdAt = 0,
  });

  @Id()
  int dbId = 0;

  @Property()
  String pubKey;

  @Property()
  String nip05;

  @Property()
  bool valid;

  @Property()
  int updatedAt;

  Nip05 toNdk() {
    final ndkM = Nip05(
      pubKey: pubKey,
      nip05: nip05,
      valid: valid,
      updatedAt: updatedAt,
    );

    return ndkM;
  }

  factory DbNip05.fromNdk(Nip05 ndkM) {
    final dbM = DbNip05(
      pubKey: ndkM.pubKey,
      nip05: ndkM.nip05,
      valid: ndkM.valid,
      updatedAt: ndkM.updatedAt,
    );
    return dbM;
  }

}