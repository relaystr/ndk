import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';

import 'nip_01_event.dart';

/// AES-GCM encrypted bytes and the private metadata required by a NIP-17
/// kind-15 rumor.
class Nip17EncryptedFile {
  final Uint8List ciphertext;
  final String key;
  final String nonce;
  final String encryptedSha256;
  final String originalSha256;

  const Nip17EncryptedFile({
    required this.ciphertext,
    required this.key,
    required this.nonce,
    required this.encryptedSha256,
    required this.originalSha256,
  });

  int get size => ciphertext.length;
}

/// Parsed metadata carried only inside a NIP-17 kind-15 rumor.
class Nip17FileMetadata {
  static const String aesGcm = 'aes-gcm';

  final Uri url;
  final String mimeType;
  final String encryptionAlgorithm;
  final String decryptionKey;
  final String decryptionNonce;
  final String encryptedSha256;
  final String originalSha256;
  final int? size;
  final String? dimensions;

  const Nip17FileMetadata({
    required this.url,
    required this.mimeType,
    required this.encryptionAlgorithm,
    required this.decryptionKey,
    required this.decryptionNonce,
    required this.encryptedSha256,
    required this.originalSha256,
    this.size,
    this.dimensions,
  });

  factory Nip17FileMetadata.fromEncryptedFile({
    required Uri url,
    required String mimeType,
    required Nip17EncryptedFile encryptedFile,
    String? dimensions,
  }) {
    return Nip17FileMetadata(
      url: url,
      mimeType: mimeType,
      encryptionAlgorithm: aesGcm,
      decryptionKey: encryptedFile.key,
      decryptionNonce: encryptedFile.nonce,
      encryptedSha256: encryptedFile.encryptedSha256,
      originalSha256: encryptedFile.originalSha256,
      size: encryptedFile.size,
      dimensions: dimensions,
    );
  }

  /// Parses a kind-15 rumor, rejecting missing or duplicated required tags.
  static Nip17FileMetadata? tryParse(Nip01Event rumor) {
    if (rumor.kind != 15 || rumor.sig != null) return null;

    final url = Uri.tryParse(rumor.content);
    final mimeType = _singleTag(rumor, 'file-type');
    final algorithm = _singleTag(rumor, 'encryption-algorithm');
    final key = _singleTag(rumor, 'decryption-key');
    final nonce = _singleTag(rumor, 'decryption-nonce');
    final encryptedHash = _singleTag(rumor, 'x');
    final originalHash = _singleTag(rumor, 'ox');
    if (url == null ||
        !url.hasScheme ||
        (url.scheme != 'https' && url.scheme != 'http') ||
        url.host.isEmpty ||
        mimeType == null ||
        mimeType.isEmpty ||
        algorithm != aesGcm ||
        key == null ||
        nonce == null ||
        encryptedHash == null ||
        originalHash == null ||
        !_sha256Pattern.hasMatch(encryptedHash) ||
        !_sha256Pattern.hasMatch(originalHash)) {
      return null;
    }

    final keyBytes = Nip17FileCrypto.tryDecodeParameter(
      key,
      allowedLengths: const {16, 32},
    );
    final nonceBytes = Nip17FileCrypto.tryDecodeParameter(
      nonce,
      allowedLengths: const {12, 16},
    );
    if (keyBytes == null ||
        (keyBytes.length != 16 && keyBytes.length != 32) ||
        nonceBytes == null ||
        (nonceBytes.length != 12 && nonceBytes.length != 16)) {
      return null;
    }

    final sizeValue = _optionalSingleTag(rumor, 'size');
    final size = sizeValue == null ? null : int.tryParse(sizeValue);
    if (sizeValue != null && (size == null || size <= 16)) return null;

    final dimensions = _optionalSingleTag(rumor, 'dim');
    if (dimensions != null && !_dimensionsPattern.hasMatch(dimensions)) {
      return null;
    }

    return Nip17FileMetadata(
      url: url,
      mimeType: mimeType,
      encryptionAlgorithm: aesGcm,
      decryptionKey: key,
      decryptionNonce: nonce,
      encryptedSha256: encryptedHash.toLowerCase(),
      originalSha256: originalHash.toLowerCase(),
      size: size,
      dimensions: dimensions,
    );
  }

  List<List<String>> toTags() => [
        ['file-type', mimeType],
        ['encryption-algorithm', encryptionAlgorithm],
        ['decryption-key', decryptionKey],
        ['decryption-nonce', decryptionNonce],
        ['x', encryptedSha256],
        ['ox', originalSha256],
        if (size != null) ['size', size.toString()],
        if (dimensions != null) ['dim', dimensions!],
      ];

  static String? _singleTag(Nip01Event rumor, String name) {
    final matches =
        rumor.tags.where((tag) => tag.isNotEmpty && tag[0] == name).toList();
    if (matches.length != 1 || matches.single.length != 2) return null;
    return matches.single[1];
  }

  static String? _optionalSingleTag(Nip01Event rumor, String name) {
    final matches =
        rumor.tags.where((tag) => tag.isNotEmpty && tag[0] == name).toList();
    if (matches.isEmpty) return null;
    if (matches.length != 1 || matches.single.length != 2) return '';
    return matches.single[1];
  }

  static final RegExp _sha256Pattern = RegExp(r'^[0-9a-fA-F]{64}$');
  static final RegExp _dimensionsPattern = RegExp(r'^[1-9][0-9]*x[1-9][0-9]*$');
}

/// NIP-17 interoperable AES-GCM file encryption.
///
/// Sending follows the convention used by Amethyst: AES-256-GCM, a fresh
/// 16-byte nonce, lowercase hex key/nonce tags, and a blob containing
/// ciphertext followed by the 16-byte authentication tag. Decryption also
/// accepts base64url parameters and 12-byte nonces used by older clients.
class Nip17FileCrypto {
  static const int _authenticationTagLength = 16;

  static Future<Nip17EncryptedFile> encrypt(Uint8List plaintext) async {
    final algorithm = AesGcm.with256bits(nonceLength: 16);
    final secretKey = await algorithm.newSecretKey();
    final keyBytes = await secretKey.extractBytes();
    final nonce = algorithm.newNonce();
    final box = await algorithm.encrypt(
      plaintext,
      secretKey: secretKey,
      nonce: nonce,
    );
    final ciphertext = Uint8List.fromList([
      ...box.cipherText,
      ...box.mac.bytes,
    ]);

    return Nip17EncryptedFile(
      ciphertext: ciphertext,
      key: _toHex(keyBytes),
      nonce: _toHex(nonce),
      encryptedSha256: sha256.convert(ciphertext).toString(),
      originalSha256: sha256.convert(plaintext).toString(),
    );
  }

  /// Verifies the encrypted hash before AES-GCM authentication and verifies
  /// the original hash after decryption.
  static Future<Uint8List> decrypt({
    required Uint8List ciphertext,
    required Nip17FileMetadata metadata,
  }) async {
    if (metadata.size != null && metadata.size != ciphertext.length) {
      throw const FormatException('Encrypted file size does not match');
    }
    if (sha256.convert(ciphertext).toString() != metadata.encryptedSha256) {
      throw const FormatException('Encrypted file hash does not match');
    }
    if (ciphertext.length <= _authenticationTagLength) {
      throw const FormatException('Encrypted file is too short');
    }

    final keyBytes = tryDecodeParameter(
      metadata.decryptionKey,
      allowedLengths: const {16, 32},
    );
    final nonce = tryDecodeParameter(
      metadata.decryptionNonce,
      allowedLengths: const {12, 16},
    );
    if (keyBytes == null ||
        (keyBytes.length != 16 && keyBytes.length != 32) ||
        nonce == null ||
        (nonce.length != 12 && nonce.length != 16)) {
      throw const FormatException('Invalid AES-GCM key or nonce');
    }

    final algorithm = keyBytes.length == 32
        ? AesGcm.with256bits(nonceLength: nonce.length)
        : AesGcm.with128bits(nonceLength: nonce.length);
    final macOffset = ciphertext.length - _authenticationTagLength;
    final box = SecretBox(
      ciphertext.sublist(0, macOffset),
      nonce: nonce,
      mac: Mac(ciphertext.sublist(macOffset)),
    );
    final plaintext = Uint8List.fromList(
      await algorithm.decrypt(box, secretKey: SecretKey(keyBytes)),
    );
    if (sha256.convert(plaintext).toString() != metadata.originalSha256) {
      throw const FormatException('Original file hash does not match');
    }
    return plaintext;
  }

  static Uint8List? tryDecodeParameter(
    String value, {
    Set<int>? allowedLengths,
  }) {
    try {
      if (_hexPattern.hasMatch(value) && value.length.isEven) {
        final decoded = Uint8List.fromList([
          for (var i = 0; i < value.length; i += 2)
            int.parse(value.substring(i, i + 2), radix: 16),
        ]);
        if (allowedLengths == null || allowedLengths.contains(decoded.length)) {
          return decoded;
        }
      }
      final decoded =
          Uint8List.fromList(base64Url.decode(base64Url.normalize(value)));
      if (allowedLengths != null && !allowedLengths.contains(decoded.length)) {
        return null;
      }
      return decoded;
    } catch (_) {
      return null;
    }
  }

  static String _toHex(List<int> bytes) =>
      bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

  static final RegExp _hexPattern = RegExp(r'^[0-9a-fA-F]+$');
}
