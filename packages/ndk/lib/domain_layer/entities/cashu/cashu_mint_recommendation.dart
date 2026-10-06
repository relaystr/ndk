import 'cashu_mint_info.dart';

/// Community information for a Cashu mint, aggregated from NIP-87 events.
class CashuMintRecommendation {
  final String url;
  final CashuMintInfo? mintInfo;
  final double? averageRating;
  final int reviewsCount;
  final List<CashuMintReview> reviews;

  const CashuMintRecommendation({
    required this.url,
    this.mintInfo,
    required this.averageRating,
    required this.reviewsCount,
    this.reviews = const [],
  });

  CashuMintRecommendation copyWith({CashuMintInfo? mintInfo}) {
    return CashuMintRecommendation(
      url: url,
      mintInfo: mintInfo ?? this.mintInfo,
      averageRating: averageRating,
      reviewsCount: reviewsCount,
      reviews: reviews,
    );
  }
}

/// Latest NIP-87 review published by one reviewer for one Cashu mint.
class CashuMintReview {
  final String reviewerPubkey;
  final int createdAt;
  final int? rating;
  final String comment;

  const CashuMintReview({
    required this.reviewerPubkey,
    required this.createdAt,
    required this.rating,
    required this.comment,
  });
}
