import 'bip32_slip132.dart';

/// Centralized configuration for BIP32 keys library
class Constants {
  // Network configurations
  static final bitcoin = Slip132.mainnetBip44SingleSig.network;
  static final testnet = Slip132.testnetBip44SingleSig.network;

  // BIP32 constants
  static const int highestBit = 0x80000000;
  static const int uint31Max = 2147483647; // 2^31 - 1
  static const int uint32Max = 4294967295; // 2^32 - 1

  // Key and data lengths
  static const int keyLength = 32;
  static const int chainCodeLength = 32;
  static const int maxDepth = 255;
  static const int extendedKeyLength = 78;
  static const int versionBytesLength = 4;
  static const int depthLength = 1;
  static const int fingerprintLength = 4;
  static const int indexLength = 4;
  static const int privateKeyPrefixLength = 1;

  // HMAC and cryptographic constants
  static const String bitcoinSeed = "Bitcoin seed";
  static const int hmacKeyLength = 128;
  static const int hmacOutputLength = 64;
  static const int hmacDataLength = 37;

  // Serialization offsets
  static const int versionOffset = 0;
  static const int depthOffset = 4;
  static const int parentFingerprintOffset = 5;
  static const int indexOffset = 9;
  static const int chainCodeOffset = 13;
  static const int privateKeyOffset = 46;
  static const int publicKeyOffset = 45;

  // Validation constants
  static const int minSeedLength = 16;
  static const int maxSeedLength = 64;
  static const int minDepth = 0;
  static const int maxIndex = uint32Max;

  // Error messages
  static const String errorInvalidBufferLength = "Invalid buffer length";
  static const String errorInvalidNetworkVersion = "Invalid network version";
  static const String errorInvalidParentFingerprint =
      "Invalid parent fingerprint";
  static const String errorInvalidIndex = "Invalid index";
  static const String errorInvalidPrivateKey = "Invalid private key";
  static const String errorMissingPrivateKey = "Missing private key";
  static const String errorMissingPrivateKeyHardened =
      "Missing private key for hardened child key";
  static const String errorExpectedUInt32 = "Expected UInt32";
  static const String errorExpectedUInt31 = "Expected UInt31";
  static const String errorExpectedBip32Path = "Expected BIP32 Path";
  static const String errorExpectedMasterGotChild =
      "Expected master, got child";
  static const String errorSeedTooShort = "Seed should be at least 128 bits";
  static const String errorSeedTooLong = "Seed should be at most 512 bits";
  static const String errorPointNotOnCurve = "Point is not on the curve";
  static const String errorPrivateKeyLength =
      "Expected property private of type Buffer(Length: 32)";
  static const String errorPrivateKeyRange = "Private key not in range [1, n]";

  // SLIP-132 specific constants
  static const int slip132VersionBytesLength = 4;
  static const String errorCannotConvertPrivateKey =
      "Cannot convert private key to SLIP-132 format";
  static const String errorCannotGetFingerprintFromPrivate =
      "Cannot get fingerprint from private key";
  static const String errorCannotGetParentFingerprintFromPrivate =
      "Cannot get parent fingerprint from private key";

  // Path validation
  static final RegExp bip32PathRegex = RegExp(r"^(m\/)?(\d+'?\/)*\d+'?$");
  static const String masterPrefix = "m";
  static const String hardenedSuffix = "'";

  // Default values
  static const int defaultDepth = 0;
  static const int defaultIndex = 0;
  static const int defaultParentFingerprint = 0x00000000;
  static const int defaultPrivateKeyPrefix = 0x00;
}
