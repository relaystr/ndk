/// is a mapping of a relay url to a list of pubkey mappings
class RelayPubkeyMapping {
// todo: think about scoring according to nip65 nip05 kind03 etc

  String relayUrl;


  List<PubkeyMapping> pubKeyMappings = [];

  bool isPubKeyForRead(String pubKey) {
    return pubKeyMappings.any((pubKeyMapping) => pubKey == pubKeyMapping.pubKey && pubKeyMapping.isRead());
  }

  bool isPubKeyForWrite(String pubKey) {
    return pubKeyMappings.any((pubKeyMapping) => pubKey == pubKeyMapping.pubKey && pubKeyMapping.isWrite());
  }

  RelayPubkeyMapping({
    required this.relayUrl,
    required this.pubKeyMappings,
  });
}

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
}

class ReadWriteMarker {
  bool read;
  bool write;
  ReadWriteMarker({this.read = false, this.write = false});
}


/// 
/// what happens if relay go down? and comes up? how do we make active subrscriptions to that relay again?