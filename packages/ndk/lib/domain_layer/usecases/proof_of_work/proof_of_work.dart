import '../../../shared/nips/nip13/nip13.dart';
import '../../entities/nip_01_event.dart';

class ProofOfWork {
  /// Mine this event with proof of work
  static Future<Nip01Event> minePoW({
    required Nip01Event event,
    required int targetDifficulty,
    int? maxIterations,
  }) {
    return Nip13.mineEvent(event, targetDifficulty,
        maxIterations: maxIterations);
  }

  /// Get the proof of work difficulty of this event

  static int getPoWDifficulty(Nip01Event event) {
    return Nip13.getDifficulty(event.id);
  }

  /// Check if this event meets a specific difficulty target
  static bool checkPoWDifficulty({
    required Nip01Event event,
    required int targetDifficulty,
  }) {
    return Nip13.checkDifficulty(event.id, targetDifficulty);
  }

  /// Get the target difficulty from nonce tag if present

  static int? getTargetDifficultyFromEvent(Nip01Event event) {
    return Nip13.getTargetDifficultyFromEvent(event);
  }

  /// Calculate the commitment (work done) for this event
  static int powCommitment(Nip01Event event) {
    return Nip13.calculateCommitment(event.id);
  }
}
