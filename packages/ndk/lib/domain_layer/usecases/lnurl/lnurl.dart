import 'dart:convert';

import 'package:bech32/bech32.dart';
import 'package:http/http.dart' as http;
import 'package:ndk/domain_layer/repositories/event_signer.dart';
import 'package:ndk/domain_layer/usecases/zaps/zap_request.dart';
import 'package:ndk/shared/nips/nip19/nip19.dart';

import '../../../shared/logger/logger.dart';
import 'lnurl_response.dart';

/// LN URL utilities
abstract class Lnurl {

  /// transform a lud16 of format name@domain.com to https://domain.com/.well-known/lnurlp/name
  static String? getLud16LinkFromLud16(String lud16) {
    var strs = lud16.split("@");
    if (strs.length < 2) {
      return null;
    }

    var username = strs[0];
    var domainname = strs[1];

    return "https://$domainname/.well-known/lnurlp/$username";
  }

  // static String? getLnurlFromLud16(String lud16) {
  //   var link = getLud16LinkFromLud16(lud16);
  //   var uint8List = utf8.encode(link!);
  //   var data = Nip19.convertBits(uint8List, 8, 5, true);
  //
  //   var encoder = Bech32Encoder();
  //   Bech32 input = Bech32("lnurl", data);
  //   var lnurl = encoder.convert(input, 2000);
  //
  //   return lnurl.toUpperCase();
  // }
  //

  /// fetch LNURL response from given link
  static Future<LnurlResponse?> getLnurlResponse(String link,
      {http.Client? client}) async {
    Uri uri = Uri.parse(link).replace(scheme: 'https');

    try {
      var response = await (client ?? http.Client()).get(uri);
      final decodedResponse =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (client == null) {
        // Only close if we created the client
        client?.close();
      }
      return LnurlResponse.fromJson(decodedResponse);
    } catch (e) {
      Logger.log.d(e);
      return null;
    }
  }

  /// creates an invoice with an optional zap request encoded if signer, pubKey & relays are non empty
  static Future<String?> getInvoiceCode({
    required String lud16Link,
    required int sats,
    EventSigner? signer,
    String? pubKey,
    String? eventId,
    Iterable<String>? relays,
    String? pollOption,
    String? comment,
    http.Client? client
  }) async {
    var lnurlResponse = await getLnurlResponse(lud16Link,client: client);
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

    if (lnurlResponse.doesAllowsNostr &&
        pubKey != null &&
        pubKey.isNotEmpty &&
        relays != null &&
        relays.isNotEmpty &&
        signer != null) {
      var tags = [
        ["relays", ...relays],
        ["amount", amount.toString()],
        ["p", pubKey],
      ];
      if (eventId != null) {
        tags.add(["e", eventId]);
      }
      if (pollOption != null) {
        tags.add(["poll_option", pollOption]);
      }
      var event = ZapRequest(
          pubKey: signer.getPublicKey(), tags: tags, content: eventContent);
      await signer.sign(event);
      if (event.sig == '') {
        return null;
      }
      Logger.log.d(jsonEncode(event));
      var eventStr = Uri.encodeQueryComponent(jsonEncode(event));
      callback += "&nostr=$eventStr";
    }

    Logger.log.d("getInvoice callback $callback");

    Uri uri = Uri.parse(callback);

    try {
      var response = await (client ?? http.Client()).get(uri);
      final decodedResponse =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return decodedResponse["pr"];
    } catch (e) {
      Logger.log.d(e);
    }

    return null;
  }
}
