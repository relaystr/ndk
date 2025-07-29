import '../../usecases/cashu_wallet/cashu_token_encoder.dart';
import '../../usecases/cashu_wallet/cashu_tools.dart';
import 'wallet_cashu_proof.dart';

class WalletCashuToken {
  final List<WalletCashuProof> proofs;

  /// user msg
  final String memo;

  final String unit;

  final String mintUrl;

  WalletCashuToken({
    required this.proofs,
    required this.memo,
    required this.unit,
    required this.mintUrl,
  });

  Map toV4Json() {
    Map<String, List<Map>> allProofs = <String, List<Map>>{};

    for (final proof in proofs) {
      final keysetId = proof.keysetId;
      final proofMaps = allProofs.putIfAbsent(keysetId, () => <Map>[]);
      proofMaps.add(proof.toV4Json());
    }

    final proofMap = allProofs.entries
        .map((entry) => {
              "i": CashuTools.hexToBytes(entry.key),
              "p": entry.value,
            })
        .toList();

    return {
      'm': mintUrl,
      'u': unit,
      if (memo.isNotEmpty) 'd': memo,
      't': proofMap,
    };
  }

  String toV4TokenString() {
    return CashuTokenEncoder.encodeTokenV4(
      token: this,
    );
  }

  factory WalletCashuToken.fromV4Json(Map json) {
    final mint = json['m']?.toString() ?? '';
    final unit = json['u']?.toString() ?? '';
    final memo = json['d']?.toString() ?? '';
    final tokensJson = json['t'] ?? [];

    if (tokensJson is! List) {
      throw Exception('Invalid token format: "t" should be a list');
    }

    final myProofs = List<WalletCashuProof>.empty(growable: true);

    for (final tokenJson in tokensJson) {
      final keysetId = tokenJson['i'] as String;

      final proofsJson = tokenJson['p'] as List<dynamic>? ?? [];

      for (final proofJson in proofsJson) {
        final myProof = WalletCashuProof.fromV4Json(
          json: proofJson as Map,
          keysetId: keysetId,
        );
        myProofs.add(myProof);
      }
    }

    return WalletCashuToken(
      mintUrl: mint,
      proofs: myProofs,
      memo: memo,
      unit: unit,
    );
  }
}
