// ignore_for_file: camel_case_types

import 'package:equatable/equatable.dart';
import 'package:ndk_nwc/commands/nwc_response.dart';
import 'package:ndk_nwc/consts/nwc_method.dart';

/// Represents the result of a 'list_transactions' response.
class ListTransactionsResponse extends NwcResponse {
  /// A list of transaction results.
  final List<TransactionResult> transactions;

  ListTransactionsResponse({required this.transactions, required super.resultType});

  factory ListTransactionsResponse.deserialize(Map<String, dynamic> input) {
    if (!input.containsKey('result')) {
      throw Exception('Invalid input');
    }

    Map<String, dynamic> result = input['result'] as Map<String, dynamic>;
    final transactionList = result["transactions"] as List;

    List<TransactionResult> transactions = transactionList
        .map((transaction) => TransactionResult.deserialize(transaction))
        .toList();

    return ListTransactionsResponse(transactions: transactions, resultType: NwcMethod.LIST_TRANSACTIONS.name);
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

  /// The preimage of the transaction.
  final String? preimage;

  /// The payment hash of the transaction.
  final String paymentHash;

  /// The amount of the transaction (in MSATs).
  final int amount;

  /// The fees paid for the transaction (in MSATs).
  final int feesPaid;

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
    required this.paymentHash,
    required this.amount,
    required this.feesPaid,
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
      amount: input['amount'] as int,
      feesPaid: input['fees_paid'] as int,
      createdAt: input['created_at'] as int,
      expiresAt: input['expires_at'] as int?,
      settledAt: input['settled_at'] as int?,
      metadata: input['metadata'] as Map<String, dynamic>?,
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
