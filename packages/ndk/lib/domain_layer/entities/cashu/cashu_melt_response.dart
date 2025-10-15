import 'cashu_blinded_signature.dart';
import 'cashu_quote.dart';

class CashuMeltResponse {
  final String qoteId;
  final String mintUrl;
  final CashuQuoteState state;
  final String? paymentPreimage;
  final List<CashuBlindedSignature> change;

  CashuMeltResponse({
    required this.qoteId,
    required this.mintUrl,
    required this.state,
    this.paymentPreimage,
    required this.change,
  });

  factory CashuMeltResponse.fromServerMap({
    required Map<String, dynamic> map,
    required String mintUrl,
    required String quoteId,
  }) {
    return CashuMeltResponse(
      qoteId: quoteId,
      mintUrl: mintUrl,
      state: CashuQuoteState.fromValue(map['state'] as String),
      paymentPreimage: map['payment_preimage'] as String?,
      change: (map['change'] as List<dynamic>?)
              ?.map((e) => CashuBlindedSignature.fromServerMap(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
