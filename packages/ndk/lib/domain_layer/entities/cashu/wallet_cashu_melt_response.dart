import 'wallet_cashu_blinded_signature.dart';
import 'wallet_cashu_quote.dart';

class WalletCashuMeltResponse {
  final String qoteId;
  final String mintUrl;
  final CashuQuoteState state;
  final String? paymentPreimage;
  final List<WalletCashuBlindedSignature> change;

  WalletCashuMeltResponse({
    required this.qoteId,
    required this.mintUrl,
    required this.state,
    this.paymentPreimage,
    required this.change,
  });

  factory WalletCashuMeltResponse.fromServerMap({
    required Map<String, dynamic> map,
    required String mintUrl,
    required String quoteId,
  }) {
    return WalletCashuMeltResponse(
      qoteId: quoteId,
      mintUrl: mintUrl,
      state: CashuQuoteState.fromValue(map['state'] as String),
      paymentPreimage: map['payment_preimage'] as String?,
      change: (map['change'] as List<Map<String, dynamic>>)
          .map((e) => WalletCashuBlindedSignature.fromServerMap(e))
          .toList(),
    );
  }
}
