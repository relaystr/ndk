import '../entities/wallet/wallet.dart';
import '../usecases/nwc/responses/pay_invoice_response.dart';

/// Repository to glue the specific wallet implementations to common operations \
/// available on all wallets.
abstract class WalletsOperationsRepo {
  /// todo:
  /// just to get an idea what this repo should do
  Future<void> zap();

  Future<PayInvoiceResponse> payLightningInvoice(Wallet wallet, String invoice);
}
