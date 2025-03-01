// This file is automatically generated, so please do not edit it.
// @generated by `flutter_rust_bridge`@ 2.8.0.

// ignore_for_file: invalid_use_of_internal_member, unused_import, unnecessary_import

import '../frb_generated.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

Future<bool> verifyNostrEvent(
        {required String eventIdHex,
        required String pubKeyHex,
        required BigInt createdAt,
        required int kind,
        required List<List<String>> tags,
        required String content,
        required String signatureHex}) =>
    RustLib.instance.api.crateApiEventVerifierVerifyNostrEvent(
        eventIdHex: eventIdHex,
        pubKeyHex: pubKeyHex,
        createdAt: createdAt,
        kind: kind,
        tags: tags,
        content: content,
        signatureHex: signatureHex);

Future<bool> verifySchnorrSignature(
        {required String pubKeyHex,
        required String eventIdHex,
        required String signatureHex}) =>
    RustLib.instance.api.crateApiEventVerifierVerifySchnorrSignature(
        pubKeyHex: pubKeyHex,
        eventIdHex: eventIdHex,
        signatureHex: signatureHex);

/// * hashes the given params, in nostr this is the id
/// * [return] hash / nostrId
///
Future<String> hashEventData(
        {required String pubkey,
        required BigInt createdAt,
        required int kind,
        required List<List<String>> tags,
        required String content}) =>
    RustLib.instance.api.crateApiEventVerifierHashEventData(
        pubkey: pubkey,
        createdAt: createdAt,
        kind: kind,
        tags: tags,
        content: content);
