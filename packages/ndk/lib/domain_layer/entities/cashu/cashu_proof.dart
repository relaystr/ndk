import '../../usecases/cashu/cashu_tools.dart';

class CashuProof {
  final String keysetId;
  final int amount;

  final String secret;

  /// C unblinded signature
  final String unblindedSig;

  CashuProofState state;

  CashuProof({
    required this.keysetId,
    required this.amount,
    required this.secret,
    required this.unblindedSig,
    this.state = CashuProofState.unspend,
  });

  /// Y derived public key
  String get Y => CashuTools.ecPointToHex(
        CashuTools.hashToCurve(secret),
      );

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
    CashuProofState state = CashuProofState.unspend,
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
        state: state);
  }
}

enum CashuProofState {
  unspend('UNSPENT'),
  pending('PENDING'),
  spend('SPENT');

  final String value;

  const CashuProofState(this.value);

  factory CashuProofState.fromValue(String value) {
    return CashuProofState.values.firstWhere(
      (transactionType) => transactionType.value == value,
      orElse: () => CashuProofState.unspend,
    );
  }

  @override
  String toString() => value;
}
