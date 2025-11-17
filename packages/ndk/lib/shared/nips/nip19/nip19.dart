import 'dart:convert';

import 'package:bech32/bech32.dart';
import 'package:collection/collection.dart';
import 'package:hex/hex.dart';

import '../../logger/logger.dart';
import '../../../domain_layer/entities/naddr.dart';
import '../../../domain_layer/entities/nevent.dart';
import '../../../domain_layer/entities/nprofile.dart';
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
      var bech32Result = decoder.convert(npub, npub.length);
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

  /// Encode nevent (event reference)
  /// [eventId] - 32-byte hex event ID (required)
  /// [relays] - optional list of relay URLs where the event may be found
  /// [author] - optional 32-byte hex public key of the event author
  /// [kind] - optional event kind number
  static String encodeNevent({
    required String eventId,
    List<String>? relays,
    String? author,
    int? kind,
  }) {
    final tlvData = <int>[];

    // Type 0: event ID (special) - 32 bytes
    final eventIdBytes = HEX.decode(eventId);
    if (eventIdBytes.length != 32) {
      throw ArgumentError('Event ID must be 32 bytes (64 hex characters)');
    }
    tlvData.add(0); // type
    tlvData.add(32); // length
    tlvData.addAll(eventIdBytes); // value

    // Type 1: relays (optional, can be multiple)
    if (relays != null) {
      for (final relay in relays) {
        final relayBytes = utf8.encode(relay);
        if (relayBytes.length > 255) {
          throw ArgumentError(
              'Relay URL too long: ${relay.length} bytes (max 255)');
        }
        tlvData.add(1); // type
        tlvData.add(relayBytes.length); // length
        tlvData.addAll(relayBytes); // value
      }
    }

    // Type 2: author pubkey (optional, 32 bytes)
    if (author != null) {
      final authorBytes = HEX.decode(author);
      if (authorBytes.length != 32) {
        throw ArgumentError(
            'Author pubkey must be 32 bytes (64 hex characters)');
      }
      tlvData.add(2); // type
      tlvData.add(32); // length
      tlvData.addAll(authorBytes); // value
    }

    // Type 3: kind (optional, 32-bit unsigned big-endian)
    if (kind != null) {
      final kindBytes = [
        (kind >> 24) & 0xFF,
        (kind >> 16) & 0xFF,
        (kind >> 8) & 0xFF,
        kind & 0xFF,
      ];
      tlvData.add(3); // type
      tlvData.add(4); // length (32-bit = 4 bytes)
      tlvData.addAll(kindBytes); // value
    }

    // Convert to bech32
    final data = convertBits(tlvData, 8, 5, true);
    var encoder = Bech32Encoder();
    Bech32 input = Bech32(Hrps.kNevent, data);
    var encoded = encoder.convert(input, input.hrp.length + data.length + 10);
    return encoded;
  }

  /// Encode naddr (addressable event coordinate)
  /// [identifier] - the "d" tag value (empty string for normal replaceable events)
  /// [pubkey] - 32-byte hex public key of the event author (required)
  /// [kind] - event kind number (required)
  /// [relays] - optional list of relay URLs where the event may be found
  static String encodeNaddr({
    required String identifier,
    required String pubkey,
    required int kind,
    List<String>? relays,
  }) {
    final tlvData = <int>[];

    // Type 0: identifier (special) - UTF-8 encoded string
    final identifierBytes = utf8.encode(identifier);
    tlvData.add(0); // type
    tlvData.add(identifierBytes.length); // length
    tlvData.addAll(identifierBytes); // value

    // Type 1: relays (optional, can be multiple)
    if (relays != null) {
      for (final relay in relays) {
        final relayBytes = utf8.encode(relay);
        if (relayBytes.length > 255) {
          throw ArgumentError(
              'Relay URL too long: ${relay.length} bytes (max 255)');
        }
        tlvData.add(1); // type
        tlvData.add(relayBytes.length); // length
        tlvData.addAll(relayBytes); // value
      }
    }

    // Type 2: author pubkey (required, 32 bytes)
    final pubkeyBytes = HEX.decode(pubkey);
    if (pubkeyBytes.length != 32) {
      throw ArgumentError('Public key must be 32 bytes (64 hex characters)');
    }
    tlvData.add(2); // type
    tlvData.add(32); // length
    tlvData.addAll(pubkeyBytes); // value

    // Type 3: kind (required, 32-bit unsigned big-endian)
    final kindBytes = [
      (kind >> 24) & 0xFF,
      (kind >> 16) & 0xFF,
      (kind >> 8) & 0xFF,
      kind & 0xFF,
    ];
    tlvData.add(3); // type
    tlvData.add(4); // length (32-bit = 4 bytes)
    tlvData.addAll(kindBytes); // value

    // Convert to bech32
    final data = convertBits(tlvData, 8, 5, true);
    var encoder = Bech32Encoder();
    Bech32 input = Bech32(Hrps.kNaddr, data);
    var encoded = encoder.convert(input, input.hrp.length + data.length + 10);
    return encoded;
  }

  /// Encode nprofile (profile reference)
  /// [pubkey] - 32-byte hex public key (required)
  /// [relays] - optional list of relay URLs where the profile may be found
  static String encodeNprofile({
    required String pubkey,
    List<String>? relays,
  }) {
    final tlvData = <int>[];

    // Type 0: pubkey (special) - 32 bytes
    final pubkeyBytes = HEX.decode(pubkey);
    if (pubkeyBytes.length != 32) {
      throw ArgumentError('Public key must be 32 bytes (64 hex characters)');
    }
    tlvData.add(0); // type
    tlvData.add(32); // length
    tlvData.addAll(pubkeyBytes); // value

    // Type 1: relays (optional, can be multiple)
    if (relays != null) {
      for (final relay in relays) {
        final relayBytes = utf8.encode(relay);
        if (relayBytes.length > 255) {
          throw ArgumentError(
              'Relay URL too long: ${relay.length} bytes (max 255)');
        }
        tlvData.add(1); // type
        tlvData.add(relayBytes.length); // length
        tlvData.addAll(relayBytes); // value
      }
    }

    // Convert to bech32
    final data = convertBits(tlvData, 8, 5, true);
    var encoder = Bech32Encoder();
    Bech32 input = Bech32(Hrps.kNprofile, data);
    var encoded = encoder.convert(input, input.hrp.length + data.length + 10);
    return encoded;
  }

  /// Decode nprofile and return Nprofile object
  static Nprofile decodeNprofile(String nprofileStr) {
    var decoder = Bech32Decoder();
    var bech32Result = decoder.convert(nprofileStr, nprofileStr.length);

    if (bech32Result.hrp != Hrps.kNprofile) {
      throw ArgumentError(
          "Invalid HRP: expected '${Hrps.kNprofile}', got '${bech32Result.hrp}'");
    }

    var data = convertBits(bech32Result.data, 5, 8, false);
    final tlv = Nip19TLV.parseTLV(data);

    String? pubkey;
    List<String> relays = [];

    for (var t in tlv) {
      switch (t.type) {
        case 0: // pubkey (special)
          if (t.value.length == 32) {
            pubkey = HEX.encode(t.value);
          }
          break;
        case 1: // relay
          try {
            relays.add(utf8.decode(t.value));
          } catch (e) {
            // Ignore invalid UTF-8 per spec
          }
          break;
        default:
          // Ignore unrecognized TLV types per spec
          break;
      }
    }

    // Validate required fields
    if (pubkey == null) {
      throw ArgumentError('Missing required pubkey field (type 0)');
    }

    return Nprofile(
      pubkey: pubkey,
      relays: relays.isEmpty ? null : relays,
    );
  }

  /// Decode nevent and return Nevent object
  static Nevent decodeNevent(String neventStr) {
    var decoder = Bech32Decoder();
    var bech32Result = decoder.convert(neventStr, neventStr.length);

    if (bech32Result.hrp != Hrps.kNevent) {
      throw ArgumentError(
          "Invalid HRP: expected '${Hrps.kNevent}', got '${bech32Result.hrp}'");
    }

    var data = convertBits(bech32Result.data, 5, 8, false);
    final tlv = Nip19TLV.parseTLV(data);

    String? eventId;
    List<String> relays = [];
    String? author;
    int? kind;

    for (var t in tlv) {
      switch (t.type) {
        case 0: // event id (special)
          if (t.value.length == 32) {
            eventId = HEX.encode(t.value);
          }
          break;
        case 1: // relay
          try {
            relays.add(utf8.decode(t.value));
          } catch (e) {
            // Ignore invalid UTF-8 per spec
          }
          break;
        case 2: // author pubkey
          if (t.value.length == 32) {
            author = HEX.encode(t.value);
          }
          break;
        case 3: // kind
          if (t.value.length == 4) {
            kind = (t.value[0] << 24) |
                (t.value[1] << 16) |
                (t.value[2] << 8) |
                t.value[3];
          }
          break;
        default:
          // Ignore unrecognized TLV types per spec
          break;
      }
    }

    // Validate required fields
    if (eventId == null) {
      throw ArgumentError('Missing required event ID field (type 0)');
    }

    return Nevent(
      eventId: eventId,
      author: author,
      kind: kind,
      relays: relays.isEmpty ? null : relays,
    );
  }

  /// Decode naddr and return Naddr object
  static Naddr decodeNaddr(String naddrStr) {
    var decoder = Bech32Decoder();
    var bech32Result = decoder.convert(naddrStr, naddrStr.length);

    if (bech32Result.hrp != Hrps.kNaddr) {
      throw ArgumentError(
          "Invalid HRP: expected '${Hrps.kNaddr}', got '${bech32Result.hrp}'");
    }

    var data = convertBits(bech32Result.data, 5, 8, false);
    final tlv = Nip19TLV.parseTLV(data);

    String? identifier;
    List<String> relays = [];
    String? pubkey;
    int? kind;

    for (var t in tlv) {
      switch (t.type) {
        case 0: // identifier
          try {
            identifier = utf8.decode(t.value);
          } catch (e) {
            // Ignore invalid UTF-8 per spec
          }
          break;
        case 1: // relay
          try {
            relays.add(utf8.decode(t.value));
          } catch (e) {
            // Ignore invalid UTF-8 per spec
          }
          break;
        case 2: // author pubkey
          if (t.value.length == 32) {
            pubkey = HEX.encode(t.value);
          }
          break;
        case 3: // kind
          if (t.value.length == 4) {
            kind = (t.value[0] << 24) |
                (t.value[1] << 16) |
                (t.value[2] << 8) |
                t.value[3];
          }
          break;
        default:
          // Ignore unrecognized TLV types per spec
          break;
      }
    }

    // Validate required fields
    if (identifier == null) {
      throw ArgumentError('Missing required identifier field (type 0)');
    }
    if (pubkey == null) {
      throw ArgumentError('Missing required author pubkey field (type 2)');
    }
    if (kind == null) {
      throw ArgumentError('Missing required kind field (type 3)');
    }

    return Naddr(
      identifier: identifier,
      pubkey: pubkey,
      kind: kind,
      relays: relays.isEmpty ? null : relays,
    );
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
