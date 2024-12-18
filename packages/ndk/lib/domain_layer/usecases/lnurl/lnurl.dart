import 'dart:convert';

import 'package:bech32/bech32.dart';
import 'package:http/http.dart' as http;
import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/domain_layer/repositories/event_signer.dart';
import 'package:ndk/domain_layer/usecases/zaps/zap_request.dart';
import 'package:ndk/shared/nips/nip19/nip19.dart';

import '../../../shared/logger/logger.dart';
import 'lnurl_response.dart';

// TODO make this an instance in ndk/Initialization
class Lnurl {
  static String? getLud16LinkFromLud16(String lud16) {
    var strs = lud16.split("@");
    if (strs.length < 2) {
      return null;
    }

    var username = strs[0];
    var domainname = strs[1];

    return "https://$domainname/.well-known/lnurlp/$username";
  }

  static String? getLnurlFromLud16(String lud16) {
    var link = getLud16LinkFromLud16(lud16);
    var uint8List = utf8.encode(link!);
    var data = Nip19.convertBits(uint8List, 8, 5, true);

    var encoder = Bech32Encoder();
    Bech32 input = Bech32("lnurl", data);
    var lnurl = encoder.convert(input, 2000);

    return lnurl.toUpperCase();
  }

  static Future<LnurlResponse?> getLnurlResponse(String link) async {
    Uri uri = Uri.parse(link).replace(scheme: 'https');

    try {
      var response = await http.get(uri);
      final decodedResponse =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return LnurlResponse.fromJson(decodedResponse);
    } catch (e) {
      Logger.log.d(e);
      return null;
    }
  }

  static Future<String?> getInvoiceCode({
    required String lud16Link,
    required int sats,
    required String recipientPubkey,
    required EventSigner signer,
    String? eventId,
    required Iterable<String> relays,
    String? pollOption,
    String? comment,
  }) async {
    var lnurlResponse = await getLnurlResponse(lud16Link);
    if (lnurlResponse == null) {
      return null;
    }

    var callback = lnurlResponse.callback!;
    if (callback.contains("?")) {
      callback += "&";
    } else {
      callback += "?";
    }

    var amount = sats * 1000;
    callback += "amount=$amount";

    String eventContent = "";
    if (comment != null && comment.trim() != '') {
      var commentNum = lnurlResponse.commentAllowed;
      if (commentNum != null) {
        if (commentNum < comment.length) {
          comment = comment.substring(0, commentNum);
        }
        callback += "&comment=${Uri.encodeQueryComponent(comment)}";
        eventContent = comment;
      }
    }

    var tags = [
      ["relays", ...relays],
      ["amount", amount.toString()],
      ["p", recipientPubkey],
    ];
    if (eventId != null) {
      tags.add(["e", eventId]);
    }
    if (pollOption != null) {
      tags.add(["poll_option", pollOption]);
    }
    var event = Nip01Event(
        pubKey: signer.getPublicKey(),
        kind: ZapRequest.KIND,
        tags: tags,
        content: eventContent);
    await signer.sign(event);
    if (event.sig != '') {
      return null;
    }
    Logger.log.d(jsonEncode(event));
    var eventStr = Uri.encodeQueryComponent(jsonEncode(event));
    callback += "&nostr=$eventStr";

    Logger.log.d("getInvoice callback $callback");

    Uri uri = Uri.parse(callback);

    try {
      var response = await http.get(uri);
      final decodedResponse =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return decodedResponse["pr"];
    } catch (e) {
      Logger.log.d(e);
    }

    return null;
  }

  static int getNumFromStr(String zapStr) {
    var numStr = subUntil(zapStr, "lnbc", "1p");
    if (numStr != '') {
      var numStrLength = numStr.length;
      if (numStrLength > 1) {
        var lastStr = numStr.substring(numStr.length - 1);
        var pureNumStr = numStr.substring(0, numStr.length - 1);
        var pureNum = int.tryParse(pureNumStr);
        if (pureNum != null) {
          if (lastStr == "p") {
            return (pureNum * 0.0001).round();
          } else if (lastStr == "n") {
            return (pureNum * 0.1).round();
          } else if (lastStr == "u") {
            return (pureNum * 100).round();
          } else if (lastStr == "m") {
            return (pureNum * 100000).round();
          }
        }
      }
    }
    return 0;
  }

  static String subUntil(String content, String before, String end) {
    var beforeLength = before.length;
    var index = content.indexOf(before);
    if (index < 0) {
      return "";
    }

    var index2 = content.indexOf(end, index + beforeLength);
    if (index2 <= 0) {
      return "";
    }

    return content.substring(index + beforeLength, index2);
  }
}
