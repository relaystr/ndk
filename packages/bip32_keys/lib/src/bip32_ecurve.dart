// coverage:ignore-file

import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:pointycastle/api.dart'
    show PrivateKeyParameter, PublicKeyParameter;
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/ecc/api.dart'
    show ECPoint, ECPrivateKey, ECPublicKey, ECSignature;
import 'package:pointycastle/ecc/curves/secp256k1.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/signers/ecdsa_signer.dart';
// ignore: implementation_imports
import 'package:pointycastle/src/utils.dart' show negativeFlag;

final zero32 = Uint8List.fromList(List.generate(32, (index) => 0));
final ecGroupOrder = hex
    .decode('fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141');
final ecP = hex
    .decode('fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f');
final secp256k1 = ECCurve_secp256k1();
final n = secp256k1.n;
final g = secp256k1.G;
BigInt nDiv2 = n >> 1;

const throwBadPrivate = 'Expected Private';
const throwBadPoint = 'Expected Point';
const throwBadTweak = 'Expected Tweak';
const throwBadHash = 'Expected Hash';
const throwBadSignature = 'Expected Signature';

bool isPrivate(Uint8List x) {
  if (!isScalar(x)) return false;
  return _compare(x, zero32) > 0 && _compare(x, ecGroupOrder as Uint8List) < 0;
}

bool isPoint(Uint8List p) {
  if (p.length < 33) {
    return false;
  }
  var t = p[0];
  var x = p.sublist(1, 33);

  if (_compare(x, zero32) == 0) {
    return false;
  }
  if (_compare(x, ecP as Uint8List) == 1) {
    return false;
  }
  try {
    decodeFrom(p);
  } catch (_) {
    return false;
  }
  if ((t == 0x02 || t == 0x03) && p.length == 33) {
    return true;
  }
  var y = p.sublist(33);
  if (_compare(y, zero32) == 0) {
    return false;
  }
  if (_compare(y, ecP as Uint8List) == 1) {
    return false;
  }
  if (t == 0x04 && p.length == 65) {
    return true;
  }
  return false;
}

bool isScalar(Uint8List x) {
  return x.length == 32;
}

bool isOrderScalar(Uint8List x) {
  if (!isScalar(x)) return false;
  return _compare(x, ecGroupOrder as Uint8List) < 0;
}

bool isSignature(Uint8List value) {
  final r = value.sublist(0, 32);
  final s = value.sublist(32, 64);

  return value.length == 64 &&
      _compare(r, ecGroupOrder as Uint8List) < 0 &&
      _compare(s, ecGroupOrder as Uint8List) < 0;
}

bool _isPointCompressed(Uint8List p) {
  return p[0] != 0x04;
}

bool assumeCompression(bool? value, Uint8List? pubkey) {
  if (value == null && pubkey != null) return _isPointCompressed(pubkey);
  if (value == null) return true;
  return value;
}

Uint8List? pointFromScalar(Uint8List d, bool compressed) {
  if (!isPrivate(d)) throw ArgumentError(throwBadPrivate);
  final dd = fromBuffer(d);
  final pp = (g * dd) as ECPoint;
  if (pp.isInfinity) return null;
  return getEncoded(pp, compressed);
}

Uint8List? pointAddScalar(Uint8List p, Uint8List tweak, bool compressed) {
  if (!isPoint(p)) throw ArgumentError(throwBadPoint);
  if (!isOrderScalar(tweak)) throw ArgumentError(throwBadTweak);
  final isCompressed = assumeCompression(compressed, p);
  final pp = decodeFrom(p);
  if (_compare(tweak, zero32) == 0) return getEncoded(pp, isCompressed);
  final tt = fromBuffer(tweak);
  final qq = (g * tt) as ECPoint;
  final uu = (pp! + qq) as ECPoint;
  if (uu.isInfinity) return null;
  return getEncoded(uu, isCompressed);
}

Uint8List? privateAdd(Uint8List d, Uint8List tweak) {
  if (!isPrivate(d)) throw ArgumentError(throwBadPrivate);
  if (!isOrderScalar(tweak)) throw ArgumentError(throwBadTweak);
  final dd = fromBuffer(d);
  final tt = fromBuffer(tweak);
  var dt = toBuffer((dd + tt) % n);

  if (dt.length < 32) {
    final padLeadingZero = Uint8List(32 - dt.length);
    dt = Uint8List.fromList(padLeadingZero + dt);
  }

  if (!isPrivate(dt)) return null;
  return dt;
}

Uint8List sign(Uint8List hash, Uint8List x) {
  if (!isScalar(hash)) throw ArgumentError(throwBadHash);
  if (!isPrivate(x)) throw ArgumentError(throwBadPrivate);
  final sig = deterministicGenerateK(hash, x);
  final buffer = Uint8List(64);
  buffer.setRange(0, 32, _encodeBigInt(sig.r));
  final s = sig.s.compareTo(nDiv2) > 0 ? n - sig.s : sig.s;
  buffer.setRange(32, 64, _encodeBigInt(s));
  return buffer;
}

bool verify(Uint8List hash, Uint8List q, Uint8List signature) {
  if (!isScalar(hash)) throw ArgumentError(throwBadHash);
  if (!isPoint(q)) throw ArgumentError(throwBadPoint);
  if (!isSignature(signature)) throw ArgumentError(throwBadSignature);

  final Q = decodeFrom(q);
  final r = fromBuffer(signature.sublist(0, 32));
  final s = fromBuffer(signature.sublist(32, 64));

  final signer = ECDSASigner(null, HMac(SHA256Digest(), 64));
  signer.init(false, PublicKeyParameter(ECPublicKey(Q, secp256k1)));
  return signer.verifySignature(hash, ECSignature(r, s));
}

BigInt _decodeBigInt(List<int> bytes) {
  var result = BigInt.zero;
  for (var i = 0; i < bytes.length; i++) {
    result += BigInt.from(bytes[bytes.length - i - 1]) << (8 * i);
  }
  return result;
}

final _byteMask = BigInt.from(0xff);

Uint8List _encodeBigInt(BigInt number) {
  late int needsPaddingByte;
  late int rawSize;

  if (number > BigInt.zero) {
    rawSize = (number.bitLength + 7) >> 3;
    needsPaddingByte =
        ((number >> (rawSize - 1) * 8) & negativeFlag) == negativeFlag ? 1 : 0;

    if (rawSize < 32) {
      needsPaddingByte = 1;
    }
  } else {
    needsPaddingByte = 0;
    rawSize = (number.bitLength + 8) >> 3;
  }

  final size = rawSize < 32 ? rawSize + needsPaddingByte : rawSize;
  final result = Uint8List(size);
  for (var i = 0; i < size; i++) {
    result[size - i - 1] = (number & _byteMask).toInt();
    number = number >> 8;
  }
  return result;
}

BigInt fromBuffer(Uint8List d) {
  return _decodeBigInt(d);
}

Uint8List toBuffer(BigInt d) {
  return _encodeBigInt(d);
}

ECPoint? decodeFrom(Uint8List p) {
  return secp256k1.curve.decodePoint(p);
}

Uint8List getEncoded(ECPoint? p, bool compressed) {
  return p!.getEncoded(compressed);
}

ECSignature deterministicGenerateK(Uint8List hash, Uint8List x) {
  final signer = ECDSASigner(null, HMac(SHA256Digest(), 64));
  final pkp = PrivateKeyParameter(ECPrivateKey(_decodeBigInt(x), secp256k1));
  signer.init(true, pkp);
  return signer.generateSignature(hash) as ECSignature;
}

int _compare(Uint8List a, Uint8List b) {
  final aa = fromBuffer(a);
  final bb = fromBuffer(b);
  if (aa == bb) return 0;
  if (aa > bb) return 1;
  return -1;
}
