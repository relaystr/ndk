import 'dart:convert';

import '../../../domain_layer/entities/nip_01_event.dart';
import '../../../domain_layer/usecases/accounts/accounts.dart';
import '../../../presentation_layer/ndk.dart';
import '../nip01/bip340.dart';

class GiftWrapService {
  static const int kSealEventKind = 13;
  static const int kGiftWrapEventkind = 1059;
  final Ndk ndk;

  final Accounts accounts;

  GiftWrapService(this.ndk, this.accounts);

  /// converts a Nip01Event to a giftWrap Nip01Event \
  /// [rumor] the event you want to wrap \
  /// [recipientPubkey] the reciever of the rumor \
  /// [returns] the wrapped event
  Future<Nip01Event> toGiftWrap({
    required Nip01Event rumor,
    required String recipientPubkey,
  }) async {
    final sealedRumor =
        await sealRumor(rumor: rumor, recipientPubkey: recipientPubkey);

    final giftWrap = await wrapSeal(
      recipientPublicKey: recipientPubkey,
      sealEvent: sealedRumor,
    );
    return giftWrap;
  }

  /// Unwraps a gift-wrapped event to retrieve the original rumor \
  /// [giftWrap] the gift-wrapped event to unwrap \
  /// [returns] the original rumor event
  Future<Nip01Event> fromGiftWrap({
    required Nip01Event giftWrap,
  }) async {
    if (giftWrap.kind != kGiftWrapEventkind) {
      throw Exception("Event is not a gift wrap (kind:1059)");
    }

    final account = accounts.getLoggedAccount();
    if (account == null) {
      throw Exception("Cannot decrypt without account");
    }

    // First, decrypt the gift wrap to get the seal
    final decryptedSealJson = await account.signer.decryptNip44(
      ciphertext: giftWrap.content,
      userPubkey: account.pubkey,
      senderPubKey: giftWrap.pubKey,
    );

    if (decryptedSealJson == null) {
      throw Exception("Failed to decrypt gift wrap");
    }

    // Parse the seal event
    final Map<String, dynamic> sealJson = jsonDecode(decryptedSealJson);
    final sealEvent = Nip01Event.fromJson(sealJson);

    if (sealEvent.kind != kSealEventKind) {
      throw Exception("Unwrapped event is not a seal (kind:13)");
    }

    // Now decrypt the seal to get the rumor
    final decryptedRumorJson = await account.signer.decryptNip44(
      ciphertext: sealEvent.content,
      userPubkey: account.pubkey,
      senderPubKey: sealEvent.pubKey,
    );

    if (decryptedRumorJson == null) {
      throw Exception("Failed to decrypt seal");
    }

    // Parse the rumor event
    final Map<String, dynamic> rumorJson = jsonDecode(decryptedRumorJson);
    final rumor = Nip01Event.fromJson(rumorJson);

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
  Future<Nip01Event> sealRumor({
    required Nip01Event rumor,
    required String recipientPubkey,
  }) async {
    final account = accounts.getLoggedAccount();
    if (account == null) {
      throw Exception("cannot sign without account");
    }

    final encryptedContent = await account.signer.encryptNip44(
      plaintext: jsonEncode(rumor),
      userPubkey: account.pubkey,
      recipientPubKey: recipientPubkey,
    );

    if (encryptedContent == null) {
      throw Exception("encrypted content is null");
    }

    final sealEvent = Nip01Event(
      pubKey: account.pubkey,
      kind: kSealEventKind,
      tags: [],
      content: encryptedContent,
    );

    return sealEvent;
  }

  /// wraps a sealed msg \
  /// [recipientPublicKey] the reciever of the rumor \
  /// [sealEvent] sealed event \
  /// [returns] giftWrapEvent
  Future<Nip01Event> wrapSeal({
    required String recipientPublicKey,
    required Nip01Event sealEvent,
    List<List<String>>? additionalTags,
  }) async {
    // Generate a random one-time-use keypair
    final ephemeralKeys = Bip340.generatePrivateKey();

    final account = accounts.getLoggedAccount();
    if (account == null) {
      throw Exception("cannot sign without account");
    }

    final encryptedSeal = await account.signer.encryptNip44(
      plaintext: jsonEncode(sealEvent),
      userPubkey: ephemeralKeys.publicKey,
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

    giftWrapEvent.sig = signature;

    return giftWrapEvent;
  }
}
