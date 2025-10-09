class CashuBlindedSignature {
  CashuBlindedSignature({
    required this.id,
    required this.amount,
    required this.blindedSignature,
  });

  final String id;
  final int amount;

  /// C_ blinded signature
  final String blindedSignature;

  factory CashuBlindedSignature.fromServerMap(Map json) {
    return CashuBlindedSignature(
      id: json['id'],
      amount: json['amount'] is int
          ? json['amount']
          : int.tryParse(json['amount']) ?? 0,
      blindedSignature: json['C_'] ?? '',
    );
  }

  @override
  String toString() {
    return '${super.toString()}, id: $id, amount: $amount, blindedSignature: $blindedSignature';
  }
}
