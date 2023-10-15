import 'package:dart_ndk/nips/nip65/read_write_marker.dart';

/// maps the direction for a pubkey read, write, both
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
  // coverage:ignore-end
}
