// ignore_for_file: camel_case_types

import 'nwc_response.dart';

/// Represents the result of a 'make_invoice' response.
class MakeInvoiceResponse extends NwcResponse {
  /// The type of the invoice "incoming" for invoices, "outgoing" for payments.
  final String type;

  /// The bolt11 invoice.
  final String invoice;

  /// The description of the invoice.
  final String description;

  /// The hash of the invoice description.
  final String descriptionHash;

  /// The preimage of the invoice.
  final String preimage;

  /// The payment hash of the invoice.
  final String paymentHash;

  /// The amount of the invoice (in MSATs)
  final int amountMsat;

  /// The amount of the invoice (in SATS)
  get amountSat => amountMsat ~/ 1000;

  /// The fees paid for the invoice (in MSATs).
  final int feesPaid;

  /// The timestamp when the invoice/payment was created.
  final int createdAt;

  /// The timestamp when the invoice/payment expires.
  final int? expiresAt;

  /// The timestamp when the invoice was settled (optional).

  final int? settledAt;

  MakeInvoiceResponse({
    required this.type,
    required this.invoice,
    required this.description,
    required this.descriptionHash,
    required this.preimage,
    required this.paymentHash,
    required this.amountMsat,
    required this.feesPaid,
    required this.createdAt,
    this.expiresAt,
    this.settledAt,
    required super.resultType,
  });

  factory MakeInvoiceResponse.deserialize(Map<String, dynamic> input) {
    if (!input.containsKey('result')) {
      throw Exception('Invalid input');
    }

    Map<String, dynamic> result = input['result'] as Map<String, dynamic>;

    return MakeInvoiceResponse(
      type: result['type'] as String,
      invoice: result['invoice'] as String,
      description: result['description'] as String,
      descriptionHash: result.containsKey('description_hash')
          ? result['description_hash'] as String
          : '',
      preimage:
          result.containsKey('preimage') ? result['preimage'] as String : '',
      paymentHash: result.containsKey('payment_hash')
          ? result['payment_hash'] as String
          : '',
      amountMsat: result['amount'] as int,
      feesPaid:
          result.containsKey('feeds_paid') ? result['fees_paid'] as int : 0,
      createdAt: result['created_at'] as int,
      expiresAt: result['expires_at'] as int?,
      settledAt: result['settled_at'] as int?, // optional
      resultType: input['result_type'] as String,
    );
  }
}
