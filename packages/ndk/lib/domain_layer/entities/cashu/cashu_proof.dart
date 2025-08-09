import '../../usecases/cashu/cashu_tools.dart';

class CashuProof {
  final String keysetId;
  final int amount;

  final String secret;

  /// C unblinded signature
  final String unblindedSig;

  CashuProof({
    required this.keysetId,
    required this.amount,
    required this.secret,
    required this.unblindedSig,
  });

  Map<String, Object> toJson() {
    return {
      'id': keysetId,
      'amount': amount,
      'secret': secret,
      'C': unblindedSig,
    };
  }

  Map<String, Object> toV4Json() {
    return {
      'a': amount,
      's': secret,
      'c': CashuTools.hexToBytes(unblindedSig),
    };
  }

  factory CashuProof.fromV4Json({
    required Map json,
    required String keysetId,
  }) {
    final unblindedSig = json['c'] as String?;
    if (unblindedSig == null || unblindedSig.isEmpty) {
      throw Exception('Unblinded signature is missing or empty');
    }

    return CashuProof(
      keysetId: keysetId,
      amount: json['a'] ?? 0,
      secret: json['s']?.toString() ?? '',
      unblindedSig: unblindedSig,
    );
  }
}
