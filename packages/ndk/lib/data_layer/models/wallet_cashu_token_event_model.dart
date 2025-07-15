import 'dart:convert';

import '../../domain_layer/entities/cashu/wallet_cashu_token_event.dart';
import '../../domain_layer/entities/cashu/wallet_cashu_token_event_content.dart';
import '../../domain_layer/entities/nip_01_event.dart';
import '../../domain_layer/repositories/event_signer.dart';

class WalletCashuTokenEventModel extends WalletCashuTokenEvent {
  WalletCashuTokenEventModel(
      {required super.mintUrl,
      required super.proofs,
      required super.deletedIds});

  Future<WalletCashuTokenEventModel> fromNip01Event({
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

    final extractedContent = WalletCashuTokenEventContent.fromJson(jsonContent);

    return WalletCashuTokenEventModel(
      mintUrl: extractedContent.mintUrl,
      proofs: extractedContent.proofs.toSet(),
      deletedIds: extractedContent.deletedIds.toSet(),
    );
  }
}
