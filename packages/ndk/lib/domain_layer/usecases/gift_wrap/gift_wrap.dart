import 'dart:convert';

import '../../../data_layer/models/nip_01_event_model.dart';
import '../../../data_layer/repositories/signers/bip340_event_signer.dart';
import '../../entities/nip_01_event.dart';
import '../../repositories/event_signer.dart';
import '../accounts/accounts.dart';
import '../../../shared/nips/nip01/bip340.dart';

class GiftWrap {
  static const int kSealEventKind = 13;
  static const int kGiftWrapEventkind = 1059;

  final Accounts accounts;

  GiftWrap({required this.accounts});

  /// Returns the signer to use for signing operations.
  /// Uses [customSigner] if provided, otherwise falls back to logged-in account's signer.
  EventSigner _getSigner({EventSigner? customSigner}) {
    if (customSigner != null) {
      return customSigner;
    }
    final account = accounts.getLoggedAccount();
    if (account == null) {
      throw Exception("cannot sign without account or custom signer");
    }
    return account.signer;
  }

  /// converts a Nip01Event to a giftWrap Nip01Event \
  /// [rumor] the event you want to wrap \
  /// [recipientPubkey] the reciever of the rumor \
  /// [customSigner] optional signer to use instead of the logged-in account's signer \
  /// [returns] the wrapped event
  Future<Nip01Event> toGiftWrap({
    required Nip01Event rumor,
    required String recipientPubkey,
    EventSigner? customSigner,
  }) async {
    final sealedRumor = await sealRumor(
      rumor: rumor,
      recipientPubkey: recipientPubkey,
      customSigner: customSigner,
    );

    final giftWrap = await wrapEvent(
      recipientPublicKey: recipientPubkey,
      sealEvent: sealedRumor,
    );
    return giftWrap;
  }

  /// Unwraps a gift-wrapped event to retrieve the original rumor \
  /// [giftWrap] the gift-wrapped event to unwrap \
  /// [customSigner] optional signer to use instead of the logged-in account's signer \
  /// [returns] the original rumor event
  Future<Nip01Event> fromGiftWrap({
    required Nip01Event giftWrap,
    EventSigner? customSigner,
  }) async {
    if (giftWrap.kind != kGiftWrapEventkind) {
      throw Exception("Event is not a gift wrap (kind:1059)");
    }

    final sealEvent = await unwrapEvent(
      wrappedEvent: giftWrap,
      customSigner: customSigner,
    );
    final rumor = await unsealRumor(
      sealedEvent: sealEvent,
      customSigner: customSigner,
    );

    return rumor;
  }

  /// Creates a rumor (unsigned event)
  Future<Nip01Event> createRumor({
    String? customPubkey,
    required String content,
    required int kind,
    required List<List<String>> tags,
  }) async {
    final myPubkey = accounts.getPublicKey();

    final usedPubkey = customPubkey ?? myPubkey;

    if (usedPubkey == null) {
      throw Exception("cannot create crumor: no pubkey provided");
    }

    final Nip01Event rumor = Nip01Event(
      pubKey: usedPubkey,
      kind: kind,
      tags: tags,
      content: content,
    );

    return rumor;
  }

  /// Seals a rumor (creates a kind:13 event)
  ///
  /// [customSigner] optional signer to use instead of the logged-in account's signer
  Future<Nip01Event> sealRumor({
    required Nip01Event rumor,
    required String recipientPubkey,
    EventSigner? customSigner,
  }) async {
    final signer = _getSigner(customSigner: customSigner);

    final encryptedContent = await signer.encryptNip44(
      plaintext: Nip01EventModel.fromEntity(rumor).toJsonString(),
      recipientPubKey: recipientPubkey,
    );

    if (encryptedContent == null) {
      throw Exception("encrypted content is null");
    }

    final sealEvent = Nip01Event(
      pubKey: signer.getPublicKey(),
      kind: kSealEventKind,
      tags: [],
      content: encryptedContent,
    );

    return sealEvent;
  }

  /// Unseals a sealed event to retrieve the rumor
  ///
  /// [customSigner] optional signer to use instead of the logged-in account's signer
  Future<Nip01Event> unsealRumor({
    required Nip01Event sealedEvent,
    EventSigner? customSigner,
  }) async {
    final signer = _getSigner(customSigner: customSigner);

    // Now decrypt the seal to get the rumor
    final decryptedRumorJson = await signer.decryptNip44(
      ciphertext: sealedEvent.content,
      senderPubKey: sealedEvent.pubKey,
    );

    if (decryptedRumorJson == null) {
      throw Exception("Failed to decrypt seal");
    }

    // Parse the rumor event
    final Map<String, dynamic> rumorJson = jsonDecode(decryptedRumorJson);
    final rumor = Nip01EventModel.fromJson(rumorJson);

    return rumor;
  }

  /// wraps a sealed msg \
  /// [recipientPublicKey] the reciever of the rumor \
  /// [sealEvent] not wrapped event \
  /// [returns] giftWrapEvent
  static Future<Nip01Event> wrapEvent({
    required String recipientPublicKey,
    required Nip01Event sealEvent,
    List<List<String>>? additionalTags,
  }) async {
    // Generate a random one-time-use keypair
    final ephemeralKeys = Bip340.generatePrivateKey();
    final ephemeralSigner = Bip340EventSigner(
      privateKey: ephemeralKeys.privateKey,
      publicKey: ephemeralKeys.publicKey,
    );

    final encryptedSeal = await ephemeralSigner.encryptNip44(
      plaintext: Nip01EventModel.fromEntity(sealEvent).toJsonString(),
      recipientPubKey: recipientPublicKey,
    );

    if (encryptedSeal == null) {
      throw Exception("encryptedSeal is null");
    }

    final tags = <List<String>>[
      ['p', recipientPublicKey]
    ];

    // Add any additional tags if provided
    if (additionalTags != null) {
      tags.addAll(additionalTags);
    }

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Create the gift wrap event with ephemeral keys
    final giftWrapEvent = Nip01Event(
      kind: kGiftWrapEventkind,
      content: encryptedSeal,
      tags: tags,
      createdAt: now,
      pubKey: ephemeralKeys.publicKey,
    );

    // Sign with ephemeral key
    final signature = Bip340.sign(giftWrapEvent.id, ephemeralKeys.privateKey!);

    final gWEventSigned = giftWrapEvent.copyWith(sig: signature);

    return gWEventSigned;
  }

  /// Unwraps a gift wrap to get the seal event
  ///
  /// [customSigner] optional signer to use instead of the logged-in account's signer
  Future<Nip01Event> unwrapEvent({
    required Nip01Event wrappedEvent,
    EventSigner? customSigner,
  }) async {
    final signer = _getSigner(customSigner: customSigner);

    final decryptedEventJson = await signer.decryptNip44(
      ciphertext: wrappedEvent.content,
      senderPubKey: wrappedEvent.pubKey,
    );

    if (decryptedEventJson == null) {
      throw Exception("Failed to decrypt gift wrap");
    }

    // Parse the seal event
    final Map<String, dynamic> sealJson = jsonDecode(decryptedEventJson);
    final event = Nip01EventModel.fromJson(sealJson);
    return event;
  }
}
