import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

void main() {
  group('PendingSignerRequest', () {
    test('content returns plaintext when set', () {
      final request = PendingSignerRequest(
        id: 'req-001',
        method: SignerMethod.nip44Encrypt,
        createdAt: DateTime.now(),
        signerPubkey: 'signer-pubkey',
        plaintext: 'hello',
      );
      expect(request.content, 'hello');
    });

    test('content returns ciphertext when plaintext is null', () {
      final request = PendingSignerRequest(
        id: 'req-002',
        method: SignerMethod.nip44Decrypt,
        createdAt: DateTime.now(),
        signerPubkey: 'signer-pubkey',
        ciphertext: 'encrypted',
      );
      expect(request.content, 'encrypted');
    });

    test('toString formats correctly', () {
      final request = PendingSignerRequest(
        id: 'req-003',
        method: SignerMethod.signEvent,
        createdAt: DateTime(2024, 1, 1),
        signerPubkey: 'signer-pubkey',
      );
      expect(request.toString(), contains('req-003'));
    });
  });
}
