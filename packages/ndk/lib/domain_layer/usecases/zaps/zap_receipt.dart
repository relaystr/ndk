import 'dart:convert';

import 'package:ndk/domain_layer/entities/nip_01_event.dart';

class ZapReceipt {
  static const KIND = 9735;

  int? paidAt;
  String? pubKey;
  String? bolt11;
  String? preimage;
  String? zapRequestJson;
  String? recipient;
  String? eventId;
  String? zapContent;
  String? sender;
  String? anon;

  ZapReceipt(
      this.paidAt,
      this.pubKey,
      this.bolt11,
      this.preimage,
      this.zapRequestJson,
      this.recipient,
      this.eventId,
      this.zapContent,
      this.sender);

  ZapReceipt.fromEvent(Nip01Event event) {
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
      if (zapRequestJson != null) {
        try {
          Map map = jsonDecode(zapRequestJson!);
          zapContent = map['content'];
          sender = map['pubkey'];
        } catch (_) {
          zapContent = '';
        }
      }
      List<String>? splitStrings = anon?.split('_');
      if (splitStrings != null && splitStrings.length == 2) {
        // /// recipient decrypt
        // try {
        //   String contentBech32 = splitStrings[0];
        //   String ivBech32 = splitStrings[1];
        //   String? encryptedContent = bech32Decode(contentBech32,
        //       maxLength: contentBech32.length)['data'];
        //   String? iv =
        //       bech32Decode(ivBech32, maxLength: ivBech32.length)['data'];
        //
        //   String encryptedContentBase64 =
        //       base64Encode(hexToBytes(encryptedContent!));
        //   String ivBase64 = base64Encode(hexToBytes(iv!));
        //
        //   String eventString = await Nip4.decryptContent(
        //       '$encryptedContentBase64?iv=$ivBase64',
        //       recipient!,
        //       myPubkey,
        //       privkey);
        //
        //   /// try to use sender decrypt
        //   if (eventString.isEmpty) {
        //     String derivedPrivkey =
        //         generateKeyPair(recipient, event.createdAt, privkey);
        //     eventString = await Nip4.decryptContent('$encryptedContent?iv=$iv',
        //         recipient, bip340.getPublicKey(derivedPrivkey), derivedPrivkey);
        //   }
        //   if (eventString.isNotEmpty) {
        //     Event privEvent = await Event.fromJson(jsonDecode(eventString));
        //     sender = privEvent.pubkey;
        //     content = privEvent.content;
        //   }
        // } catch (_) {}
      }
    } else {
      throw Exception("${event.kind} is not nip57 compatible");
    }
  }

  bool isValid(String invoice) {
    return bolt11 == invoice;
    // TODO:
    //  - The zap receipt event's pubkey MUST be the same as the recipient's lnurl provider's nostrPubkey (retrieved in step 1 of the protocol flow).
    //  - The invoiceAmount contained in the bolt11 tag of the zap receipt MUST equal the amount tag of the zap request (if present).
    //  - The lnurl tag of the zap request (if present) SHOULD equal the recipient's lnurl.
    //  - SHA256(description) MUST match the description hash in the bolt11 invoice.
  }

  @override
  String toString() {
    return 'ZapReceipt(paidAt: $paidAt, pubKey: $pubKey, bolt11: $bolt11, preimage: $preimage, description: $zapRequestJson, recipient: $recipient, eventId: $eventId, zapContent: $zapContent, sender: $sender, anon: $anon)';
  }
}
