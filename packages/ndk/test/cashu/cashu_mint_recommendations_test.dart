import 'package:ndk/ndk.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_mint_info.dart';
import 'package:test/test.dart';

void main() {
  group('CashuMintRecommendations.fromEvents', () {
    test('keeps latest review per author and ranks recommendations', () {
      const mintA = 'https://mint-a.example';
      const mintB = 'https://mint-b.example';
      final recommendations = CashuMintRecommendations.fromEvents(
        announcements: [
          _event(kind: 38172, pubkey: 'a', tags: const [
            ['u', mintA]
          ]),
          _event(kind: 38172, pubkey: 'b', tags: const [
            ['u', mintB]
          ]),
        ],
        reviews: [
          _review(mintA, pubkey: 'one', createdAt: 10, content: '[2/5] old'),
          _review(mintA, pubkey: 'one', createdAt: 20, content: '[5/5] great'),
          _review(mintA, pubkey: 'two', createdAt: 15, content: '[3/5] okay'),
          _review(mintB, pubkey: 'three', createdAt: 30, content: '[5/5] good'),
        ],
      );

      expect(recommendations.map((item) => item.url), [mintA, mintB]);
      expect(recommendations.first.reviewsCount, 2);
      expect(recommendations.first.averageRating, 4);
      expect(recommendations.first.reviews.first.comment, 'great');
    });

    test('rejects non-HTTPS URLs and keeps unrated comments', () {
      final recommendations = CashuMintRecommendations.fromEvents(
        announcements: const [],
        reviews: [
          _review(
            'http://insecure.example',
            pubkey: 'one',
            createdAt: 10,
            content: '[5/5] ignored',
          ),
          _review(
            'https://mint.example/',
            pubkey: 'two',
            createdAt: 20,
            content: 'Useful comment without rating',
          ),
        ],
      );

      expect(recommendations, hasLength(1));
      expect(recommendations.single.url, 'https://mint.example');
      expect(recommendations.single.averageRating, isNull);
      expect(recommendations.single.reviews.single.comment,
          'Useful comment without rating');
    });

    test('ignores unrelated events and ranks equal review counts by rating',
        () {
      const mintA = 'https://mint-a.example';
      const mintB = 'https://mint-b.example';
      final recommendations = CashuMintRecommendations.fromEvents(
        announcements: [
          _event(kind: 1, pubkey: 'ignored', tags: const [
            ['u', 'https://ignored.example']
          ]),
          _event(kind: 38172, pubkey: 'a', tags: const [
            ['u'],
            ['u', mintA]
          ]),
          _event(kind: 38172, pubkey: 'b', tags: const [
            ['u', mintB]
          ]),
        ],
        reviews: [
          _event(
            kind: 38000,
            pubkey: 'ignored',
            tags: const [
              ['u', mintA]
            ],
          ),
          _review(mintA, pubkey: 'one', createdAt: 10, content: '[6/5] bad'),
          _review(mintB, pubkey: 'two', createdAt: 20, content: '[4/5] good'),
        ],
      );

      expect(recommendations.map((item) => item.url), [mintB, mintA]);
      expect(recommendations.last.averageRating, isNull);
      expect(recommendations.last.reviews.single.comment, 'bad');
    });

    test('copyWith preserves review data while attaching mint info', () {
      const review = CashuMintReview(
        reviewerPubkey: 'reviewer',
        createdAt: 42,
        rating: 5,
        comment: 'Reliable',
      );
      const recommendation = CashuMintRecommendation(
        url: 'https://mint.example',
        averageRating: 5,
        reviewsCount: 1,
        reviews: [review],
      );
      final mintInfo = CashuMintInfo(name: 'Example Mint', nuts: const {});

      final enriched = recommendation.copyWith(mintInfo: mintInfo);

      expect(enriched.url, recommendation.url);
      expect(enriched.mintInfo, same(mintInfo));
      expect(enriched.averageRating, recommendation.averageRating);
      expect(enriched.reviewsCount, recommendation.reviewsCount);
      expect(enriched.reviews, same(recommendation.reviews));
      expect(enriched.copyWith().mintInfo, same(mintInfo));
    });
  });
}

Nip01Event _review(
  String mintUrl, {
  required String pubkey,
  required int createdAt,
  required String content,
}) {
  return _event(
    kind: 38000,
    pubkey: pubkey,
    createdAt: createdAt,
    tags: [
      const ['k', '38172'],
      ['u', mintUrl],
    ],
    content: content,
  );
}

Nip01Event _event({
  required int kind,
  required String pubkey,
  required List<List<String>> tags,
  String content = '',
  int createdAt = 1,
}) {
  return Nip01Event(
    pubKey: pubkey.padRight(64, '0'),
    kind: kind,
    tags: tags,
    content: content,
    createdAt: createdAt,
  );
}
