import 'dart:convert';

import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip04/nip04.dart';
import 'package:ndk/domain_layer/usecases/nwc/consts/nwc_method.dart';
import 'get_balance.dart';
import 'get_info.dart';
import 'list_transactions.dart';
import 'lookup_invoice.dart';
import 'make_invoice.dart';
import 'multi_pay_invoice.dart';
import 'multi_pay_keysend.dart';
import 'pay_invoice.dart';
import 'pay_keysend.dart';
import '../tlv_record.dart';

import '../consts/transaction_type.dart';

/// NWC request
class NwcRequest {
  final NwcMethod method;

  const NwcRequest({
    required this.method,
  });

  factory NwcRequest.fromEvent(
      Nip01Event event, String contentDecryptionPrivateKey) {
    final connectionPubkey = event.pubKey;
    final decryptedContent = Nip04.decrypt(
      event.content,
      contentDecryptionPrivateKey,
      connectionPubkey,
    );

    final content = jsonDecode(decryptedContent);
    final method = content['method'] as String;
    final params = content['params'] as Map<String, dynamic>? ?? {};

    return NwcRequest.fromMap({
      'method': method,
      'created_at': event.createdAt,
      ...params,
    });
  }

  factory NwcRequest.fromMap(Map<String, dynamic> map) {
    final method = NwcMethod.fromPlaintext(map['method'] as String);

    // Handling for standard methods
    switch (method) {
      case NwcMethod.GET_INFO:
        return GetInfoRequest();
      case NwcMethod.GET_BALANCE:
        return GetBalanceRequest();
      case NwcMethod.MAKE_INVOICE:
        return MakeInvoiceRequest(
          amountMsat: map['amount'] as int,
          description: map['description'] as String?,
          descriptionHash: map['description_hash'] as String?,
          expiry: map['expiry'] as int?,
        );
      case NwcMethod.PAY_INVOICE:
        return PayInvoiceRequest(
          invoice: map['invoice'] as String,
        );
      case NwcMethod.MULTI_PAY_INVOICE:
        final invoices = (map['invoices'] as List)
            .map((e) => MultiPayInvoiceRequestInvoicesElement(
                  invoice: e['invoice'] as String,
                  amountMsat: e['amount'] as int,
                ))
            .toList();
        return MultiPayInvoiceRequest(
          invoices: invoices,
        );
      case NwcMethod.PAY_KEYSEND:
        return PayKeysendRequest(
          amountMsat: map['amount'] as int,
          pubkey: map['pubkey'] as String,
          preimage: map['preimage'] as String?,
          tlvRecords: (map['tlv_records'] as List)
              .map((e) => TlvRecord.fromMap(e as Map<String, dynamic>))
              .toList(),
        );
      case NwcMethod.MULTI_PAY_KEYSEND:
        final keysends = (map['keysends'] as List)
            .map((e) => MultiPayKeysendRequestInvoicesElement(
                  pubkey: e['pubkey'] as String,
                  amountMsat: e['amount'] as int,
                  preimage: e['preimage'] as String?,
                  tlvRecords: (e['tlv_records'] as List)
                      .map((e) => TlvRecord.fromMap(e as Map<String, dynamic>))
                      .toList(),
                ))
            .toList();
        return MultiPayKeysendRequest(
          keysends: keysends,
        );
      case NwcMethod.LOOKUP_INVOICE:
        return LookupInvoiceRequest(
          paymentHash: map['payment_hash'] as String?,
          invoice: map['invoice'] as String?,
        );
      case NwcMethod.LIST_TRANSACTIONS:
        return ListTransactionsRequest(
          from: map['from'] as int?,
          until: map['until'] as int?,
          limit: map['limit'] as int?,
          offset: map['offset'] as int?,
          unpaid: map['unpaid'] as bool,
          type: map['type'] == null
              ? null
              : TransactionType.fromValue(
                  map['type'] as String,
                ),
        );
      default:
        throw Exception("unknown method");
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'method': method.name,
    };
  }
}
