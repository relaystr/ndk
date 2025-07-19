import '../tuple.dart';
import 'wallet_cashu_spending_history_event.dart';

class WalletCashuSpendingHistoryEventContent {
  final CashuSpendDirection direction;
  final int amount;

  /// tokens < TOKEN,SPEND_MARKER >
  final List<Tuple<String, CashuSpendMarker>> tokens;

  WalletCashuSpendingHistoryEventContent({
    required this.direction,
    required this.amount,
    required this.tokens,
  });

  /// extracts data from plain lists
  factory WalletCashuSpendingHistoryEventContent.fromJson(
    List<List<String>> jsonList,
  ) {
    CashuSpendDirection? direction;
    int? amount;
    List<Tuple<String, CashuSpendMarker>> tokens = [];

    for (final item in jsonList) {
      if (item.isEmpty) continue;

      switch (item.first) {
        case 'direction':
          if (item.length > 1) {
            direction = CashuSpendDirection.fromValue(item[1]);
          }
          break;

        case 'amount':
          if (item.length > 1) {
            amount = int.tryParse(item[1]);
          }
          break;

        case 'e':
          if (item.length >= 4) {
            final tokenId = item[1];
            final markerString = item[3];

            CashuSpendMarker marker = CashuSpendMarker.fromValue(markerString);

            tokens.add(Tuple(tokenId, marker));
          }
          break;
      }
    }
    if (direction == null) {
      throw Exception("err parsing direction");
    }

    if (amount == null) {
      throw Exception("err parsing amount");
    }

    return WalletCashuSpendingHistoryEventContent(
      direction: direction,
      amount: amount,
      tokens: tokens,
    );
  }
}
