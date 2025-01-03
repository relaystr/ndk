import 'dart:convert';

import 'package:ndk/domain_layer/repositories/lnurl_transport.dart';
import 'package:ndk/ndk.dart';

import 'lnurl_response.dart';

/// LN URL utilities
class Lnurl {
  final LnurlTransport _transport;

  ///
  Lnurl({
    required LnurlTransport transport,
  }) : _transport = transport;

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
  Future<LnurlResponse?> getLnurlResponse(String link) async {
    return await _transport.requestLnurlResponse(link);
  }

  /// fetch invoice from callback
  Future<InvoiceResponse?> fetchInvoice(
      {required LnurlResponse lnurlResponse,
      required int amountSats,
      ZapRequest? zapRequest,
      String? comment}) async {
    var callback = lnurlResponse.callback!;
    if (callback.contains("?")) {
      callback += "&";
    } else {
      callback += "?";
    }

    final amount = amountSats * 1000;
    callback += "amount=$amount";

    if (comment != null && comment.trim() != '') {
      var commentNum = lnurlResponse.commentAllowed;
      if (commentNum != null) {
        if (commentNum < comment.length) {
          comment = comment.substring(0, commentNum);
        }
        callback += "&comment=${Uri.encodeQueryComponent(comment)}";
      }
    }

    // ZAP ?
    if (lnurlResponse.doesAllowsNostr &&
        zapRequest != null &&
        zapRequest.sig.isNotEmpty) {
      Logger.log.d(jsonEncode(zapRequest));
      var eventStr = Uri.encodeQueryComponent(jsonEncode(zapRequest));
      callback += "&nostr=$eventStr";
    }

    Logger.log.d("getInvoice callback $callback");

    try {
      var response = await _transport.fetchInvoice(callback);
      String invoice = response!["pr"];
      return InvoiceResponse(
          invoice: invoice,
          amountSats: amountSats,
          nostrPubkey: lnurlResponse.nostrPubkey);
    } catch (e) {
      Logger.log.d(e);
    }
    return null;
  }

  /// extract amount from bolt11 in sats
  static int getAmountFromBolt11(String bolt11) {
    final numStr = _subUntil(bolt11, "lnbc", "1p");
    if (numStr.isNotEmpty) {
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

  static String _subUntil(String content, String before, String end) {
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
