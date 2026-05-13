import '../../usecases/cashu/cashu_keypair.dart';

class CashuQuote {
  final String quoteId;
  final String request;
  final int amount;
  final String unit;
  final CashuQuoteState state;

  final CashuKeypair quoteKey;

  /// expires in seconds
  final int expiry;
  final String mintUrl;

  CashuQuote({
    required this.quoteId,
    required this.request,
    required this.amount,
    required this.unit,
    required this.state,
    required this.expiry,
    required this.mintUrl,
    required this.quoteKey,
  });

  factory CashuQuote.fromServerMap({
    required Map<String, dynamic> map,
    required String mintUrl,
    required CashuKeypair quoteKey,
  }) {
    return CashuQuote(
      quoteId: map['quote'] as String,
      request: map['request'] as String,
      amount: map['amount'] as int,
      unit: map['unit'] as String,
      state: CashuQuoteState.fromValue(map['state'] as String),
      expiry: map['expiry'] as int,
      mintUrl: mintUrl,
      quoteKey: quoteKey,
    );
  }

  factory CashuQuote.fromJson(Map<String, dynamic> json) {
    return CashuQuote(
      quoteId: json['quoteId'] as String,
      request: json['request'] as String,
      amount: json['amount'] as int,
      unit: json['unit'] as String,
      state: CashuQuoteState.fromValue(json['state'] as String),
      expiry: json['expiry'] as int,
      mintUrl: json['mintUrl'] as String,
      quoteKey: CashuKeypair.fromJson(json['quoteKey'] as Map<String, dynamic>),
    );
  }

  Map<String, Object> toJson() {
    return {
      'quoteId': quoteId,
      'request': request,
      'amount': amount,
      'unit': unit,
      'state': state.value,
      'expiry': expiry,
      'mintUrl': mintUrl,
      'quoteKey': quoteKey.toJson(),
    };
  }
}

enum CashuQuoteState {
  unpaid('UNPAID'),

  pending('PENDING'),

  paid('PAID');

  final String value;

  const CashuQuoteState(this.value);

  factory CashuQuoteState.fromValue(String value) {
    return CashuQuoteState.values.firstWhere(
      (t) => t.value == value,
      orElse: () => CashuQuoteState.unpaid,
    );
  }
}
