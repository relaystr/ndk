enum TransactionType {
  incoming('incoming'),
  outgoing('outgoing');

  final String value;

  const TransactionType(this.value);

  factory TransactionType.fromValue(String value) {
    return TransactionType.values.firstWhere(
      (transactionType) => transactionType.value == value,
      orElse: () => TransactionType.incoming,
    );
  }
}
