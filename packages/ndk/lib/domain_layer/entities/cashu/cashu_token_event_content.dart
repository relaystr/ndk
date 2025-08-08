import 'cashu_token_event.dart';

class CashuTokenEventContent {
  final String mintUrl;
  final List<CashuProof> proofs;
  final List<String> deletedIds;

  CashuTokenEventContent({
    required this.mintUrl,
    required this.proofs,
    required this.deletedIds,
  });

  /// extracts data from plain lists
  factory CashuTokenEventContent.fromJson(
    Map<String, dynamic> jsonList,
  ) {
    return CashuTokenEventContent(
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
