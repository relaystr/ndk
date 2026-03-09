import 'package:ndk/domain_layer/entities/wallet/wallet_type.dart';

import '../../../domain_layer/entities/wallet/wallet.dart';
import '../../../domain_layer/entities/wallet/wallet_transaction.dart';
import '../../../domain_layer/repositories/wallets_operations_repo.dart';
import '../../../domain_layer/usecases/cashu/cashu.dart';
import '../../../domain_layer/usecases/nwc/nwc.dart';
import '../../../domain_layer/usecases/nwc/responses/pay_invoice_response.dart';

class WalletsOperationsImpl implements WalletsOperationsRepo {
  final Cashu _cashuUseCase;
  final Nwc _nwcUseCase;

  WalletsOperationsImpl({
    required Cashu cashuUseCase,
    required Nwc nwcUseCase,
  })  : _cashuUseCase = cashuUseCase,
        _nwcUseCase = nwcUseCase;

  @override
  Future<void> zap() {
    // TODO: implement zap
    throw UnimplementedError();
  }

  @override
  Future<PayInvoiceResponse> payLightningInvoice(
      Wallet wallet, String invoice) async {
    if (wallet.type == WalletType.NWC) {
      final NwcWallet nwcWallet = wallet as NwcWallet;
      return _nwcUseCase.payInvoice(nwcWallet.connection!, invoice: invoice);
    } else if (wallet.type == WalletType.CASHU) {
      final CashuWallet cashuWallet = wallet as CashuWallet;

      final draftTransaction = await _cashuUseCase.initiateRedeem(
        mintUrl: cashuWallet.mintUrl,
        request: invoice,
        unit: 'sat',
        method: 'bolt11',
      );

      await for (final transaction in _cashuUseCase.redeem(
        draftRedeemTransaction: draftTransaction,
      )) {
        if (transaction.state == WalletTransactionState.completed) {
          final int feesPaid;
          if (draftTransaction.qouteMelt?.feeReserve != null) {
            feesPaid = draftTransaction.qouteMelt!.feeReserve! * 1000;
          } else {
            feesPaid = 0;
          }

          return PayInvoiceResponse(
            resultType: 'pay_invoice',
            preimage: null,
            feesPaid: feesPaid,
          );
        } else if (transaction.state == WalletTransactionState.failed) {
          throw Exception('Cashu payment failed: ${transaction.completionMsg}');
        }
      }

      throw Exception('Cashu payment did not complete');
    }
    throw UnimplementedError('Unsupported wallet type: ${wallet.type}');
  }
}
