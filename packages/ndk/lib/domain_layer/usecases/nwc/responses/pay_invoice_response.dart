// ignore_for_file: camel_case_types

import 'nwc_response.dart';

/// Represents the result of an pay_invoice response.
class PayInvoiceResponse extends NwcResponse {
  /// The preimage of the paid invoice.
  final String? preimage;

  /// The fees paid for the invoice (in MSATs).
  final int feesPaid;

  PayInvoiceResponse(
      {this.preimage, required super.resultType, required this.feesPaid});

  factory PayInvoiceResponse.deserialize(Map<String, dynamic> input) {
    if (!input.containsKey('result')) {
      throw Exception('Invalid input');
    }

    Map<String, dynamic> result = input['result'] as Map<String, dynamic>;

    return PayInvoiceResponse(
      preimage: result['preimage'] as String?,
      resultType: input['result_type'] as String,
      feesPaid:
          result.containsKey('fees_paid') ? result['fees_paid'] as int : 0,
    );
  }
}
