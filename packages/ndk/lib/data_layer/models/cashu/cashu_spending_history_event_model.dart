import 'dart:convert';

import '../../../domain_layer/entities/cashu/cashu_spending_history_event.dart';
import '../../../domain_layer/entities/cashu/cashu_spending_history_event_content.dart';
import '../../../domain_layer/entities/nip_01_event.dart';
import '../../../domain_layer/repositories/event_signer.dart';

class CashuSpendingHistoryEventModel extends CashuSpendingHistoryEvent {
  CashuSpendingHistoryEventModel({
    required super.direction,
    required super.amount,
    required super.tokens,
  });

  Future<CashuSpendingHistoryEventModel> fromNip01Event({
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
        CashuSpendingHistoryEventContent.fromJson(jsonContent);

    return CashuSpendingHistoryEventModel(
      amount: extractedContent.amount,
      direction: extractedContent.direction,
      tokens: extractedContent.tokens,
    );
  }
}
