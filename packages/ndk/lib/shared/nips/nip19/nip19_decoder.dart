import 'dart:convert';

import 'package:bech32/bech32.dart';
import 'package:collection/collection.dart';
import 'package:convert/convert.dart';

import '../../logger/logger.dart';
import '../../../domain_layer/entities/naddr.dart';
import '../../../domain_layer/entities/nevent.dart';
import '../../../domain_layer/entities/nprofile.dart';
import 'hrps.dart';
import 'nip19_tlv.dart';
import 'nip19_utils.dart';

/// NIP-19 decoding functions
class Nip19Decoder {
  /// Decode a NIP-19 encoded string (npub, note, nevent, nprofile, naddr)
  /// Returns the decoded hex string
  static String decode(String nip19String) {
    try {
      var decoder = Bech32Decoder();
      var bech32Result = decoder.convert(nip19String, nip19String.length);
      var data = Nip19Utils.convertBits(bech32Result.data, 5, 8, false);
      if (bech32Result.hrp != Hrps.kNoteId &&
          bech32Result.hrp != Hrps.kPublicKey &&
          bech32Result.hrp != Hrps.kPrivateKey) {
        final tlv = Nip19TLV.parseTLV(data);
        final special = tlv.firstWhereOrNull((t) => t.type == 0)?.value;
        if (special != null) {
          return hex.encode(special);
        } else {
          throw "Missing 'special' kind in TLV entity, cant decode to hex";
        }
      } else {
        return hex.encode(data);
      }
    } catch (e) {
      Logger.log.e(() => "Nip19 decode error ${e.toString()}");
      return "";
    }
  }

  /// Decode nprofile and return Nprofile object
  static Nprofile decodeNprofile(String nprofileStr) {
    var decoder = Bech32Decoder();
    var bech32Result = decoder.convert(nprofileStr, nprofileStr.length);

    if (bech32Result.hrp != Hrps.kNprofile) {
      throw ArgumentError(
          "Invalid HRP: expected '${Hrps.kNprofile}', got '${bech32Result.hrp}'");
    }

    var data = Nip19Utils.convertBits(bech32Result.data, 5, 8, false);
    final tlv = Nip19TLV.parseTLV(data);

    String? pubkey;
    List<String> relays = [];

    for (var t in tlv) {
      switch (t.type) {
        case 0: // pubkey (special)
          if (t.value.length == 32) {
            pubkey = hex.encode(t.value);
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

    var data = Nip19Utils.convertBits(bech32Result.data, 5, 8, false);
    final tlv = Nip19TLV.parseTLV(data);

    String? eventId;
    List<String> relays = [];
    String? author;
    int? kind;

    for (var t in tlv) {
      switch (t.type) {
        case 0: // event id (special)
          if (t.value.length == 32) {
            eventId = hex.encode(t.value);
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
            author = hex.encode(t.value);
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

    var data = Nip19Utils.convertBits(bech32Result.data, 5, 8, false);
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
            pubkey = hex.encode(t.value);
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
}
