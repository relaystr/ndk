// coverage:ignore-file

import 'dart:typed_data';

import 'package:pointycastle/api.dart' show KeyParameter;
import 'package:pointycastle/digests/ripemd160.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/digests/sha512.dart';
import 'package:pointycastle/macs/hmac.dart';

Uint8List hash160(Uint8List buffer) {
  final tmp = SHA256Digest().process(buffer);
  return RIPEMD160Digest().process(tmp);
}

Uint8List hmacSHA512(Uint8List key, Uint8List data) {
  final tmp = HMac(SHA512Digest(), 128)..init(KeyParameter(key));
  return tmp.process(data);
}
