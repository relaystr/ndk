import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Negentropy protocol implementation for NIP-77
/// Handles varint encoding, fingerprints, bounds, and message framing
class Negentropy {
  /// Protocol version byte
  static const int protocolVersion = 0x61;

  /// Size of event ID in bytes (32 bytes = 64 hex chars)
  static const int idSize = 32;

  /// Size of fingerprint in bytes
  static const int fingerprintSize = 16;

  /// Mode constants
  static const int modeSkip = 0;
  static const int modeFingerprint = 1;
  static const int modeIdList = 2;

  /// Encodes an integer as a varint (base-128, MSB-first)
  static Uint8List encodeVarint(int value) {
    if (value < 0) {
      throw ArgumentError('Varint value must be non-negative');
    }

    if (value == 0) {
      return Uint8List.fromList([0]);
    }

    final bytes = <int>[];
    var remaining = value;

    while (remaining > 0) {
      bytes.insert(0, remaining & 0x7F);
      remaining >>= 7;
    }

    // Set continuation bits (MSB) on all bytes except the last
    for (var i = 0; i < bytes.length - 1; i++) {
      bytes[i] |= 0x80;
    }

    return Uint8List.fromList(bytes);
  }

  /// Decodes a varint from bytes, returns (value, bytesConsumed)
  static (int value, int bytesConsumed) decodeVarint(Uint8List data,
      [int offset = 0]) {
    if (offset >= data.length) {
      throw ArgumentError('Not enough data to decode varint');
    }

    int value = 0;
    int bytesConsumed = 0;

    while (offset + bytesConsumed < data.length) {
      final byte = data[offset + bytesConsumed];
      value = (value << 7) | (byte & 0x7F);
      bytesConsumed++;

      if ((byte & 0x80) == 0) {
        break;
      }

      if (bytesConsumed > 9) {
        throw ArgumentError('Varint too long');
      }
    }

    return (value, bytesConsumed);
  }

  /// Calculates fingerprint from a list of event IDs
  /// Fingerprint = SHA256(XOR of all IDs || count as little-endian u64)[0:16]
  static Uint8List calculateFingerprint(List<Uint8List> ids) {
    // XOR all IDs together
    final xorResult = Uint8List(idSize);

    for (final id in ids) {
      for (var i = 0; i < idSize && i < id.length; i++) {
        xorResult[i] ^= id[i];
      }
    }

    // Count as little-endian u64 (8 bytes)
    final countBytes = Uint8List(8);
    var count = ids.length;
    for (var i = 0; i < 8; i++) {
      countBytes[i] = count & 0xFF;
      count >>= 8;
    }

    // SHA256 and take first 16 bytes
    final combined = Uint8List.fromList([...xorResult, ...countBytes]);
    final digest = sha256.convert(combined);

    return Uint8List.fromList(digest.bytes.sublist(0, fingerprintSize));
  }

  /// Encodes a bound (timestamp + ID prefix)
  static Uint8List encodeBound(int timestamp, Uint8List idPrefix) {
    final timestampBytes = encodeVarint(timestamp);
    final lengthByte = Uint8List.fromList([idPrefix.length]);
    return Uint8List.fromList([...timestampBytes, ...lengthByte, ...idPrefix]);
  }

  /// Decodes a bound from bytes
  static (int timestamp, Uint8List idPrefix, int bytesConsumed) decodeBound(
      Uint8List data,
      [int offset = 0]) {
    final (timestamp, tsBytes) = decodeVarint(data, offset);
    final prefixLength = data[offset + tsBytes];
    final idPrefix = Uint8List.fromList(
        data.sublist(offset + tsBytes + 1, offset + tsBytes + 1 + prefixLength));
    return (timestamp, idPrefix, tsBytes + 1 + prefixLength);
  }

  /// Parses a hex string to bytes
  static Uint8List hexToBytes(String hex) {
    if (hex.length % 2 != 0) {
      throw ArgumentError('Hex string must have even length');
    }
    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < result.length; i++) {
      result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }

  /// Converts bytes to hex string
  static String bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Creates an initial client message (NEG-OPEN query payload)
  static Uint8List createInitialMessage(
      List<NegentropyItem> items, int idSize) {
    items.sort((a, b) {
      final tsCmp = a.timestamp.compareTo(b.timestamp);
      if (tsCmp != 0) return tsCmp;
      return _compareBytes(a.id, b.id);
    });

    final output = BytesBuilder();
    output.addByte(protocolVersion);

    // Single range covering all items with fingerprint
    // Upper bound - use max timestamp + 1 if we have items, otherwise use a large value
    final maxTs = items.isEmpty ? 0x7FFFFFFF : items.last.timestamp + 1;
    output.add(encodeVarint(maxTs));
    output.addByte(0); // prefix length

    // Always send fingerprint mode (even for empty set)
    output.addByte(modeFingerprint);
    final ids = items.map((i) => i.id).toList();
    output.add(calculateFingerprint(ids));

    return output.toBytes();
  }

  /// Reconciles received message and creates response
  /// Returns (response bytes, need IDs, have IDs)
  static (Uint8List response, List<String> needIds, List<String> haveIds)
      reconcile(Uint8List message, List<NegentropyItem> items) {
    items.sort((a, b) {
      final tsCmp = a.timestamp.compareTo(b.timestamp);
      if (tsCmp != 0) return tsCmp;
      return _compareBytes(a.id, b.id);
    });

    int offset = 0;

    // Check version
    if (message.isEmpty || message[0] != protocolVersion) {
      throw ArgumentError('Invalid protocol version');
    }
    offset++;

    final needIds = <String>[];
    final haveIds = <String>[];
    final output = BytesBuilder();
    output.addByte(protocolVersion);

    var prevBound = _Bound(0, Uint8List(0));
    var itemIndex = 0;

    while (offset < message.length) {
      // Decode upper bound
      final (timestamp, idPrefix, boundBytes) = decodeBound(message, offset);
      offset += boundBytes;

      final currBound = _Bound(timestamp, idPrefix);

      // Get items in range [prevBound, currBound)
      final rangeItems = <NegentropyItem>[];
      while (itemIndex < items.length) {
        final item = items[itemIndex];
        if (_isInRange(item, prevBound, currBound)) {
          rangeItems.add(item);
          itemIndex++;
        } else if (_isBeforeBound(item, currBound)) {
          itemIndex++;
        } else {
          break;
        }
      }

      // Decode mode
      if (offset >= message.length) break;
      final mode = message[offset++];

      switch (mode) {
        case modeSkip:
          // Do nothing, this range is synchronized
          break;

        case modeFingerprint:
          // Read fingerprint
          if (offset + fingerprintSize > message.length) {
            throw ArgumentError('Not enough data for fingerprint');
          }
          final theirFingerprint =
              Uint8List.fromList(message.sublist(offset, offset + fingerprintSize));
          offset += fingerprintSize;

          // Calculate our fingerprint for this range
          final ourIds = rangeItems.map((i) => i.id).toList();
          final ourFingerprint = calculateFingerprint(ourIds);

          if (!_bytesEqual(theirFingerprint, ourFingerprint)) {
            // Mismatch - need to split or send IDs
            if (rangeItems.length <= 2) {
              // Send our IDs directly
              output.add(encodeBound(timestamp, idPrefix));
              output.addByte(modeIdList);
              output.add(encodeVarint(rangeItems.length));
              for (final item in rangeItems) {
                output.add(item.id);
              }
            } else {
              // Split range in half
              final mid = rangeItems.length ~/ 2;
              final midItem = rangeItems[mid];

              // First half
              output.add(encodeBound(midItem.timestamp, midItem.id));
              output.addByte(modeFingerprint);
              final firstHalfIds =
                  rangeItems.sublist(0, mid).map((i) => i.id).toList();
              output.add(calculateFingerprint(firstHalfIds));

              // Second half
              output.add(encodeBound(timestamp, idPrefix));
              output.addByte(modeFingerprint);
              final secondHalfIds =
                  rangeItems.sublist(mid).map((i) => i.id).toList();
              output.add(calculateFingerprint(secondHalfIds));
            }
          }
          break;

        case modeIdList:
          // Read their IDs
          final (count, countBytes) = decodeVarint(message, offset);
          offset += countBytes;

          final theirIds = <Uint8List>[];
          for (var i = 0; i < count; i++) {
            if (offset + idSize > message.length) {
              throw ArgumentError('Not enough data for ID');
            }
            theirIds.add(Uint8List.fromList(message.sublist(offset, offset + idSize)));
            offset += idSize;
          }

          // Find differences
          final ourIdSet =
              rangeItems.map((i) => bytesToHex(i.id)).toSet();
          final theirIdSet = theirIds.map(bytesToHex).toSet();

          // We need IDs they have that we don't
          for (final theirId in theirIdSet) {
            if (!ourIdSet.contains(theirId)) {
              needIds.add(theirId);
            }
          }

          // We have IDs that they don't
          for (final ourId in ourIdSet) {
            if (!theirIdSet.contains(ourId)) {
              haveIds.add(ourId);
            }
          }

          // Send skip for this range
          output.add(encodeBound(timestamp, idPrefix));
          output.addByte(modeSkip);
          break;

        default:
          throw ArgumentError('Unknown mode: $mode');
      }

      prevBound = currBound;
    }

    return (output.toBytes(), needIds, haveIds);
  }

  static int _compareBytes(Uint8List a, Uint8List b) {
    final minLength = a.length < b.length ? a.length : b.length;
    for (var i = 0; i < minLength; i++) {
      if (a[i] != b[i]) {
        return a[i].compareTo(b[i]);
      }
    }
    return a.length.compareTo(b.length);
  }

  static bool _bytesEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _isInRange(
      NegentropyItem item, _Bound lower, _Bound upper) {
    // item >= lower AND item < upper
    return _compareWithBound(item, lower) >= 0 &&
        _compareWithBound(item, upper) < 0;
  }

  static bool _isBeforeBound(NegentropyItem item, _Bound bound) {
    return _compareWithBound(item, bound) < 0;
  }

  static int _compareWithBound(NegentropyItem item, _Bound bound) {
    if (item.timestamp != bound.timestamp) {
      return item.timestamp.compareTo(bound.timestamp);
    }
    if (bound.idPrefix.isEmpty) {
      return -1; // Empty prefix means "end of timestamp bucket"
    }
    return _compareBytes(item.id, bound.idPrefix);
  }
}

/// Represents an item for negentropy reconciliation
class NegentropyItem {
  final int timestamp;
  final Uint8List id;

  NegentropyItem({required this.timestamp, required this.id});

  factory NegentropyItem.fromHex({required int timestamp, required String idHex}) {
    return NegentropyItem(
      timestamp: timestamp,
      id: Negentropy.hexToBytes(idHex),
    );
  }
}

class _Bound {
  final int timestamp;
  final Uint8List idPrefix;

  _Bound(this.timestamp, this.idPrefix);
}
