import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

void main() {
  group('Account', () {
    late Account account;
    late Bip340EventSigner signer;
    late KeyPair keyPair;

    setUp(() {
      keyPair = Bip340.generatePrivateKey();
      signer = Bip340EventSigner(
        privateKey: keyPair.privateKey,
        publicKey: keyPair.publicKey,
      );
      account = Account(
        type: AccountType.privateKey,
        pubkey: keyPair.publicKey,
        signer: signer,
      );
    });

    tearDown(() async {
      await account.dispose();
    });

    test('pendingRequestsStream delegates to signer', () async {
      final requests = await account.pendingRequestsStream.first;
      expect(requests, isEmpty);
    });

    test('pendingRequests delegates to signer', () {
      expect(account.pendingRequests, isEmpty);
    });

    test('cancelRequest delegates to signer', () {
      final result = account.cancelRequest('some-request-id');
      expect(result, isFalse);
    });

    test('dispose delegates to signer', () async {
      await account.dispose();

      // Re-create for tearDown
      signer = Bip340EventSigner(
        privateKey: keyPair.privateKey,
        publicKey: keyPair.publicKey,
      );
      account = Account(
        type: AccountType.privateKey,
        pubkey: keyPair.publicKey,
        signer: signer,
      );
    });
  });
}
