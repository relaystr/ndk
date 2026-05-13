import '../nip_01_event.dart';

class CashuTokenEvent {
  static const int kUnspendProofKind = 7375;

  final String mintUrl;
  final Set<CashuProof> proofs;
  final Set<String> deletedIds;

  late final Nip01Event? nostrEvent;

  CashuTokenEvent({
    required this.mintUrl,
    required this.proofs,
    required this.deletedIds,
  });
}

class CashuProof {
  final String id;
  final int amount;
  final String secret;

  /// C unblinded signature
  final String unblindedSig;

  CashuProof({
    required this.id,
    required this.amount,
    required this.secret,
    required this.unblindedSig,
  });

  factory CashuProof.fromJson(Map<String, dynamic> json) {
    return CashuProof(
      id: json['id'] as String,
      amount: json['amount'] as int,
      secret: json['secret'] as String,
      unblindedSig: json['C'] as String,
    );
  }
}
