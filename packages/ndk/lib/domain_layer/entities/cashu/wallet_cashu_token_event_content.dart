import 'wallet_cashu_token_event.dart';

class WalletCashuTokenEventContent {
  final String mintUrl;
  final List<CashuProof> proofs;
  final List<String> deletedIds;

  WalletCashuTokenEventContent({
    required this.mintUrl,
    required this.proofs,
    required this.deletedIds,
  });

  /// extracts data from plain lists
  factory WalletCashuTokenEventContent.fromJson(
    Map<String, dynamic> jsonList,
  ) {
    return WalletCashuTokenEventContent(
      mintUrl: jsonList['mint'] as String,
      proofs: (jsonList['proofs'] as List<dynamic>)
          .map((proofJson) =>
              CashuProof.fromJson(proofJson as Map<String, dynamic>))
          .toList(),
      deletedIds: (jsonList['del'] as List<dynamic>?)
              ?.map((id) => id as String)
              .toList() ??
          [],
    );
  }
}
