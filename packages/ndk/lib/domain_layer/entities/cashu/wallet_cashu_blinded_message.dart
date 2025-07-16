class WalletCashuBlindedMessage {
  WalletCashuBlindedMessage({
    required this.id,
    required this.amount,
    required this.blindedMessage,
  });

  final String id;
  final int amount;

  /// B_
  final String blindedMessage;

  factory WalletCashuBlindedMessage.fromServerMap(Map json) {
    return WalletCashuBlindedMessage(
      id: json['id'],
      amount: int.tryParse(json['amount']) ?? 0,
      blindedMessage: json['B_'],
    );
  }

  Map<String, Object> toJson() {
    return {
      'id': id,
      'amount': amount,
      'B_': blindedMessage,
    };
  }

  @override
  String toString() {
    return '${super.toString()}, id: $id, amount: $amount, blindedMessage: $blindedMessage';
  }
}
