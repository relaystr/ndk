import 'package:dart_ndk/models/pubkey_mapping.dart';
import 'package:dart_ndk/nips/nip65/read_write_marker.dart';
import 'package:isar/isar.dart';

part 'db_pubkey_mapping.g.dart';

@Embedded(inheritance: false)
class DbPubkeyMapping extends PubkeyMapping {
  @override
  String get pubKey => super.pubKey;

  String get marker => super.rwMarker.name;

  DbPubkeyMapping({required super.pubKey, required String marker}) : super(rwMarker: fromName(marker));

  static ReadWriteMarker fromName(String name) {
    if (name == ReadWriteMarker.readOnly.name) {
      return ReadWriteMarker.readOnly;
    } else if (name == ReadWriteMarker.writeOnly.name) {
      return ReadWriteMarker.writeOnly;
    }
    return ReadWriteMarker.readWrite;
  }

}
