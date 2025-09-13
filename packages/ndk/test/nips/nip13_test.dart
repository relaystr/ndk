import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/shared/nips/nip13/nip13.dart';

void main() {
  group('NIP-13 Proof of Work', () {
    test('countLeadingZeroBits should count correctly', () {
      expect(Nip13.countLeadingZeroBits('0'), equals(4));
      expect(Nip13.countLeadingZeroBits('1'), equals(3));
      expect(Nip13.countLeadingZeroBits('2'), equals(2));
      expect(Nip13.countLeadingZeroBits('3'), equals(2));
      expect(Nip13.countLeadingZeroBits('4'), equals(1));
      expect(Nip13.countLeadingZeroBits('5'), equals(1));
      expect(Nip13.countLeadingZeroBits('6'), equals(1));
      expect(Nip13.countLeadingZeroBits('7'), equals(1));
      expect(Nip13.countLeadingZeroBits('8'), equals(0));
      expect(Nip13.countLeadingZeroBits('9'), equals(0));
      expect(Nip13.countLeadingZeroBits('a'), equals(0));
      expect(Nip13.countLeadingZeroBits('b'), equals(0));
      expect(Nip13.countLeadingZeroBits('c'), equals(0));
      expect(Nip13.countLeadingZeroBits('d'), equals(0));
      expect(Nip13.countLeadingZeroBits('e'), equals(0));
      expect(Nip13.countLeadingZeroBits('f'), equals(0));
      expect(Nip13.countLeadingZeroBits('00f'), equals(8));
      expect(Nip13.countLeadingZeroBits('001'), equals(11));
    });

    test('mineEvent should meet difficulty', () {
      final keypair = Bip340.generatePrivateKey();

      final event = Nip01Event(
        pubKey: keypair.publicKey,
        kind: 1,
        tags: [],
        content: 'Hello, Nostr!',
        createdAt: 1234567890,
      ).minePoW(4);

      final minedEvent = Nip13.mineEvent(event, 4, maxIterations: 100000);

      expect(minedEvent.checkPoWDifficulty(2), isTrue);
    });
  });
}