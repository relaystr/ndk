// ignore_for_file: camel_case_types

import 'package:equatable/equatable.dart';
import '../consts/transaction_type.dart';
import '../nwc_notification.dart';
import 'nwc_response.dart';
import 'package:ndk/domain_layer/usecases/nwc/consts/nwc_method.dart';

/// Represents the result of a 'list_transactions' response.
class ListTransactionsResponse extends NwcResponse {
  /// A list of transaction results.
  final List<TransactionResult> transactions;

  ListTransactionsResponse(
      {required this.transactions, required super.resultType});

  factory ListTransactionsResponse.deserialize(Map<String, dynamic> input) {
    if (!input.containsKey('result')) {
      throw Exception('Invalid input');
    }

    Map<String, dynamic> result = input['result'] as Map<String, dynamic>;
    final transactionList = result["transactions"] as List;

    List<TransactionResult> transactions = transactionList
        .map((transaction) => TransactionResult.deserialize(transaction))
        .toList();

    return ListTransactionsResponse(
        transactions: transactions,
        resultType: NwcMethod.LIST_TRANSACTIONS.name);
  }
}

/// Represents a transaction result.
class TransactionResult extends Equatable {
  /// The type of the transaction "incoming" or "outgoing".
  final String type;

  /// The bolt11 invoice.
  final String? invoice;

  /// The description of the transaction.
  final String? description;

  /// The hash of the transaction description.
  final String? descriptionHash;

  /// The state of the payment, can be "pending", "settled", "expired" (for invoices) or "failed" (for payments), optional
  final String? state;

  /// The preimage of the transaction.
  final String? preimage;

  /// The payment hash of the transaction.
  final String paymentHash;

  /// The amount of the transaction (in MSATs).
  final int amount;

  /// The amount of the invoice (in SATS)
  int get amountSat => amount ~/ 1000;

  /// The fees paid for the transaction (in MSATs). Optional.
  final int? feesPaid;

  /// The timestamp when the transaction was created.
  final int createdAt;

  /// The timestamp when the transaction expires.
  final int? expiresAt;

  /// The timestamp when the transaction was settled (optional).
  final int? settledAt;

  /// Additional metadata (optional).
  final Map<String, dynamic>? metadata;

  const TransactionResult({
    required this.type,
    this.invoice,
    this.description,
    this.descriptionHash,
    this.preimage,
    this.state,
    required this.paymentHash,
    required this.amount,
    this.feesPaid,
    required this.createdAt,
    this.expiresAt,
    this.settledAt,
    this.metadata,
  });

  factory TransactionResult.deserialize(Map<String, dynamic> input) {
    return TransactionResult(
      type: input['type'] as String,
      invoice: input['invoice'] as String?,
      description: input['description'] as String?,
      descriptionHash: input['description_hash'] as String?,
      preimage: input['preimage'] as String?,
      paymentHash: input['payment_hash'] as String,
      state: input['state'] as String?,
      amount: input['amount'] as int,
      feesPaid: input['fees_paid'] as int?,
      createdAt: input['created_at'] as int,
      expiresAt: input['expires_at'] as int?,
      settledAt: input['settled_at'] as int?,
      metadata: input['metadata'] as Map<String, dynamic>?,
    );
  }
  bool get isIncoming => type == TransactionType.incoming.value;

  String? get zapperPubKey {
    if (metadata != null && metadata?['nostr'] != null) {
      Map<String, dynamic> nostr = metadata?['nostr'];
      // TODO refactor to nip57
      if (nostr['kind'] == 9734 && nostr['pubkey'] != null) {
        return nostr['pubkey'];
      }
    }
    return null;
  }

  /// creates a transaction result from a [NwcNotification]
  static TransactionResult fromNotification(NwcNotification notification) {
    return TransactionResult(
      type: notification.type,
      invoice: notification.invoice,
      amount: notification.amount,
      createdAt: notification.createdAt,
      description: notification.description,
      descriptionHash: notification.descriptionHash,
      preimage: notification.preimage,
      paymentHash: notification.paymentHash,
      expiresAt: notification.expiresAt,
      settledAt: notification.settledAt,
      metadata: notification.metadata,
      feesPaid: notification.feesPaid,
    );
  }

  @override
  List<Object?> get props => [
        type,
        invoice,
        description,
        descriptionHash,
        preimage,
        paymentHash,
        amount,
        feesPaid,
        createdAt,
        expiresAt,
        settledAt,
        metadata,
      ];
}
