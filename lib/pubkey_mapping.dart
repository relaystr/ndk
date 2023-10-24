import 'package:dart_ndk/nips/nip65/read_write_marker.dart';
import 'package:isar/isar.dart';

part 'pubkey_mapping.g.dart';

/// maps the direction for a pubkey read, write, both
@embedded
class PubkeyMapping {
  String pubKey;

  ReadWriteMarker rwMarker;

  PubkeyMapping({
    required this.pubKey,
    required this.rwMarker,
  });

  // coverage:ignore-start
  @override
  String toString() {
    String result = '$pubKey ';
    if (rwMarker == ReadWriteMarker.readOnly) {
      result += "(read)";
    }
    if (rwMarker == ReadWriteMarker.writeOnly) {
      result += "(write)";
    }
    return result;
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is PubkeyMapping && runtimeType == other.runtimeType && pubKey == other.pubKey;

  @override
  int get hashCode => pubKey.hashCode;

// coverage:ignore-end

}
