import 'dart:typed_data';

import 'package:cbor/cbor.dart';
import 'package:ur/ur.dart';
import 'package:ur/ur_encoder.dart';
import 'package:ur/ur_decoder.dart';

import '../../../shared/logger/logger.dart';
import '../../entities/cashu/cashu_token.dart';

/// Encoder and decoder for Cashu tokens using UR (Uniform Resources) format.
/// This implements NUT-16 for animated QR codes support.
///
/// Based on the UR specification: https://developer.blockchaincommons.com/ur/
class CashuTokenUrEncoder {
  /// The UR type for Cashu tokens
  static const String urType = 'bytes';

  /// Encodes a Cashu token to a single-part UR string.
  /// Use this for tokens that can fit in a single QR code.
  ///
  /// Returns a UR-formatted string like: "ur:bytes/..."
  static String encodeSinglePart({
    required CashuToken token,
  }) {
    try {
      final json = token.toV4Json();
      final myCbor = CborValue(json);
      final cborBytes = Uint8List.fromList(cbor.encode(myCbor));

      final ur = UR(urType, cborBytes);
      return UREncoder.encode(ur);
    } catch (e) {
      Logger.log.f('Error encoding token to UR: $e');
      rethrow;
    }
  }

  /// Decodes a single-part UR string back to a Cashu token.
  ///
  /// Returns null if the UR string is invalid or cannot be decoded.
  static CashuToken? decodeSinglePart(String urString) {
    try {
      final ur = URDecoder.decode(urString);

      if (ur.type != urType) {
        Logger.log.f('Invalid UR type: expected $urType, got ${ur.type}');
        return null;
      }

      final cborValue = cbor.decode(ur.cbor);
      final json = cborValue.toJson() as Map;

      return CashuToken.fromV4Json(json);
    } catch (e) {
      Logger.log.f('Error decoding UR to token: $e');
      return null;
    }
  }

  /// Creates a UREncoder for generating animated QR codes (multi-part URs).
  /// Use this for large tokens that need to be split across multiple QR codes.
  ///
  /// [token] - The Cashu token to encode
  /// [maxFragmentLen] - Maximum size of each fragment (default: 100 bytes)
  ///
  /// Returns a UREncoder that can generate multiple UR parts via nextPart()
  static UREncoder createMultiPartEncoder({
    required CashuToken token,
    int maxFragmentLen = 100,
    int firstSeqNum = 0,
    int minFragmentLen = 10,
  }) {
    try {
      final json = token.toV4Json();
      final myCbor = CborValue(json);
      final cborBytes = Uint8List.fromList(cbor.encode(myCbor));

      final ur = UR(urType, cborBytes);
      return UREncoder(
        ur,
        maxFragmentLen,
        firstSeqNum: firstSeqNum,
        minFragmentLen: minFragmentLen,
      );
    } catch (e) {
      Logger.log.f('Error creating multi-part UR encoder: $e');
      rethrow;
    }
  }

  /// Creates a URDecoder for decoding animated QR codes (multi-part URs).
  /// Feed each scanned UR part to the decoder using receivePart() until complete.
  ///
  /// Returns a URDecoder that accumulates parts until the token is complete
  static URDecoder createMultiPartDecoder() {
    return URDecoder();
  }

  /// Decodes a complete multi-part UR back to a Cashu token.
  /// Call this after the URDecoder indicates it's complete (isComplete() == true).
  ///
  /// Returns null if the decoder is not complete or decoding fails.
  static CashuToken? decodeFromMultiPartDecoder(URDecoder decoder) {
    try {
      if (!decoder.isComplete()) {
        Logger.log.f('Decoder is not complete yet');
        return null;
      }

      final result = decoder.resultMessage();
      if (result == null || result is! UR) {
        Logger.log.f('Invalid decoder result');
        return null;
      }

      final ur = result as UR;
      if (ur.type != urType) {
        Logger.log.f('Invalid UR type: expected $urType, got ${ur.type}');
        return null;
      }

      final cborValue = cbor.decode(ur.cbor);
      final json = cborValue.toJson() as Map;

      return CashuToken.fromV4Json(json);
    } catch (e) {
      Logger.log.f('Error decoding multi-part UR to token: $e');
      return null;
    }
  }
}
