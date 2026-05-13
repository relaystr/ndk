// coverage:ignore-file

// ignore_for_file: constant_identifier_names

import 'package:bs58check/bs58check.dart' as bs58check;
import 'package:convert/convert.dart';

class Bip32Version {
  final int public;
  final int private;

  const Bip32Version({required this.public, required this.private});
}

class Bip32Network {
  final int wif;
  final Bip32Version version;

  const Bip32Network({required this.wif, required this.version});
}

enum Slip132 {
  mainnetBip44SingleSig(
    network: Bip32Network(
      wif: 0x80,
      version: Bip32Version(public: 0x0488b21e, private: 0x0488ade4),
    ),
  ),
  mainnetBip49SingleSig(
    network: Bip32Network(
      wif: 0x80,
      version: Bip32Version(public: 0x049d7cb2, private: 0x049d7878),
    ),
  ),
  mainnetBip84SingleSig(
    network: Bip32Network(
      wif: 0x80,
      version: Bip32Version(public: 0x04b24746, private: 0x04b2430c),
    ),
  ),
  mainnetBip49MultiSig(
    network: Bip32Network(
      wif: 0x80,
      version: Bip32Version(public: 0x0295b43f, private: 0x0295b005),
    ),
  ),
  mainnetBip84MultiSig(
    network: Bip32Network(
      wif: 0x80,
      version: Bip32Version(public: 0x02aa7ed3, private: 0x02aa7a99),
    ),
  ),
  testnetBip44SingleSig(
    network: Bip32Network(
      wif: 0xef,
      version: Bip32Version(public: 0x043587cf, private: 0x04358394),
    ),
  ),
  testnetBip49SingleSig(
    network: Bip32Network(
      wif: 0xef,
      version: Bip32Version(public: 0x044a5262, private: 0x044a4e28),
    ),
  ),
  testnetBip84SingleSig(
    network: Bip32Network(
      wif: 0xef,
      version: Bip32Version(public: 0x045f1cf6, private: 0x045f18bc),
    ),
  ),
  testnetBip49MultiSig(
    network: Bip32Network(
      wif: 0xef,
      version: Bip32Version(public: 0x024289ef, private: 0x024285b5),
    ),
  ),
  testnetBip84MultiSig(
    network: Bip32Network(
      wif: 0xef,
      version: Bip32Version(public: 0x02575483, private: 0x02575048),
    ),
  );

  const Slip132({required this.network});

  final Bip32Network network;

  static Slip132 parsePublicKey(String input) {
    input = input.trim();
    final bytes = bs58check.decode(input);
    final version = hex.encode(bytes.sublist(0, 4));

    for (final slip132 in Slip132.values) {
      if (slip132.network.version.public == int.parse(version, radix: 16)) {
        return slip132;
      }
    }

    throw 'Invalid SLIP-132 format: $input';
  }

  static Slip132? tryParse(String input) {
    try {
      return parsePublicKey(input);
    } catch (_) {
      return null;
    }
  }
}
