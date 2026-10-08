import 'nwc_response.dart';

/// Represents the result of a NWC-321 `pay` response.
class PayResponse extends NwcResponse {
  /// Wallet-scoped transaction identifier.
  final String transactionId;

  /// Payment state: `pending`, `settled`, or `failed`.
  final String state;

  /// Selected instruction type. Currently only `bolt11` is supported.
  final String instructionType;

  /// Paid amount in millisatoshis.
  final int amountMsat;

  /// Paid fees in millisatoshis.
  final int feesPaid;

  /// Payment hash, when available.
  final String? paymentHash;

  /// Payment preimage, when available.
  final String? preimage;

  /// Proof supplied by the selected instruction, when available.
  final String? payerProof;

  /// On-chain transaction identifier, when available.
  final String? txid;

  /// Failure details. This is expected when [state] is `failed`.
  final String? failureReason;

  /// Unix timestamp when the transaction was created.
  final int createdAt;

  /// Unix timestamp when the transaction settled, when applicable.
  final int? settledAt;

  PayResponse({
    required super.resultType,
    required this.transactionId,
    required this.state,
    required this.instructionType,
    required this.amountMsat,
    required this.feesPaid,
    required this.createdAt,
    this.paymentHash,
    this.preimage,
    this.payerProof,
    this.txid,
    this.failureReason,
    this.settledAt,
  });

  /// Paid amount rounded down to satoshis.
  int get amountSat => amountMsat ~/ 1000;

  factory PayResponse.deserialize(Map<String, dynamic> input) {
    if (!input.containsKey('result')) {
      throw Exception('Invalid input');
    }

    final result = input['result'] as Map<String, dynamic>;

    return PayResponse(
      resultType: input['result_type'] as String,
      transactionId: result['transaction_id'] as String,
      state: result['state'] as String,
      instructionType: result['instruction_type'] as String,
      amountMsat: result['amount'] as int,
      feesPaid: result['fees_paid'] as int,
      paymentHash: result['payment_hash'] as String?,
      preimage: result['preimage'] as String?,
      payerProof: result['payer_proof'] as String?,
      txid: result['txid'] as String?,
      failureReason: result['failure_reason'] as String?,
      createdAt: result['created_at'] as int,
      settledAt: result['settled_at'] as int?,
    );
  }
}
