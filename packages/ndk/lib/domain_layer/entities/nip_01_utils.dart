import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../data_layer/models/nip_01_event_model.dart';
import '../../shared/isolates/isolate_manager.dart';
import '../../shared/nips/nip01/bip340.dart';
import '../../shared/nips/nip13/nip13.dart';
import 'nip_01_event.dart';

class Nip01Utils {
  /// create event and calculate id \
  /// [returns] event with calculated id
  static Nip01Event createEventCalculateId({
    required String pubKey,
    required int kind,
    required List<List<String>> tags,
    required String content,
    int createdAt = 0,
  }) {
    final id = calculateEventIdSync(
      pubKey: pubKey,
      createdAt: createdAt,
      kind: kind,
      tags: tags,
      content: content,
    );

    final event = Nip01Event(
      id: id,
      pubKey: pubKey,
      kind: kind,
      tags: tags,
      content: content,
      createdAt: createdAt,
      sources: [],
    );

    return event;
  }

  /// checks if event id is valid, including proof of work if present
  static bool isIdValid(Nip01Event event) {
    // Validate event data
    if (event.id !=
        calculateEventIdSync(
          pubKey: event.pubKey,
          createdAt: event.createdAt,
          kind: event.kind,
          tags: event.tags,
          content: event.content,
        )) {
      return false;
    }
    // Validate proof of work if present
    if (!Nip13.validateEvent(event)) {
      return false;
    }
    return true;
  }

  /// Calculate event id synchronously
  static String calculateEventIdSync({
    required String pubKey,
    required int createdAt,
    required int kind,
    required List<dynamic> tags,
    required String content,
  }) {
    return calculateId(
      Nip01Event(
        id: '',
        pubKey: pubKey,
        createdAt: createdAt,
        kind: kind,
        tags:
            List<List<String>>.from(tags.map((tag) => List<String>.from(tag))),
        content: content,
        sig: null,
        validSig: null,
        sources: [],
      ),
    );
  }

  /// Calculate event id asynchronously running in an isolate
  static Future<String> calculateEventId({
    required String publicKey,
    required int createdAt,
    required int kind,
    required List<dynamic> tags,
    required String content,
  }) async {
    final id =
        await IsolateManager.instance.runInComputeIsolate<Nip01Event, String>(
      calculateId,
      Nip01Event(
        pubKey: publicKey,
        createdAt: createdAt,
        kind: kind,
        tags:
            List<List<String>>.from(tags.map((tag) => List<String>.from(tag))),
        content: content,
      ),
    );
    return id;
  }

  static String calculateId(Nip01Event event) {
    final model = Nip01EventModel.fromEntity(event);
    final jsonData = json.encode([
      0,
      model.pubKey,
      model.createdAt,
      model.kind,
      model.tags,
      model.content
    ]);
    final bytes = utf8.encode(jsonData);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// this method signs the event with the provided private key
  /// mainly used for testing purposes, please use the account usecase to sign events!
  static Nip01Event signWithPrivateKey({
    required Nip01Event event,
    required String privateKey,
  }) {
    String? id = event.id;
    id ??= calculateId(event);
    final signature = Bip340.sign(
      id,
      privateKey,
    );
    return event.copyWith(sig: signature, validSig: true);
  }
}
