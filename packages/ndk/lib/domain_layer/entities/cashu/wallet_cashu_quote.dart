import '../../../shared/nips/nip01/key_pair.dart';

class WalletCashuQuote {
  final String quoteId;
  final String request;
  final int amount;
  final String unit;
  final CashuQuoteState state;

  final KeyPair quoteKey;

  /// expires in seconds
  final int expiry;
  final String mintURL;

  WalletCashuQuote({
    required this.quoteId,
    required this.request,
    required this.amount,
    required this.unit,
    required this.state,
    required this.expiry,
    required this.mintURL,
    required this.quoteKey,
  });

  factory WalletCashuQuote.fromServerMap({
    required Map<String, dynamic> map,
    required String mintURL,
    required KeyPair quoteKey,
  }) {
    return WalletCashuQuote(
      quoteId: map['quote'] as String,
      request: map['request'] as String,
      amount: map['amount'] as int,
      unit: map['unit'] as String,
      state: CashuQuoteState.fromValue(map['state'] as String),
      expiry: map['expiry'] as int,
      mintURL: mintURL,
      quoteKey: quoteKey,
    );
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
