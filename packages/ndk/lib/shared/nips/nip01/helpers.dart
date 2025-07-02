import 'dart:convert';
import 'dart:math';

import 'package:bech32/bech32.dart';
import 'package:hex/hex.dart';

import '../../logger/logger.dart';

class Helpers {
  static const _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';

  // coverage:ignore-line
  static final Random _rnd = Random();

  /// return a random string of given length
  static String getRandomString(int length) {
    return String.fromCharCodes(Iterable.generate(
        length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
  }

  /// return a secure random string of given length
  static String getSecureRandomString(int length) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64UrlEncode(values);
  }

  /// return a secure random hex string of given length
  static String getSecureRandomHex(int length) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return HEX.encode(values);
  }

  /// Encode a hex string + human readable part as a bech32 string
  static String encodeBech32(String hex, String hrp) {
    final bytes = HEX.decode(hex);
    final fiveBitWords = _convertBits(bytes, 8, 5, true);
    return bech32.encode(Bech32(hrp, fiveBitWords), hex.length + hrp.length);
  }

  /// Decode a bech32 string into a hex string + human readable part
  static List<String> decodeBech32(String bech32String) {
    try {
      const Bech32Codec codec = Bech32Codec();
      final Bech32 bech32 = codec.decode(bech32String, bech32String.length);
      final eightBitWords = _convertBits(bech32.data, 5, 8, false);
      return [HEX.encode(eightBitWords), bech32.hrp];
    } catch (e) {
      Logger.log.w(
        'decodeBech32 error: $e, \n \n String is: $bech32String \n \n',
        error: e,
      );
    }
    return ["", ""];
  }

  // static Future<List<String>> decodeBech32Thread(String bech32String) {
  //   var result = compute(decodeBech32, bech32String);
  //   return result;
  // }

  /// reads tags from a nostr event and returns a list of pubkeys
  static List<String> getPubkeysFromTags(List tag) {
    var pubkeys = <String>[];
    for (var i = 0; i < tag.length; i++) {
      if (tag[i][0] == "p") {
        pubkeys.add(tag[i][1]);
      }
    }
    return pubkeys;
  }

  /// reads tags from a nostr event and returns a list of events
  static List<String> getEventsFromTags(List tag) {
    var events = <String>[];
    for (var i = 0; i < tag.length; i++) {
      if (tag[i][0] == "e") {
        events.add(tag[i][1]);
      }
    }
    return events;
  }

  /// Convert bits from one base to another
  /// [data] - the data to convert
  /// [fromBits] - the number of bits per input value
  /// [toBits] - the number of bits per output value
  /// [pad] - whether to pad the output if there are not enough bits
  /// If pad is true, and there are remaining bits after the conversion, then the remaining bits are left-shifted and added to the result
  /// [return] - the converted data
  static List<int> _convertBits(
      List<int> data, int fromBits, int toBits, bool pad) {
    int acc = 0;
    int bits = 0;
    List<int> result = [];

    for (int value in data) {
      acc = (acc << fromBits) | value;
      bits += fromBits;

      while (bits >= toBits) {
        bits -= toBits;
        result.add((acc >> bits) & ((1 << toBits) - 1));
      }
    }

    if (pad) {
      if (bits > 0) {
        result.add((acc << (toBits - bits)) & ((1 << toBits) - 1));
      }
    } else if (bits >= fromBits || (acc & ((1 << bits) - 1)) != 0) {
      throw Exception('Invalid padding');
    }

    return result;
  }

  /// return if given string is not blank
  static bool isNotBlank(String? str) {
    if (str != null && str.trim() != "") {
      return true;
    }
    return false;
  }

  /// return if given string is blank
  static bool isBlank(String? str) {
    return !isNotBlank(str);
  }

  /// now
  static int get now => DateTime.now().millisecondsSinceEpoch ~/ 1000;
}
