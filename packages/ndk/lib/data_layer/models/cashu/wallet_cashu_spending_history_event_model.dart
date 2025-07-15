import 'dart:convert';

import '../../../domain_layer/entities/cashu/wallet_cashu_spending_history_event.dart';
import '../../../domain_layer/entities/cashu/wallet_cashu_spending_history_event_content.dart';
import '../../../domain_layer/entities/nip_01_event.dart';
import '../../../domain_layer/repositories/event_signer.dart';

class WalletCashuSpendingHistoryEventModel
    extends WalletCashuSpendingHistoryEvent {
  WalletCashuSpendingHistoryEventModel({
    required super.direction,
    required super.amount,
    required super.tokens,
  });

  Future<WalletCashuSpendingHistoryEventModel> fromNip01Event({
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
        WalletCashuSpendingHistoryEventContent.fromJson(jsonContent);

    return WalletCashuSpendingHistoryEventModel(
      amount: extractedContent.amount,
      direction: extractedContent.direction,
      tokens: extractedContent.tokens,
    );
  }
}
