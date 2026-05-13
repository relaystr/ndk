import '../../../entities.dart';

class CashuSpendingResult {
  final CashuToken token;
  final CashuWalletTransaction transaction;

  CashuSpendingResult({
    required this.token,
    required this.transaction,
  });
}
