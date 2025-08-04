import 'wallet_cashu_quote.dart';

class WalletCashuQuoteMelt {
  final String request;
  final String quoteId;
  final int amount;
  final int? feeReserve;
  final bool paid;
  final int? expiry;
  final String mintUrl;
  final CashuQuoteState state;
  final String unit;

  WalletCashuQuoteMelt({
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

  factory WalletCashuQuoteMelt.fromServerMap({
    required Map<String, dynamic> json,
    required String mintUrl,
    String? request,
  }) {
    return WalletCashuQuoteMelt(
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
}
