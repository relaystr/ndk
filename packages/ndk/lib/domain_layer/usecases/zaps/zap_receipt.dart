import 'dart:convert';

import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/domain_layer/usecases/lnurl/lnurl.dart';

import '../../../shared/logger/logger.dart';

class ZapReceipt {
  static const KIND = 9735;

  int? paidAt;
  int? amountSats;
  String? pubKey;
  String? bolt11;
  String? preimage;
  String? recipient;
  String? eventId;
  String? comment;
  String? sender;
  String? anon;
  String? lnurl;

  ZapReceipt.fromEvent(Nip01Event event) {
    String? zapRequestJson;
    pubKey = event.pubKey;
    if (event.kind == 9735) {
      for (var tag in event.tags) {
        if (tag[0] == 'bolt11') bolt11 = tag[1];
        if (tag[0] == 'preimage') preimage = tag[1];
        if (tag[0] == 'description') zapRequestJson = tag[1];
        if (tag[0] == 'p') recipient = tag[1];
        if (tag[0] == 'e') eventId = tag[1];
        if (tag[0] == 'anon') anon = tag[1];
        if (tag[0] == 'P') sender = tag[1];
      }
      paidAt = event.createdAt;
      if (zapRequestJson != null && zapRequestJson.isNotEmpty) {
        Nip01Event event = Nip01Event.fromJson(jsonDecode(zapRequestJson));
        comment = event.content;
        sender = event.pubKey;
        lnurl = event.getFirstTag('lnurl');
        String? amountString = event.getFirstTag('amount');
        if (amountString != null && amountString.isNotEmpty) {
          try {
            double? amount = double.tryParse(amountString);
            if (amount != null) {
              amountSats = (amount / 1000).round();
            }
          } catch (e) {
            Logger.log.w(e);
          }
        }
      }
      if (amountSats == null && bolt11 != null) {
        amountSats = Lnurl.getAmountFromBolt11(bolt11!);
      }
      List<String>? splitStrings = anon?.split('_');
      if (splitStrings != null && splitStrings.length == 2) {
        // TODO decrypt private zap
      }
    } else {
      throw Exception("${event.kind} is not nip57 compatible");
    }
  }

  /// is valid
  bool isValid({required String nostrPubKey, required String recipientLnurl}) {
    //  - The zap receipt event's pubkey MUST be the same as the recipient's lnurl provider's nostrPubkey (retrieved in step 1 of the protocol flow).
    if (pubKey != nostrPubKey) {
      return false;
    }
    //  - The invoiceAmount contained in the bolt11 tag of the zap receipt MUST equal the amount tag of the zap request (if present).
    if (bolt11!=null && bolt11!.isNotEmpty) {
      if (amountSats != Lnurl.getAmountFromBolt11(bolt11!)) {
        return false;
      }
    }
    //  - The lnurl tag of the zap request (if present) SHOULD equal the recipient's lnurl.
    if (lnurl!=null && lnurl!.isNotEmpty) {
      if (lnurl != recipientLnurl) {
        return false;
      }
    }
    return true;
  }

  @override
  String toString() {
    return 'ZapReceipt(paidAt: $paidAt, pubKey: $pubKey, bolt11: $bolt11, preimage: $preimage, amount: $amountSats, recipient: $recipient, eventId: $eventId, comment: $comment, sender: $sender, anon: $anon)';
  }
}
