/// invoice response
class InvoiceResponse {
  String invoice;
  int amountSats;
  String? nostrPubkey;

  /// .
  InvoiceResponse({required this.invoice, this.nostrPubkey, required this.amountSats});
}
