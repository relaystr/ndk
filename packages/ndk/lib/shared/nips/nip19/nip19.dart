import 'package:bech32/bech32.dart';
import 'package:collection/collection.dart';
import 'package:hex/hex.dart';

import '../../logger/logger.dart';
import 'hrps.dart';

class Nip19 {
  // static String encodePubKey(String pubKey) {
  //   var data = hex.decode(pubKey);
  //   data = Bech32.convertBits(data, 8, 5, true);
  //   return Bech32.encode(Hrps.PUBLIC_KEY, data);
  // }
  static const int kNpubLength = 63;
  static const int kNoteIdLength = 63;

  static RegExp nip19regex = RegExp(
      r'@?(nostr:)?@?(nsec1|npub1|nevent1|naddr1|note1|nprofile1|nrelay1)([qpzry9x8gf2tvdw0s3jn54khce6mua7l]+)([\\S]*)',
      caseSensitive: false);

  static bool isNip19(String str) {
    return nip19regex.firstMatch(str) != null;
  }

  static bool isKey(String hrp, String str) {
    if (str.indexOf(hrp) == 0) {
      return true;
    } else {
      return false;
    }
  }

  static bool isPubkey(String str) {
    return isKey(Hrps.kPublicKey, str);
  }

  static String encodePubKey(String pubkey) {
    // var data = HEX.decode(pubKey);
    // data = _convertBits(data, 8, 5, true);

    // var encoder = Bech32Encoder();
    // Bech32 input = Bech32(Hrps.PUBLIC_KEY, data);
    // return encoder.convert(input);
    return _encodeKey(Hrps.kPublicKey, pubkey);
  }

  static String encodeSimplePubKey(String pubKey) {
    try {
      var code = encodePubKey(pubKey);
      var length = code.length;
      return "${code.substring(0, 10)}:${code.substring(length - 10)}";
    } catch (e) {
      return pubKey;
    }
  }

  // static String decode(String npub) {
  //   var res = Bech32.decode(npub);
  //   var data = Bech32.convertBits(res.words, 5, 8, false);
  //   return hex.encode(data).substring(0, 64);
  // }
  static String decode(String npub) {
    try {
      var decoder = Bech32Decoder();
      var bech32Result = decoder.convert(npub);
      var data = convertBits(bech32Result.data, 5, 8, false);
      if (bech32Result.hrp != Hrps.kNoteId &&
          bech32Result.hrp != Hrps.kPublicKey &&
          bech32Result.hrp != Hrps.kPrivateKey) {
        final tlv = Nip19TLV.parseTLV(data);
        final special = tlv.firstWhereOrNull((t) => t.type == 0)?.value;
        if (special != null) {
          return HEX.encode(special);
        } else {
          throw "Missing 'special' kind in TLV entity, cant decode to hex";
        }
      } else {
        return HEX.encode(data);
      }
    } catch (e) {
      Logger.log.e("Nip19 decode error ${e.toString()}");
      return "";
    }
  }

  static String _encodeKey(String hrp, String key) {
    var data = HEX.decode(key);
    data = convertBits(data, 8, 5, true);

    var encoder = Bech32Encoder();
    Bech32 input = Bech32(hrp, data);
    return encoder.convert(input);
  }

  static bool isPrivateKey(String str) {
    return isKey(Hrps.kPrivateKey, str);
  }

  static String encodePrivateKey(String pubkey) {
    return _encodeKey(Hrps.kPrivateKey, pubkey);
  }

  static bool isNoteId(String str) {
    return isKey(Hrps.kNoteId, str);
  }

  /// encode note id
  static String encodeNoteId(String id) {
    return _encodeKey(Hrps.kNoteId, id);
  }

  static List<int> convertBits(List<int> data, int from, int to, bool pad) {
    var acc = 0;
    var bits = 0;
    var result = <int>[];
    var maxv = (1 << to) - 1;

    for (var v in data) {
      if (v < 0 || (v >> from) != 0) {
        throw Exception();
      }
      acc = (acc << from) | v;
      bits += from;
      while (bits >= to) {
        bits -= to;
        result.add((acc >> bits) & maxv);
      }
    }

    if (pad) {
      if (bits > 0) {
        result.add((acc << (to - bits)) & maxv);
      }
    } else if (bits >= from) {
      throw InvalidPadding('illegal zero padding');
    } else if (((acc << (to - bits)) & maxv) != 0) {
      throw InvalidPadding('non zero');
    }

    return result;
  }
}

class Nip19TLV {
  final int type;
  final int length;
  final List<int> value;

  Nip19TLV(this.type, this.length, this.value);

  static List<Nip19TLV> parseTLV(List<int> data) {
    List<Nip19TLV> result = [];
    int index = 0;

    while (index < data.length) {
      // Check if we have enough bytes for type and length
      if (index + 2 > data.length) {
        throw FormatException('Incomplete TLV data');
      }

      // Read type (1 byte)
      int type = data[index];
      index++;

      // Read length (1 byte)
      int length = data[index];
      index++;

      // Check if we have enough bytes for value
      if (index + length > data.length) {
        throw FormatException('TLV value length exceeds available data');
      }

      // Read value
      List<int> value = data.sublist(index, index + length);
      index += length;

      result.add(Nip19TLV(type, length, value));
    }

    return result;
  }
}
