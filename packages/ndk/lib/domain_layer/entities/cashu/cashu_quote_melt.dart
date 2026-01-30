import 'cashu_quote.dart';

class CashuQuoteMelt {
  final String request;
  final String quoteId;
  final int amount;
  final int? feeReserve;
  final bool paid;
  final int? expiry;
  final String mintUrl;
  final CashuQuoteState state;
  final String unit;

  CashuQuoteMelt({
    required this.quoteId,
    required this.amount,
    required this.feeReserve,
    required this.paid,
    required this.expiry,
    required this.mintUrl,
    required this.state,
    required this.unit,
    required this.request,
  });

  factory CashuQuoteMelt.fromServerMap({
    required Map<String, dynamic> json,
    required String mintUrl,
    String? request,
  }) {
    return CashuQuoteMelt(
      quoteId: json['quote'] as String,
      amount: json['amount'] as int,
      unit: json['unit'] as String,
      state: CashuQuoteState.fromValue(json['state'] as String),
      expiry: json['expiry'] as int?,
      paid: json['paid'] != null ? json['paid'] as bool : false,
      feeReserve:
          (json['fee_reserve'] != null ? json['fee_reserve'] as int : 0),
      request:
          request ?? (json['request'] != null ? json['request'] as String : ''),
      mintUrl: mintUrl,
    );
  }

  factory CashuQuoteMelt.fromJson(Map<String, dynamic> json) {
    return CashuQuoteMelt(
      quoteId: json['quoteId'] as String,
      amount: json['amount'] as int,
      unit: json['unit'] as String,
      state: CashuQuoteState.fromValue(json['state'] as String),
      expiry: json['expiry'] as int?,
      paid: json['paid'] as bool,
      feeReserve: json['feeReserve'] as int?,
      request: json['request'] as String,
      mintUrl: json['mintUrl'] as String,
    );
  }

  Map<String, Object> toJson() {
    return {
      'quoteId': quoteId,
      'amount': amount,
      'feeReserve': feeReserve ?? 0,
      'paid': paid,
      'expiry': expiry ?? 0,
      'mintUrl': mintUrl,
      'state': state.value,
      'unit': unit,
      'request': request,
    };
  }
}
