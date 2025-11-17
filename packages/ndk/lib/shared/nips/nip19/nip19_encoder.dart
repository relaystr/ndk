import 'dart:convert';

import 'package:bech32/bech32.dart';
import 'package:hex/hex.dart';

import 'hrps.dart';
import 'nip19_utils.dart';

/// NIP-19 encoding functions
class Nip19Encoder {
  /// Encode a public key as npub
  static String encodePubKey(String pubkey) {
    return _encodeKey(Hrps.kPublicKey, pubkey);
  }

  /// Encode a private key as nsec
  static String encodePrivateKey(String privateKey) {
    return _encodeKey(Hrps.kPrivateKey, privateKey);
  }

  /// Encode a note ID as note1
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
    final data = Nip19Utils.convertBits(tlvData, 8, 5, true);
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
    final data = Nip19Utils.convertBits(tlvData, 8, 5, true);
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
    final data = Nip19Utils.convertBits(tlvData, 8, 5, true);
    var encoder = Bech32Encoder();
    Bech32 input = Bech32(Hrps.kNprofile, data);
    var encoded = encoder.convert(input, input.hrp.length + data.length + 10);
    return encoded;
  }

  /// Internal helper to encode a simple key (pubkey, privkey, or note ID)
  static String _encodeKey(String hrp, String key) {
    var data = HEX.decode(key);
    data = Nip19Utils.convertBits(data, 8, 5, true);

    var encoder = Bech32Encoder();
    Bech32 input = Bech32(hrp, data);
    return encoder.convert(input);
  }
}
