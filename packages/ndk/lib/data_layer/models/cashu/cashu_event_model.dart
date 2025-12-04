import 'dart:convert';

import '../../../domain_layer/entities/cashu/cashu_event_content.dart';
import '../../../domain_layer/entities/nip_01_event.dart';
import '../../../domain_layer/entities/cashu/cashu_event.dart';
import '../../../domain_layer/repositories/event_signer.dart';

class CashuEventModel extends CashuEvent {
  CashuEventModel({
    required super.mints,
    required super.walletPrivkey,
    required super.userPubkey,
  });

  /// creates a nostr event based on the WalletCashuEvent data
  Future<Nip01Event> createNostrEvent({
    required EventSigner signer,
  }) async {
    final encryptedContent = await signer.encryptNip44(
        plaintext: jsonEncode(
          CashuEventContent(privKey: walletPrivkey, mints: mints)
              .toCashuEventContent(),
        ),
        recipientPubKey: userPubkey);

    if (encryptedContent == null) {
      throw Exception("could not encrypt cashu wallet event");
    }

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return Nip01Event(
      pubKey: userPubkey,
      tags: [],
      kind: CashuEvent.kWalletKind,
      createdAt: now,
      content: encryptedContent,
    );
  }

  /// creates a WalletCashuEvent from a nip01Event
  Future<CashuEventModel> fromNip01Event({
    required Nip01Event nostrEvent,
    required EventSigner signer,
  }) async {
    final decryptedContent = await signer.decryptNip44(
      ciphertext: nostrEvent.content,
      senderPubKey: nostrEvent.pubKey,
    );
    if (decryptedContent == null) {
      throw Exception("could not decrypt cashu wallet event");
    }
    final jsonContent = jsonDecode(decryptedContent);

    final extractedContent =
        CashuEventContent.fromCashuEventContent(jsonContent);

    return CashuEventModel(
      walletPrivkey: extractedContent.privKey,
      mints: extractedContent.mints,
      userPubkey: nostrEvent.pubKey,
    );
  }
}
