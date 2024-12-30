import 'package:isar/isar.dart';
import 'package:ndk/entities.dart';

part 'db_nip05.g.dart';

@Collection(inheritance: true)
class DbNip05 extends Nip05 {
  String get id => pubKey;

  DbNip05(
      {required super.pubKey,
      required super.nip05,
      required super.valid,
      required super.networkFetchTime});

  static DbNip05 fromNip05(Nip05 nip05) {
    return DbNip05(
        pubKey: nip05.pubKey,
        nip05: nip05.nip05,
        valid: nip05.valid,
        networkFetchTime: nip05.networkFetchTime);
  }
}
