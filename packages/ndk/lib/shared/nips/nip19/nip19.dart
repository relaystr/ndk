import 'hrps.dart';
import 'nip19_encoder.dart';
import 'nip19_decoder.dart';
import 'nip19_utils.dart';
import '../../../domain_layer/entities/naddr.dart';
import '../../../domain_layer/entities/nevent.dart';
import '../../../domain_layer/entities/nprofile.dart';

// Re-export for backwards compatibility
export 'nip19_encoder.dart';
export 'nip19_decoder.dart';
export 'nip19_tlv.dart';
export 'nip19_utils.dart';

/// Main NIP-19 class providing encoding, decoding, and validation
/// This is a facade that delegates to specialized encoder/decoder classes
class Nip19 {
  static const int kNpubLength = 63;
  static const int kNoteIdLength = 63;

  static RegExp nip19regex = RegExp(
      r'@?(nostr:)?@?(nsec1|npub1|nevent1|naddr1|note1|nprofile1|nrelay1)([qpzry9x8gf2tvdw0s3jn54khce6mua7l]+)([\\S]*)',
      caseSensitive: false);

  // ============================================================================
  // Validation methods
  // ============================================================================

  /// Check if a string matches NIP-19 format
  static bool isNip19(String str) {
    return nip19regex.firstMatch(str) != null;
  }

  /// Check if a string starts with a specific HRP (Human Readable Part)
  static bool isKey(String hrp, String str) {
    if (str.indexOf(hrp) == 0) {
      return true;
    } else {
      return false;
    }
  }

  /// Check if a string is a public key (npub)
  static bool isPubkey(String str) {
    return isKey(Hrps.kPublicKey, str);
  }

  /// Check if a string is a private key (nsec)
  static bool isPrivateKey(String str) {
    return isKey(Hrps.kPrivateKey, str);
  }

  /// Check if a string is a note ID (note1)
  static bool isNoteId(String str) {
    return isKey(Hrps.kNoteId, str);
  }

  // ============================================================================
  // Encoding methods (delegated to Nip19Encoder)
  // ============================================================================

  /// Encode a public key as npub
  static String encodePubKey(String pubkey) {
    return Nip19Encoder.encodePubKey(pubkey);
  }

  /// Encode a public key in simplified format (first10:last10)
  static String encodeSimplePubKey(String pubKey) {
    try {
      var code = encodePubKey(pubKey);
      var length = code.length;
      return "${code.substring(0, 10)}:${code.substring(length - 10)}";
    } catch (e) {
      return pubKey;
    }
  }

  /// Encode a private key as nsec
  static String encodePrivateKey(String privateKey) {
    return Nip19Encoder.encodePrivateKey(privateKey);
  }

  /// Encode a note ID as note1
  static String encodeNoteId(String id) {
    return Nip19Encoder.encodeNoteId(id);
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
    return Nip19Encoder.encodeNevent(
      eventId: eventId,
      relays: relays,
      author: author,
      kind: kind,
    );
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
    return Nip19Encoder.encodeNaddr(
      identifier: identifier,
      pubkey: pubkey,
      kind: kind,
      relays: relays,
    );
  }

  /// Encode nprofile (profile reference)
  /// [pubkey] - 32-byte hex public key (required)
  /// [relays] - optional list of relay URLs where the profile may be found
  static String encodeNprofile({
    required String pubkey,
    List<String>? relays,
  }) {
    return Nip19Encoder.encodeNprofile(
      pubkey: pubkey,
      relays: relays,
    );
  }

  // ============================================================================
  // Decoding methods (delegated to Nip19Decoder)
  // ============================================================================

  /// Decode a NIP-19 encoded string (npub, note, nevent, nprofile, naddr)
  /// Returns the decoded hex string
  static String decode(String nip19String) {
    return Nip19Decoder.decode(nip19String);
  }

  /// Decode nprofile and return Nprofile object
  static Nprofile decodeNprofile(String nprofileStr) {
    return Nip19Decoder.decodeNprofile(nprofileStr);
  }

  /// Decode nevent and return Nevent object
  static Nevent decodeNevent(String neventStr) {
    return Nip19Decoder.decodeNevent(neventStr);
  }

  /// Decode naddr and return Naddr object
  static Naddr decodeNaddr(String naddrStr) {
    return Nip19Decoder.decodeNaddr(naddrStr);
  }

  // ============================================================================
  // Utility methods (delegated to Nip19Utils)
  // ============================================================================

  /// Convert bits from one size to another
  /// Used for bech32 encoding/decoding
  static List<int> convertBits(List<int> data, int from, int to, bool pad) {
    return Nip19Utils.convertBits(data, from, to, pad);
  }
}
