// coverage:ignore-file

import 'dart:convert';
import 'dart:typed_data';

import 'package:bs58check/bs58check.dart' as bs58check;

import 'bip32_constants.dart';
import 'bip32_crypto.dart';
import 'bip32_ecurve.dart' as ecc;
import 'bip32_slip132.dart';
import 'bip32_wif.dart' as wif;

class Bip32Keys {
  Uint8List? _d;
  Uint8List? _q;
  Uint8List chainCode;
  int depth = 0;
  int index = 0;
  Bip32Network network;
  int parentFingerprint = 0x00000000;

  Bip32Keys(this._d, this._q, this.chainCode, this.network);

  Uint8List get public {
    _q ??= ecc.pointFromScalar(_d!, true)!;
    return _q!;
  }

  Uint8List? get private => _d;

  Uint8List get identifier => hash160(public);

  Uint8List get fingerprint => identifier.sublist(0, 4);

  bool get isNeutered => _d == null;

  Bip32Keys get neutered {
    final neutered =
        Bip32Keys.fromPublicKey(public, chainCode, network: network);
    neutered.depth = depth;
    neutered.index = index;
    neutered.parentFingerprint = parentFingerprint;
    return neutered;
  }

  factory Bip32Keys.fromBase58(
    String string, {
    Bip32Network? network,
    bool bypassVersion = false,
  }) {
    network ??= Constants.bitcoin;

    final buffer = bs58check.decode(string);
    if (buffer.length != Constants.extendedKeyLength) {
      throw ArgumentError(Constants.errorInvalidBufferLength);
    }

    final bytes = buffer.buffer.asByteData();
    final version = bytes.getUint32(0);
    if (!bypassVersion &&
        (version != network.version.private &&
            version != network.version.public)) {
      throw ArgumentError(Constants.errorInvalidNetworkVersion);
    }

    final depth = buffer[Constants.depthOffset];
    final parentFingerprint =
        bytes.getUint32(Constants.parentFingerprintOffset);
    if (depth == Constants.minDepth) {
      if (parentFingerprint != Constants.defaultParentFingerprint) {
        throw ArgumentError(Constants.errorInvalidParentFingerprint);
      }
    }

    final index = bytes.getUint32(Constants.indexOffset);
    if (depth == Constants.minDepth && index != Constants.defaultIndex) {
      throw ArgumentError(Constants.errorInvalidIndex);
    }

    final chainCode = buffer.sublist(13, 45);
    late Bip32Keys hd;
    if (version == network.version.private) {
      if (bytes.getUint8(Constants.publicKeyOffset) !=
          Constants.defaultPrivateKeyPrefix) {
        throw ArgumentError(Constants.errorInvalidPrivateKey);
      }
      final k = buffer.sublist(
          Constants.privateKeyOffset, Constants.extendedKeyLength);
      hd = Bip32Keys.fromPrivateKey(k, chainCode, network: network);
    } else {
      final x = buffer.sublist(
          Constants.publicKeyOffset, Constants.extendedKeyLength);
      hd = Bip32Keys.fromPublicKey(x, chainCode, network: network);
    }

    hd.depth = depth;
    hd.index = index;
    hd.parentFingerprint = parentFingerprint;
    return hd;
  }

  factory Bip32Keys.fromPublicKey(Uint8List publicKey, Uint8List chainCode,
      {Bip32Network? network}) {
    network ??= Constants.bitcoin;

    if (!ecc.isPoint(publicKey)) {
      throw ArgumentError(Constants.errorPointNotOnCurve);
    }

    return Bip32Keys(null, publicKey, chainCode, network);
  }

  factory Bip32Keys.fromPrivateKey(
    Uint8List privateKey,
    Uint8List chainCode, {
    Bip32Network? network,
  }) {
    network ??= Constants.bitcoin;

    if (privateKey.length != Constants.keyLength) {
      throw ArgumentError(Constants.errorPrivateKeyLength);
    }

    if (!ecc.isPrivate(privateKey)) {
      throw ArgumentError(Constants.errorPrivateKeyRange);
    }

    return Bip32Keys(privateKey, null, chainCode, network);
  }

  factory Bip32Keys.fromSeed(Uint8List seed, {Bip32Network? network}) {
    network ??= Constants.bitcoin;

    if (seed.length < Constants.minSeedLength) {
      throw ArgumentError(Constants.errorSeedTooShort);
    }

    if (seed.length > Constants.maxSeedLength) {
      throw ArgumentError(Constants.errorSeedTooLong);
    }

    final i = hmacSHA512(utf8.encode(Constants.bitcoinSeed), seed);
    final il = i.sublist(0, Constants.keyLength);
    final ir = i.sublist(Constants.keyLength);

    return Bip32Keys.fromPrivateKey(il, ir, network: network);
  }

  Bip32Keys derive(int index) {
    if (index > Constants.uint32Max || index < 0) {
      throw ArgumentError(Constants.errorExpectedUInt32);
    }

    final isHardened = index >= Constants.highestBit;
    final data = Uint8List(37);
    if (isHardened) {
      if (isNeutered) {
        throw ArgumentError(Constants.errorMissingPrivateKeyHardened);
      }
      data[0] = 0x00;
      data.setRange(1, 33, private!);
      data.buffer.asByteData().setUint32(33, index);
    } else {
      data.setRange(0, 33, public);
      data.buffer.asByteData().setUint32(33, index);
    }

    final i = hmacSHA512(chainCode, data);
    final il = i.sublist(0, 32);
    final ir = i.sublist(32);

    if (!ecc.isPrivate(il)) return derive(index + 1);

    late Bip32Keys hd;
    if (!isNeutered) {
      final ki = ecc.privateAdd(private!, il);
      if (ki == null) return derive(index + 1);
      hd = Bip32Keys.fromPrivateKey(ki, ir, network: network);
    } else {
      final ki = ecc.pointAddScalar(public, il, true);
      if (ki == null) return derive(index + 1);
      hd = Bip32Keys.fromPublicKey(ki, ir, network: network);
    }

    hd.depth = depth + 1;
    hd.index = index;
    hd.parentFingerprint = fingerprint.buffer.asByteData().getUint32(0);
    return hd;
  }

  Bip32Keys deriveHardened(int index) {
    if (index > Constants.uint31Max || index < 0) {
      throw ArgumentError(Constants.errorExpectedUInt31);
    }

    return derive(index + Constants.highestBit);
  }

  Bip32Keys derivePath(String path) {
    if (!Constants.bip32PathRegex.hasMatch(path)) {
      throw ArgumentError(Constants.errorExpectedBip32Path);
    }

    var splitPath = path.split('/');
    if (splitPath[0] == Constants.masterPrefix) {
      if (parentFingerprint != Constants.defaultParentFingerprint) {
        throw ArgumentError(Constants.errorExpectedMasterGotChild);
      }
      splitPath = splitPath.sublist(1);
    }

    return splitPath.fold(this, (Bip32Keys prevHd, String indexStr) {
      int index;
      if (indexStr.substring(indexStr.length - 1) == "'") {
        index = int.parse(indexStr.substring(0, indexStr.length - 1));
        return prevHd.deriveHardened(index);
      }
      index = int.parse(indexStr);
      return prevHd.derive(index);
    });
  }

  Uint8List sign(Uint8List hash) => ecc.sign(hash, private!);

  bool verify(Uint8List hash, Uint8List signature) {
    return ecc.verify(hash, public, signature);
  }

  String toBase58({Bip32Network? overrideNetwork}) {
    final network = overrideNetwork ?? this.network;
    final version =
        isNeutered ? network.version.public : network.version.private;

    final buffer = Uint8List(78);
    final bytes = buffer.buffer.asByteData();
    bytes.setUint32(0, version);
    bytes.setUint8(4, depth);
    bytes.setUint32(5, parentFingerprint);
    bytes.setUint32(9, index);
    buffer.setRange(13, 45, chainCode);

    if (!isNeutered) {
      bytes.setUint8(45, 0);
      buffer.setRange(46, 78, private!);
    } else {
      buffer.setRange(45, 78, public);
    }

    return bs58check.encode(buffer);
  }

  String toWIF() {
    if (private == null) throw ArgumentError(Constants.errorMissingPrivateKey);

    return wif.encode(
      wif.WIF(
        version: network.wif,
        privateKey: private!,
        compressed: true,
      ),
    );
  }
}
