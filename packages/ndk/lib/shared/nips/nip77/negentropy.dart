import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Negentropy Protocol V1 codec, as specified in the NIP-77 appendix.
///
/// See https://github.com/hoytech/negentropy/blob/master/docs/negentropy-protocol-v1.md
class NegentropyEncoder {
  /// Protocol version byte (version 1)
  static const int protocolVersion = 0x61;

  /// Size of event ID in bytes (32 bytes = 64 hex chars)
  static const int idSize = 32;

  /// Size of fingerprint in bytes
  static const int fingerprintSize = 16;

  /// Mode constants
  static const int modeSkip = 0;
  static const int modeFingerprint = 1;
  static const int modeIdList = 2;

  /// Reserved "infinity" timestamp. The spec reserves `2**64 - 1`, which does
  /// not survive dart2js; this sentinel is the largest exactly representable
  /// integer on both native and web, and never touches the wire (infinity is
  /// always encoded as `0`).
  static const int infiniteTimestamp = 9007199254740991;

  /// Number of sub-ranges a mismatching range is split into
  static const int _buckets = 16;

  /// Ranges with fewer items than this are sent as an id list instead of split
  static const int _idListThreshold = _buckets * 2;

  /// Encodes an integer as a varint (base-128, most significant digit first)
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
      bytes.insert(0, remaining % 128);
      remaining = remaining ~/ 128;
    }

    for (var i = 0; i < bytes.length - 1; i++) {
      bytes[i] |= 0x80;
    }

    return Uint8List.fromList(bytes);
  }

  /// Decodes a varint from bytes, returns (value, bytesConsumed)
  static (int value, int bytesConsumed) decodeVarint(
    Uint8List data, [
    int offset = 0,
  ]) {
    var value = 0;
    var bytesConsumed = 0;

    while (true) {
      if (offset + bytesConsumed >= data.length) {
        throw ArgumentError('Truncated varint');
      }

      final byte = data[offset + bytesConsumed];
      bytesConsumed++;

      final digit = byte & 0x7F;
      if (value > (infiniteTimestamp - digit) ~/ 128) {
        throw ArgumentError('Varint exceeds the supported integer range');
      }
      value = value * 128 + digit;

      if ((byte & 0x80) == 0) {
        return (value, bytesConsumed);
      }
    }
  }

  /// Calculates the fingerprint of a range: the first 16 bytes of
  /// `SHA256(sum of the IDs mod 2^256, little-endian || varint(count))`.
  static Uint8List calculateFingerprint(List<Uint8List> ids) {
    final accumulator = Uint8List(idSize);

    for (final id in ids) {
      var carry = 0;
      for (var i = 0; i < idSize; i++) {
        final sum = accumulator[i] + (i < id.length ? id[i] : 0) + carry;
        accumulator[i] = sum & 0xFF;
        carry = sum >> 8;
      }
    }

    final digest = sha256.convert([
      ...accumulator,
      ...encodeVarint(ids.length),
    ]);

    return Uint8List.fromList(digest.bytes.sublist(0, fingerprintSize));
  }

  /// Encodes a bound. Timestamps are delta encoded against [lastTimestamp],
  /// which is the timestamp of the previously encoded bound in the same
  /// message (0 at the start of every message).
  static Uint8List encodeBound(
    int timestamp,
    Uint8List idPrefix, {
    int lastTimestamp = 0,
  }) {
    if (idPrefix.length > idSize) {
      throw ArgumentError('Bound ID prefix must be at most $idSize bytes');
    }

    final output = BytesBuilder();

    if (timestamp >= infiniteTimestamp) {
      output.addByte(0);
    } else {
      if (timestamp < lastTimestamp) {
        throw ArgumentError('Bound timestamps must be non-decreasing');
      }
      output.add(encodeVarint(timestamp - lastTimestamp + 1));
    }

    output.add(encodeVarint(idPrefix.length));
    output.add(idPrefix);

    return output.toBytes();
  }

  /// Decodes a bound. [lastTimestamp] is the timestamp of the previously
  /// decoded bound in the same message (0 at the start of every message).
  static (int timestamp, Uint8List idPrefix, int bytesConsumed) decodeBound(
    Uint8List data, [
    int offset = 0,
    int lastTimestamp = 0,
  ]) {
    var pos = offset;

    final (encodedTimestamp, timestampBytes) = decodeVarint(data, pos);
    pos += timestampBytes;

    final int timestamp;
    if (encodedTimestamp == 0) {
      timestamp = infiniteTimestamp;
    } else {
      timestamp = lastTimestamp + encodedTimestamp - 1;
      if (timestamp >= infiniteTimestamp) {
        throw ArgumentError('Bound timestamp out of range');
      }
    }

    final (prefixLength, lengthBytes) = decodeVarint(data, pos);
    pos += lengthBytes;

    if (prefixLength > idSize) {
      throw ArgumentError('Bound ID prefix too long: $prefixLength');
    }
    if (pos + prefixLength > data.length) {
      throw ArgumentError('Truncated bound ID prefix');
    }

    final idPrefix = Uint8List.fromList(data.sublist(pos, pos + prefixLength));
    pos += prefixLength;

    return (timestamp, idPrefix, pos - offset);
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
  static String bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Creates the initial message an initiator sends in `NEG-OPEN`.
  static Uint8List createInitialMessage(
    List<NegentropyItem> items, [
    int itemIdSize = idSize,
  ]) {
    if (itemIdSize != idSize) {
      throw ArgumentError('Negentropy v1 requires $idSize byte IDs');
    }

    final sorted = _prepare(items);
    final output = _MessageWriter()..addByte(protocolVersion);
    _splitRange(sorted, 0, sorted.length, _infinityBound, output);

    return output.toBytes();
  }

  /// Reconciles a message received from the other side as the initiator.
  ///
  /// Returns the response to send back plus the IDs discovered so far:
  /// [needIds] are held by the other side only, [haveIds] by us only. A
  /// response consisting of nothing but the version byte means the
  /// reconciliation has converged.
  static (Uint8List response, List<String> needIds, List<String> haveIds)
      reconcile(Uint8List message, List<NegentropyItem> items) {
    final needIds = <String>[];
    final haveIds = <String>[];
    final response = _reconcileAux(
      message,
      items,
      isInitiator: true,
      needIds: needIds,
      haveIds: haveIds,
    );
    return (response, needIds, haveIds);
  }

  /// Reconciles a message received from an initiator, as the responding side.
  ///
  /// Only the initiator learns the have/need sets, so this returns just the
  /// response message.
  static Uint8List respond(Uint8List message, List<NegentropyItem> items) {
    return _reconcileAux(
      message,
      items,
      isInitiator: false,
      needIds: [],
      haveIds: [],
    );
  }

  static Uint8List _reconcileAux(
    Uint8List message,
    List<NegentropyItem> items, {
    required bool isInitiator,
    required List<String> needIds,
    required List<String> haveIds,
  }) {
    if (message.isEmpty) {
      throw ArgumentError('Empty negentropy message');
    }
    if (message[0] != protocolVersion) {
      throw ArgumentError(
        'Unsupported negentropy protocol version: '
        '0x${message[0].toRadixString(16)}',
      );
    }

    final sorted = _prepare(items);
    final output = _MessageWriter()..addByte(protocolVersion);

    var offset = 1;
    var lastTimestampIn = 0;
    var prevBound = _Bound(0, Uint8List(0));
    var prevIndex = 0;
    var pendingSkip = false;

    // Adjacent skipped ranges are coalesced into one, emitted only once a
    // range that carries a payload follows.
    void flushSkip() {
      if (!pendingSkip) return;
      pendingSkip = false;
      output.addBound(prevBound);
      output.addVarint(modeSkip);
    }

    while (offset < message.length) {
      final (timestamp, idPrefix, boundBytes) = decodeBound(
        message,
        offset,
        lastTimestampIn,
      );
      offset += boundBytes;
      lastTimestampIn = timestamp;
      final currBound = _Bound(timestamp, idPrefix);

      if (offset >= message.length) {
        throw ArgumentError('Truncated range: missing mode');
      }
      final (mode, modeBytes) = decodeVarint(message, offset);
      offset += modeBytes;

      final lower = prevIndex;
      final upper = _lowerBound(sorted, prevIndex, currBound);

      switch (mode) {
        case modeSkip:
          pendingSkip = true;

        case modeFingerprint:
          if (offset + fingerprintSize > message.length) {
            throw ArgumentError('Truncated fingerprint');
          }
          final theirFingerprint = Uint8List.sublistView(
            message,
            offset,
            offset + fingerprintSize,
          );
          offset += fingerprintSize;

          final ourFingerprint = calculateFingerprint([
            for (var i = lower; i < upper; i++) sorted[i].id,
          ]);

          if (_bytesEqual(theirFingerprint, ourFingerprint)) {
            pendingSkip = true;
          } else {
            flushSkip();
            _splitRange(sorted, lower, upper, currBound, output);
          }

        case modeIdList:
          final (count, countBytes) = decodeVarint(message, offset);
          offset += countBytes;
          if (count > (message.length - offset) ~/ idSize) {
            throw ArgumentError('Truncated ID list');
          }

          final theirIds = <String>{};
          for (var i = 0; i < count; i++) {
            theirIds.add(
              bytesToHex(
                Uint8List.sublistView(message, offset, offset + idSize),
              ),
            );
            offset += idSize;
          }

          if (isInitiator) {
            for (var i = lower; i < upper; i++) {
              final ourId = bytesToHex(sorted[i].id);
              if (!theirIds.remove(ourId)) {
                haveIds.add(ourId);
              }
            }
            needIds.addAll(theirIds);
            pendingSkip = true;
          } else {
            flushSkip();
            output.addBound(currBound);
            output.addVarint(modeIdList);
            output.addVarint(upper - lower);
            for (var i = lower; i < upper; i++) {
              output.addBytes(sorted[i].id);
            }
          }

        default:
          throw ArgumentError('Unknown negentropy mode: $mode');
      }

      prevBound = currBound;
      prevIndex = upper;
    }

    // A trailing skip needs no encoding: the spec appends an implicit skip to
    // infinity after the last range.
    return output.toBytes();
  }

  /// Emits [lower, upper) either as an id list or as [_buckets] sub-ranges
  /// covered by fingerprints, ending on [upperBound].
  static void _splitRange(
    List<NegentropyItem> items,
    int lower,
    int upper,
    _Bound upperBound,
    _MessageWriter output,
  ) {
    final numElems = upper - lower;

    if (numElems < _idListThreshold) {
      output.addBound(upperBound);
      output.addVarint(modeIdList);
      output.addVarint(numElems);
      for (var i = lower; i < upper; i++) {
        output.addBytes(items[i].id);
      }
      return;
    }

    final itemsPerBucket = numElems ~/ _buckets;
    final bucketsWithExtra = numElems % _buckets;
    var curr = lower;

    for (var i = 0; i < _buckets; i++) {
      final bucketSize = itemsPerBucket + (i < bucketsWithExtra ? 1 : 0);
      final next = curr + bucketSize;

      final bound = next >= upper
          ? upperBound
          : _minimalBound(items[next - 1], items[next]);

      output.addBound(bound);
      output.addVarint(modeFingerprint);
      output.addBytes(
        calculateFingerprint([for (var j = curr; j < next; j++) items[j].id]),
      );

      curr = next;
    }
  }

  /// Shortest bound that separates [prev] from [curr]
  static _Bound _minimalBound(NegentropyItem prev, NegentropyItem curr) {
    if (curr.timestamp != prev.timestamp) {
      return _Bound(curr.timestamp, Uint8List(0));
    }

    var shared = 0;
    while (shared < idSize && curr.id[shared] == prev.id[shared]) {
      shared++;
    }

    return _Bound(
      curr.timestamp,
      Uint8List.fromList(
        curr.id.sublist(0, shared + 1 > idSize ? idSize : shared + 1),
      ),
    );
  }

  /// Index of the first item at or after [bound], searching from [from]
  static int _lowerBound(List<NegentropyItem> items, int from, _Bound bound) {
    var low = from;
    var high = items.length;

    while (low < high) {
      final mid = low + ((high - low) >> 1);
      if (_compareItemToBound(items[mid], bound) < 0) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }

    return low;
  }

  /// Sorts by (timestamp, id) ascending and drops duplicates
  static List<NegentropyItem> _prepare(List<NegentropyItem> items) {
    items.sort(_compareItems);

    final prepared = <NegentropyItem>[];
    for (final item in items) {
      if (prepared.isNotEmpty && _compareItems(prepared.last, item) == 0) {
        continue;
      }
      prepared.add(item);
    }

    return prepared;
  }

  static int _compareItems(NegentropyItem a, NegentropyItem b) {
    final timestampCmp = a.timestamp.compareTo(b.timestamp);
    if (timestampCmp != 0) return timestampCmp;
    return _compareBytes(a.id, b.id);
  }

  /// Compares an item against a bound whose ID prefix is implicitly
  /// zero-padded to [idSize] bytes.
  static int _compareItemToBound(NegentropyItem item, _Bound bound) {
    if (item.timestamp != bound.timestamp) {
      return item.timestamp.compareTo(bound.timestamp);
    }
    for (var i = 0; i < idSize; i++) {
      final boundByte = i < bound.idPrefix.length ? bound.idPrefix[i] : 0;
      if (item.id[i] != boundByte) {
        return item.id[i].compareTo(boundByte);
      }
    }
    return 0;
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

  static bool _bytesEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static final _Bound _infinityBound = _Bound(infiniteTimestamp, Uint8List(0));
}

/// Represents an item for negentropy reconciliation
class NegentropyItem {
  final int timestamp;
  final Uint8List id;

  NegentropyItem({required this.timestamp, required this.id}) {
    if (id.length != NegentropyEncoder.idSize) {
      throw ArgumentError(
        'Negentropy IDs must be ${NegentropyEncoder.idSize} bytes, '
        'got ${id.length}',
      );
    }
    if (timestamp < 0 || timestamp >= NegentropyEncoder.infiniteTimestamp) {
      throw ArgumentError('Negentropy timestamp out of range: $timestamp');
    }
  }

  factory NegentropyItem.fromHex({
    required int timestamp,
    required String idHex,
  }) {
    return NegentropyItem(
      timestamp: timestamp,
      id: NegentropyEncoder.hexToBytes(idHex),
    );
  }
}

/// Accumulates a message while delta encoding bound timestamps against the
/// previously written bound.
class _MessageWriter {
  final BytesBuilder _output = BytesBuilder();
  int _lastTimestamp = 0;

  void addByte(int byte) => _output.addByte(byte);

  void addBytes(Uint8List bytes) => _output.add(bytes);

  void addVarint(int value) =>
      _output.add(NegentropyEncoder.encodeVarint(value));

  void addBound(_Bound bound) {
    _output.add(
      NegentropyEncoder.encodeBound(
        bound.timestamp,
        bound.idPrefix,
        lastTimestamp: _lastTimestamp,
      ),
    );
    _lastTimestamp = bound.timestamp;
  }

  Uint8List toBytes() => _output.toBytes();
}

class _Bound {
  final int timestamp;
  final Uint8List idPrefix;

  _Bound(this.timestamp, this.idPrefix);
}
