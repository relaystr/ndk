import 'package:ndk/entities.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class DbNip05 {
  DbNip05({
    required this.pubKey,
    required this.nip05,
    required this.valid,
    required this.networkFetchTime,
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
  int? networkFetchTime;

  Nip05 toNdk() {
    final ndkM = Nip05(
      pubKey: pubKey,
      nip05: nip05,
      valid: valid,
      networkFetchTime: networkFetchTime,
    );

    return ndkM;
  }

  factory DbNip05.fromNdk(Nip05 ndkM) {
    final dbM = DbNip05(
      pubKey: ndkM.pubKey,
      nip05: ndkM.nip05,
      valid: ndkM.valid,
      networkFetchTime: ndkM.networkFetchTime,
    );
    return dbM;
  }

}