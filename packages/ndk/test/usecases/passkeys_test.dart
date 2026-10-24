import 'dart:typed_data';
import 'dart:async';
import 'package:convert/convert.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/domain_layer/usecases/passkeys/passkeys.dart';
import 'package:test/test.dart';

Uint8List bytes(String value) => Uint8List.fromList(hex.decode(value));
const author =
    '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
const storedVector =
    '4e504b01012222222222222222222222221111111111111111111111111111111111111111111111111111111111111111f2866d2730536dd59e0324da5649256a4d259463cc54540b26985e88c770edea81c8b1bca68522ae526bf85653c7f3e7';

class Provider implements PasskeyProvider {
  Uint8List? handle;
  Uint8List id = bytes('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
  final inputs = <Uint8List?>[];
  final outputs = <Uint8List>[];
  List<Uint8List> exclusions = [];
  bool? enabled;
  bool registerOutput = true;
  bool substitute = false;
  bool fail = false;
  Completer<void>? gate;
  Uint8List? customOutput;
  int registrations = 0;
  PasskeyCredential result(bool prf) {
    if (fail) throw StateError('Cancelled');
    final output = prf
        ? Uint8List.fromList(customOutput ?? List.filled(32, 7))
        : null;
    if (output != null) outputs.add(output);
    return PasskeyCredential(
      credentialId: substitute ? Uint8List.fromList([9]) : id,
      userHandle: handle,
      prfOutput: output,
      prfEnabled: enabled,
    );
  }

  @override
  Future<PasskeyCredential> register({
    required String rpId,
    required String rpName,
    required String userName,
    required Uint8List challenge,
    required Uint8List userId,
    required Uint8List prfInput,
    List<Uint8List> excludeCredentialIds = const [],
  }) async {
    if (gate != null) await gate!.future;
    registrations++;
    handle = userId;
    exclusions = excludeCredentialIds;
    inputs.add(prfInput);
    return result(registerOutput);
  }

  @override
  Future<PasskeyCredential> authenticate({
    required String rpId,
    required Uint8List challenge,
    required Uint8List? prfInput,
    Uint8List? credentialId,
  }) async {
    if (gate != null) await gate!.future;
    inputs.add(prfInput);
    return result(prfInput != null);
  }
}

class TrackingSigner extends Bip340EventSigner {
  bool disposed = false;
  TrackingSigner({required super.privateKey, required super.publicKey});
  @override
  Future<void> dispose() async {
    disposed = true;
    await super.dispose();
  }
}

class TrackingFactory extends Bip340EventSignerFactory {
  final created = <TrackingSigner>[];
  @override
  EventSigner create({String? privateKey, String? publicKey}) {
    final signer = TrackingSigner(
      privateKey: privateKey,
      publicKey: publicKey ?? derivePublicKey(privateKey!),
    );
    created.add(signer);
    return signer;
  }
}

void main() {
  late Provider provider;
  late Passkeys passkeys;
  setUp(() {
    provider = Provider();
    passkeys = Passkeys(Bip340EventSignerFactory(), provider);
  });
  group('account lifecycle', () {
    late TrackingFactory factory;
    late Accounts accounts;
    setUp(() {
      factory = TrackingFactory();
      accounts = Accounts(factory);
      provider.handle = bytes('4e504b010101${'00' * 16}');
    });
    tearDown(() => accounts.dispose());
    Future<PasskeyAccount> login([Provider? source]) => accounts
        .loginWithPasskey(provider: source ?? provider, rpId: 'example.com');
    test(
      'adding stored backup preserves logged-in account and returns metadata',
      () async {
        final privateKey = '${'0' * 63}1';
        accounts.loginPrivateKey(pubkey: author, privkey: privateKey);
        final current = accounts.getLoggedAccount();
        Uint8List? savedRecord;
        final metadata = await accounts.createStoredPasskey(
          provider: provider,
          rpId: 'example.com',
          rpName: 'Example',
          userName: 'Alice',
          privateKey: privateKey,
          hasVerifiedRecoveryCopy: true,
          existingCredentialIds: (r, a) async => [],
          saveRecord: (a, r) async {
            savedRecord = r;
          },
        );
        expect(metadata.pubkey, author);
        expect(metadata.mode, 'stored');
        expect(savedRecord, isNotNull);
        expect(accounts.getLoggedAccount(), same(current));
        expect(accounts.accounts.length, 1);
        expect(factory.created.first.disposed, isFalse);
        expect(factory.created.last.disposed, isTrue);
      },
    );
    for (final action in [
      'logout',
      'dispose',
      'ordinary login',
      'new passkey',
    ]) {
      test(
        '$action supersedes pending login and disposes its signer',
        () async {
          provider.gate = Completer<void>();
          final pending = login();
          final rejected = expectLater(pending, throwsStateError);
          if (action == 'logout') accounts.logout();
          if (action == 'dispose') await accounts.dispose();
          if (action == 'ordinary login') {
            accounts.loginPublicKey(pubkey: author);
          }
          if (action == 'new passkey') {
            final other = Provider()..handle = provider.handle;
            await login(other);
          }
          final current = accounts.getLoggedAccount();
          provider.gate!.complete();
          await rejected;
          expect(accounts.getLoggedAccount(), same(current));
          expect(factory.created.last.disposed, isTrue);
          if (action == 'dispose') await expectLater(login(), throwsStateError);
        },
      );
    }
    test(
      'duplicate signer is disposed while current account survives',
      () async {
        await login();
        final current = accounts.getLoggedAccount();
        await expectLater(login(), throwsException);
        expect(accounts.getLoggedAccount(), same(current));
        expect(factory.created.last.disposed, isTrue);
        expect(factory.created.first.disposed, isFalse);
      },
    );
    test('cancellation preserves state without creating fallback', () async {
      accounts.loginPublicKey(pubkey: author);
      final current = accounts.getLoggedAccount();
      provider.fail = true;
      await expectLater(login(), throwsStateError);
      expect(accounts.getLoggedAccount(), same(current));
      expect(provider.registrations, 0);
    });
    test('stored persistence failure cannot log in', () async {
      await expectLater(
        accounts.createStoredPasskey(
          provider: provider,
          rpId: 'example.com',
          rpName: 'Example',
          userName: 'Alice',
          privateKey: '${'0' * 63}1',
          hasVerifiedRecoveryCopy: true,
          existingCredentialIds: (r, a) async => [],
          saveRecord: (a, r) async => throw StateError('disk full'),
        ),
        throwsStateError,
      );
      expect(accounts.accounts, isEmpty);
      expect(factory.created, isEmpty);
    });
    test(
      'invalid legacy PRF length and scalar fail without account mutation',
      () async {
        provider.handle = null;
        final metadata = PasskeyAccount(
          rpId: 'example.com',
          credentialId: provider.id,
          pubkey: author,
          mode: 'legacyNosskeyDirect',
        );
        for (final invalid in [
          Uint8List(31),
          Uint8List(32),
          Uint8List.fromList(List.filled(32, 255)),
        ]) {
          provider.customOutput = invalid;
          await expectLater(
            accounts.loginWithPasskey(
              provider: provider,
              rpId: 'example.com',
              account: metadata,
            ),
            throwsStateError,
          );
          expect(accounts.accounts, isEmpty);
          expect(provider.outputs.last, everyElement(0));
        }
      },
    );
  });
  test(
    'stored metadata can reopen when targeted assertion omits handle only',
    () async {
      final metadata = PasskeyAccount(
        rpId: 'example.com',
        credentialId: provider.id,
        pubkey: author,
        mode: 'stored',
      );
      final result = await passkeys.reopen(
        rpId: 'example.com',
        account: metadata,
        resolveRecords: (a) async => [bytes(storedVector)],
      );
      expect(result.account.pubkey, author);
      provider.handle = Uint8List(16);
      await expectLater(
        passkeys.reopen(
          rpId: 'example.com',
          account: metadata,
          resolveRecords: (a) async => [bytes(storedVector)],
        ),
        throwsUnsupportedError,
      );
    },
  );
  // External vectors copied verbatim from nostr-wot-sdk:
  // packages/identity/test/vault/fixtures/passkey-key-mode-vectors.json
  for (final vector in [
    (
      1,
      '6cae07a92d7fcc20f7eed6ed78f6ab8848a7c921dd31679f6019551c0cc9fbbc',
      'bf6b11c40255021de2a25e38fe24b6ccb1e3b07a96175b25538b5453605c36d9',
      '1e36ce5101376f65a8ad05538100265305046cca1541cffb78ee31cfecbdff1f',
    ),
    (
      2,
      '8ee22949c1045c627e14236f1d06cf730b46b4cf309cbf4ede25a446cf33ad8d',
      'a1e1ac8dd866cabdf743a4cdedbf53c680444094a25c0ffc4e558ec5a78831c1',
      '5146ad1f0bec6b37a9f1937c5c80d452a2d952ac1a8f4bee690dd34dbd4ef3c8',
    ),
  ]) {
    test(
      'SDK derived parameter ${vector.$1} matches input, secret and author',
      () async {
        expect(
          hex.encode(await Passkeys.prfInput('derived', vector.$1)),
          vector.$2,
        );
        expect(
          hex.encode(
            await Passkeys.deriveKey(
              Uint8List.fromList(List.filled(32, 7)),
              vector.$1,
            ),
          ),
          vector.$3,
        );
        final result = await passkeys.create(
          rpId: 'example.com',
          rpName: 'Example',
          userName: 'Alice',
          parameterSet: vector.$1,
        );
        expect(result.account.pubkey, vector.$4);
        expect(provider.handle!.length, 22);
        expect(provider.outputs.single, everyElement(0));
        final restored = await passkeys.reopen(rpId: 'example.com');
        expect(restored.account.pubkey, vector.$4);
        expect(provider.inputs[1], isNull);
        expect(hex.encode(provider.inputs[2]!), vector.$2);
      },
    );
  }
  test('SDK stored record opens with exact AAD binding', () async {
    provider.handle = bytes('4e504b0102$author');
    expect(
      hex.encode(await Passkeys.prfInput('stored')),
      '8b309d7051d41bda75ece773d6d35c49fb2ed7901f1e0261a476ac2646036e8e',
    );
    final result = await passkeys.reopen(
      rpId: 'example.com',
      resolveRecords: (a) async => [bytes(storedVector)],
    );
    expect(result.account.pubkey, author);
    await expectLater(
      passkeys.reopen(
        rpId: 'different.com',
        resolveRecords: (a) async => [bytes(storedVector)],
      ),
      throwsStateError,
    );
    provider.id = Uint8List.fromList([1]);
    await expectLater(
      passkeys.reopen(
        rpId: 'example.com',
        resolveRecords: (a) async => [bytes(storedVector)],
      ),
      throwsStateError,
    );
  });
  test(
    'stored creation queries inventory and persists before returning',
    () async {
      Uint8List? record;
      final result = await passkeys.createStored(
        rpId: 'example.com',
        rpName: 'Example',
        userName: 'Alice',
        privateKey: '${'0' * 63}1',
        hasVerifiedRecoveryCopy: true,
        existingCredentialIds: (rp, pub) async {
          expect(provider.registrations, 0);
          expect(pub, author);
          return [
            Uint8List.fromList([5]),
          ];
        },
        saveRecord: (a, r) async {
          record = r;
        },
      );
      expect(provider.exclusions.single, [5]);
      expect(record!.length, 97);
      expect(result.account.pubkey, author);
      final restored = await passkeys.reopen(
        rpId: 'example.com',
        resolveRecords: (a) async => [record!],
      );
      expect(restored.account.pubkey, author);
    },
  );
  test('persistence failure fails creation', () async {
    await expectLater(
      passkeys.createStored(
        rpId: 'example.com',
        rpName: 'Example',
        userName: 'Alice',
        privateKey: '${'0' * 63}1',
        hasVerifiedRecoveryCopy: true,
        existingCredentialIds: (r, a) async => [],
        saveRecord: (a, r) async => throw StateError('write failed'),
      ),
      throwsStateError,
    );
    expect(provider.outputs.single, everyElement(0));
  });
  test(
    'unknown, unsupported, legacy stored and reserved parameters never derive',
    () async {
      for (final handle in <Uint8List?>[
        null,
        Uint8List(16),
        Uint8List(32),
        bytes('4e504b0201'),
        bytes('4e504b010105${'00' * 16}'),
      ]) {
        provider.handle = handle;
        provider.inputs.clear();
        await expectLater(
          passkeys.reopen(rpId: 'example.com'),
          throwsUnsupportedError,
        );
        expect(provider.inputs, [null]);
      }
      expect(
        Passkeys.classify(bytes('4e504b${'11' * 29}')).mode,
        'legacyStored',
      );
    },
  );
  test(
    'explicit LaWallet metadata permits untagged credential and checks author',
    () async {
      final account = PasskeyAccount(
        rpId: 'example.com',
        credentialId: provider.id,
        pubkey:
            '5146ad1f0bec6b37a9f1937c5c80d452a2d952ac1a8f4bee690dd34dbd4ef3c8',
        mode: 'derived',
        parameterSet: 2,
      );
      final result = await passkeys.reopen(
        rpId: 'example.com',
        account: account,
      );
      expect(result.account.pubkey, account.pubkey);
      final wrong = PasskeyAccount(
        rpId: 'example.com',
        credentialId: provider.id,
        pubkey: author,
        mode: 'derived',
        parameterSet: 2,
      );
      await expectLater(
        passkeys.reopen(rpId: 'example.com', account: wrong),
        throwsStateError,
      );
    },
  );
  test('stored recovery guard runs before inventory or registration', () async {
    await expectLater(
      passkeys.createStored(
        rpId: 'example.com',
        rpName: 'Example',
        userName: 'Alice',
        privateKey: '${'0' * 63}1',
        hasVerifiedRecoveryCopy: false,
        existingCredentialIds: (r, a) async => throw StateError('must not run'),
        saveRecord: (a, r) async {},
      ),
      throwsStateError,
    );
    expect(provider.registrations, 0);
  });
  test(
    'failed stored candidates are reported without blocking a valid copy',
    () async {
      provider.handle = bytes('4e504b0102$author');
      final reports = <int>[];
      final corrupt = bytes(storedVector)..[90] ^= 1;
      await passkeys.reopen(
        rpId: 'example.com',
        resolveRecords: (a) async => [corrupt, bytes(storedVector)],
        onRecordFailure: (index, reason) => reports.add(index),
      );
      expect(reports, [0]);
    },
  );
  test(
    'explicit legacy direct uses original PRF input and public key check',
    () async {
      final original = Uint8List.fromList(List.filled(32, 7));
      final pubkey = Bip340EventSignerFactory().derivePublicKey(
        hex.encode(original),
      );
      final account = PasskeyAccount(
        rpId: 'example.com',
        credentialId: provider.id,
        pubkey: pubkey,
        mode: 'legacyNosskeyDirect',
      );
      final result = await passkeys.reopen(
        rpId: 'example.com',
        account: account,
      );
      expect(result.account.pubkey, pubkey);
      expect(hex.encode(provider.inputs.last!), '6e6f7374722d70776b');
      provider.enabled = false;
      await expectLater(
        passkeys.reopen(rpId: 'example.com', account: account),
        throwsUnsupportedError,
      );
    },
  );
  test('saved metadata rejects malformed fields with FormatException', () {
    final valid = PasskeyAccount(
      rpId: 'example.com',
      credentialId: Uint8List.fromList([170]),
      pubkey: author,
      mode: 'derived',
      parameterSet: 1,
    ).toJson();
    expect(PasskeyAccount.fromJson(valid).toJson(), valid);
    for (final field in [
      'rpId',
      'credentialId',
      'pubkey',
      'mode',
      'parameterSet',
    ]) {
      for (final value in [null, true, <String>[]]) {
        expect(
          () => PasskeyAccount.fromJson({...valid, field: value}),
          throwsFormatException,
          reason: '$field: $value',
        );
      }
      expect(
        () => PasskeyAccount.fromJson({...valid}..remove(field)),
        throwsFormatException,
        reason: 'missing $field',
      );
    }
    for (final invalid in <Map<String, dynamic>>[
      {'rpId': 'https://example.com'},
      {'pubkey': 'invalid'},
      {'mode': 'unknown'},
      {'parameterSet': 3},
      {'mode': 'stored'},
      {'credentialId': ''},
      {'credentialId': '!'},
      {'credentialId': 'A' * 1368},
      {'credentialId': 'A' * 1369},
    ]) {
      expect(
        () => PasskeyAccount.fromJson({...valid, ...invalid}),
        throwsFormatException,
      );
    }
    for (final mode in ['stored', 'legacyNosskeyDirect']) {
      final json = {...valid, 'mode': mode}..remove('parameterSet');
      expect(PasskeyAccount.fromJson(json).toJson(), json);
    }
  });
  test('metadata has no implicit legacy default', () {
    expect(
      () => PasskeyAccount.fromJson({
        'rpId': 'example.com',
        'credentialId': 'qg==',
        'pubkey': author,
      }),
      throwsFormatException,
    );
  });
  test('PRF disabled fails even with output and clears output', () async {
    provider.enabled = false;
    await expectLater(
      passkeys.create(
        rpId: 'example.com',
        rpName: 'Example',
        userName: 'Alice',
      ),
      throwsUnsupportedError,
    );
    expect(provider.outputs.single, everyElement(0));
  });
  test(
    'registration without output makes exactly one targeted evaluation',
    () async {
      provider.registerOutput = false;
      final result = await passkeys.create(
        rpId: 'example.com',
        rpName: 'Example',
        userName: 'Alice',
      );
      expect(result.account.mode, 'derived');
      expect(provider.inputs.length, 2);
    },
  );
  test(
    'corrupt, reserved, vault records fail closed without derivation',
    () async {
      provider.handle = bytes('4e504b0102$author');
      for (final type in [2, 3, 4]) {
        final record = bytes(storedVector)..[4] = type;
        await expectLater(
          passkeys.reopen(
            rpId: 'example.com',
            resolveRecords: (a) async => [record],
          ),
          throwsStateError,
        );
      }
      final corrupt = bytes(storedVector)..[90] ^= 1;
      final valid = await passkeys.reopen(
        rpId: 'example.com',
        resolveRecords: (a) async => [corrupt, bytes(storedVector)],
      );
      expect(valid.account.pubkey, author);
    },
  );
}
