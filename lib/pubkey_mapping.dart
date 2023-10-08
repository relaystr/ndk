/// maps the direction for a pubkey read, write, both
class PubkeyMapping {

  String pubKey;

  /// if marker is missing it means both read && write
  ReadWriteMarker? rwMarker;

  PubkeyMapping({
    required this.pubKey,
    this.rwMarker,
  });

  bool isRead() {
    if (rwMarker == null) return true;
    return rwMarker!.read;
  }

  bool isWrite() {
    if (rwMarker == null) return true;
    return rwMarker!.write;
  }

  // @override
  // bool operator ==(Object other) =>
  //     identical(this, other) ||
  //     other is PubkeyMapping &&
  //         runtimeType == other.runtimeType &&
  //         pubKey == other.pubKey;
  //
  // @override
  // int get hashCode => pubKey.hashCode;
}

class ReadWriteMarker {
  bool read;
  bool write;
  ReadWriteMarker({this.read = false, this.write = false});
}
