import 'dart:math';
import '../../../domain_layer/entities/nip_01_event.dart';

class Nip13 {
  static int countLeadingZeroBits(String hex) {
    int count = 0;
    for (int i = 0; i < hex.length; i++) {
      int nibble = int.parse(hex[i], radix: 16);
      if (nibble == 0) {
        count += 4;
      } else {
        count += (nibble & 8) == 0 ? 1 : 0;
        count += (nibble & 12) == 0 ? 1 : 0;
        count += (nibble & 14) == 0 ? 1 : 0;
        break;
      }
    }
    return count;
  }

  static int getDifficulty(String eventId) {
    return countLeadingZeroBits(eventId);
  }

  static bool checkDifficulty(String eventId, int targetDifficulty) {
    return getDifficulty(eventId) >= targetDifficulty;
  }

  static Nip01Event mineEvent(
    Nip01Event event,
    int targetDifficulty, {
    int? maxIterations,
  }) {
    final random = Random();
    int nonce = 0;
    int iterations = 0;
    final maxIter = maxIterations ?? 1000000;

    List<List<String>> tags = List.from(event.tags);

    tags.removeWhere((tag) => tag.isNotEmpty && tag[0] == 'nonce');

    while (iterations < maxIter) {
      nonce = random.nextInt(1 << 32);

      final updatedTags = List<List<String>>.from(tags);
      updatedTags.add(['nonce', nonce.toString(), targetDifficulty.toString()]);

      final minedEvent = Nip01Event(
        pubKey: event.pubKey,
        kind: event.kind,
        tags: updatedTags,
        content: event.content,
        createdAt: event.createdAt,
      );

      if (checkDifficulty(minedEvent.id, targetDifficulty)) {
        return minedEvent;
      }

      iterations++;
    }

    throw Exception(
        'Failed to mine event with difficulty $targetDifficulty after $maxIter iterations');
  }

  static int? getTargetDifficultyFromEvent(Nip01Event event) {
    for (final tag in event.tags) {
      if (tag.length >= 3 && tag[0] == 'nonce') {
        return int.tryParse(tag[2]);
      }
    }
    return null;
  }

  static bool validateEvent(Nip01Event event) {
    final targetDifficulty = getTargetDifficultyFromEvent(event);
    if (targetDifficulty == null) {
      return true;
    }

    return checkDifficulty(event.id, targetDifficulty);
  }

  static int calculateCommitment(String eventId) {
    final difficulty = getDifficulty(eventId);
    return difficulty > 0 ? (1 << difficulty) : 0;
  }
}
