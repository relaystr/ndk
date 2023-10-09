/// maps the direction for a pubkey read, write, both
class PubkeyMapping {
  String pubKey;

  /// if marker is missing it means both read && write
  ReadWriteMarker rwMarker;

  PubkeyMapping({
    required this.pubKey,
    required this.rwMarker,
  });

  bool isRead() {
    return rwMarker == ReadWriteMarker.read;
  }

  bool isWrite() {
    return rwMarker == ReadWriteMarker.write;
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

enum ReadWriteMarker { read, write, readWrite }
