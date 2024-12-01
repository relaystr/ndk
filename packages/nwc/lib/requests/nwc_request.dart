import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip04/nip04.dart';
import 'package:ndk_nwc/consts/nwc_method.dart';
import 'package:ndk_nwc/tlv_record.dart';

import '../consts/transaction_type.dart';

sealed class NwcRequest {
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

// Subclass for requests to get info like supported methods
@immutable
class GetInfoRequest extends NwcRequest {
  const GetInfoRequest() : super(method: NwcMethod.GET_INFO);
}

// Subclass for requests to get balance
@immutable
class GetBalanceRequest extends NwcRequest {
  const GetBalanceRequest() : super(method: NwcMethod.GET_BALANCE);
}

// Subclass for requests to make a bolt11 invoice
class MakeInvoiceRequest extends NwcRequest {
  final int amountSat;
  final String? description;
  final String? descriptionHash;
  final int? expiry;

  const MakeInvoiceRequest({
    required amountMsat,
    this.description,
    this.descriptionHash,
    this.expiry,
  })  : amountSat = amountMsat ~/ 1000,
        super(method: NwcMethod.MAKE_INVOICE);

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'params': {
        'amount': amountSat * 1000,
        if (description != null) 'description': description,
        if (descriptionHash != null) 'description_hash': descriptionHash,
        if (expiry != null) 'expiry': expiry,
      }
    };
  }
}

// Subclass for requests to pay a bolt11 invoice
class PayInvoiceRequest extends NwcRequest {
  final String invoice;

  const PayInvoiceRequest({
    required this.invoice,
  }) : super(method: NwcMethod.PAY_INVOICE);

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'params': {
        'invoice': invoice,
      }
    };
  }
}

// Subclass for requests to pay multiple bolt11 invoices
class MultiPayInvoiceRequest extends NwcRequest {
  final List<MultiPayInvoiceRequestInvoicesElement> invoices;

  const MultiPayInvoiceRequest({
    required this.invoices,
  }) : super(method: NwcMethod.MULTI_PAY_INVOICE);

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'params': {
        'invoices': invoices.map((e) => e.toMap()).toList(),
      }
    };
  }
}

class MultiPayInvoiceRequestInvoicesElement {
  final String invoice;
  final int amountSat;

  const MultiPayInvoiceRequestInvoicesElement({
    required this.invoice,
    required amountMsat,
  }) : amountSat = amountMsat ~/ 1000;

  Map<String, dynamic> toMap() {
    return {
      'params': {
        'invoice': invoice,
        'amount': amountSat * 1000,
      }
    };
  }
}

// Subclass for requests for a keysend payment
class PayKeysendRequest extends NwcRequest {
  final int amountSat;
  final String pubkey;
  final String? preimage;
  final List<TlvRecord>? tlvRecords;

  const PayKeysendRequest({
    required amountMsat,
    required this.pubkey,
    this.preimage,
    this.tlvRecords,
  })  : amountSat = amountMsat ~/ 1000,
        super(method: NwcMethod.PAY_KEYSEND);

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'params': {
        'amount': amountSat * 1000,
        'pubkey': pubkey,
        if (preimage != null) 'preimage': preimage,
        'tlv_records': tlvRecords?.map((e) => e.toMap()).toList(),
      }
    };
  }
}

// Subclass for requests to pay multiple keysend payments
class MultiPayKeysendRequest extends NwcRequest {
  final List<MultiPayKeysendRequestInvoicesElement> keysends;

  const MultiPayKeysendRequest({
    required this.keysends,
  }) : super(method: NwcMethod.MULTI_PAY_KEYSEND);

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'params': {
        'keysends': keysends.map((e) => e.toMap()).toList(),
      }
    };
  }
}

class MultiPayKeysendRequestInvoicesElement  {
  final String pubkey;
  final int amountSat;
  final String? preimage;
  final List<TlvRecord>? tlvRecords;

  const MultiPayKeysendRequestInvoicesElement({
    required this.pubkey,
    required amountMsat,
    this.preimage,
    this.tlvRecords,
  }) : amountSat = amountMsat ~/ 1000;

  Map<String, dynamic> toMap() {
    return {
      'pubkey': pubkey,
      'amount': amountSat * 1000,
      if (preimage != null) 'preimage': preimage,
      'tlv_records': tlvRecords?.map((e) => e.toMap()).toList(),
    };
  }
}

// Subclass for requests to look up an invoice
class LookupInvoiceRequest extends NwcRequest {
  final String? paymentHash;
  final String? invoice;

  const LookupInvoiceRequest({
    this.paymentHash,
    this.invoice,
  }) : super(method: NwcMethod.LOOKUP_INVOICE);

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'params' : {
        if (paymentHash != null) 'payment_hash': paymentHash,
        if (invoice != null) 'invoice': invoice,
      }
    };
  }
}

// Subclass for requests to get a list of transactions
class ListTransactionsRequest extends NwcRequest {
  final int? from;
  final int? until;
  final int? limit;
  final int? offset;
  final bool unpaid;
  final TransactionType? type;

  const ListTransactionsRequest({
    this.from,
    this.until,
    this.limit,
    this.offset,
    this.unpaid = false,
    this.type,
  }) : super(method: NwcMethod.LIST_TRANSACTIONS);

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'params' : {
        if (from != null) 'from': from,
        if (until != null) 'until': until,
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
        'unpaid': unpaid,
        if (type != null) 'type': type!.name,
      }
    };
  }
}
