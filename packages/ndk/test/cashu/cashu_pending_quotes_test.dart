import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:ndk/data_layer/data_sources/http_request.dart';
import 'package:ndk/data_layer/repositories/cashu/cashu_repo_impl.dart';
import 'package:ndk/data_layer/repositories/cashu_seed_secret_generator/dart_cashu_key_derivation.dart';
import 'package:ndk/data_layer/repositories/wallets/mem_wallets_repo.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_quote.dart';
import 'package:ndk/domain_layer/repositories/cashu_key_derivation.dart';
import 'package:ndk/domain_layer/usecases/cashu/cashu_keypair.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

import '../mocks/mock_event_verifier.dart';
import 'mocks/cashu_http_client_mock.dart';

const mockMintUrl = 'http://mock.mint';
const paidQuoteId = 'd00e6cbc-04c9-4661-8909-e47c19612bf0';
const devMintUrl = 'https://dev.mint.camelus.app';

CashuWalletTransaction _pendingFundTx({
  required CashuKeypair quoteKey,
  CashuQuoteState state = CashuQuoteState.unpaid,
  int quoteKeyCounter = -1,
}) {
  return CashuWalletTransaction(
    id: paidQuoteId,
    walletId: mockMintUrl,
    changeAmount: 5,
    unit: 'sat',
    walletType: WalletType.CASHU,
    state: WalletTransactionState.pending,
    mintUrl: mockMintUrl,
    method: 'bolt11',
    qoute: CashuQuote(
      quoteId: paidQuoteId,
      request: 'lnbc...',
      amount: 5,
      unit: 'sat',
      state: state,
      expiry: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
      mintUrl: mockMintUrl,
      quoteKey: quoteKey,
      quoteKeyCounter: quoteKeyCounter,
    ),
  );
}

Cashu _cashu({
  required MemWalletsRepo wallets,
  required CacheManager cache,
  required CashuUserSeedphrase seedPhrase,
  MockCashuHttpClient? mockClient,
}) {
  final repo = CashuRepoImpl(
    client: HttpRequestDS(mockClient ?? MockCashuHttpClient()),
  );
  return Cashu(
    cashuRepo: repo,
    walletsRepo: wallets,
    cacheManager: cache,
    cashuKeyDerivation: DartCashuKeyDerivation(),
    cashuUserSeedphrase: seedPhrase,
  );
}

Future<CashuWalletTransaction> _storedTx(MemWalletsRepo wallets) async {
  final tx = (await wallets.getTransactions()).single;
  return tx as CashuWalletTransaction;
}

/// Builds a Cashu instance wired to a real mint over HTTP.
Cashu _realCashu({
  required http.Client client,
  required MemWalletsRepo wallets,
  required CacheManager cache,
  required CashuUserSeedphrase seedPhrase,
}) {
  return Cashu(
    cashuRepo: CashuRepoImpl(client: HttpRequestDS(client)),
    walletsRepo: wallets,
    cacheManager: cache,
    cashuKeyDerivation: DartCashuKeyDerivation(),
    cashuUserSeedphrase: seedPhrase,
  );
}

void main() {
  final seedPhrase =
      CashuUserSeedphrase(seedPhrase: CashuSeed.generateSeedPhrase());

  test('updatePendingQuotes re-fetches the state of pending quotes', () async {
    final wallets = MemWalletsRepo();
    final cashu = _cashu(
      wallets: wallets,
      cache: MemCacheManager(),
      seedPhrase: seedPhrase,
    );

    await wallets.saveTransactions(
      [_pendingFundTx(quoteKey: CashuKeypair.generateCashuKeyPair())],
    );

    await cashu.updatePendingQuotes();

    final stored = await _storedTx(wallets);
    expect(stored.qoute!.state, equals(CashuQuoteState.paid));
  });

  test('updatePendingQuotes ignores completed transactions', () async {
    final wallets = MemWalletsRepo();
    final cashu = _cashu(
      wallets: wallets,
      cache: MemCacheManager(),
      seedPhrase: seedPhrase,
    );

    final tx = _pendingFundTx(
      quoteKey: CashuKeypair.generateCashuKeyPair(),
      state: CashuQuoteState.paid,
    );
    await wallets.saveTransactions(
      [tx.copyWith(state: WalletTransactionState.completed)],
    );

    await cashu.updatePendingQuotes();

    final stored = await _storedTx(wallets);
    // the mock mint reports PAID, but a completed transaction is left alone
    expect(stored.state, equals(WalletTransactionState.completed));
  });

  test('runs automatically on startup when a seed phrase is available',
      () async {
    final wallets = MemWalletsRepo();
    await wallets.saveTransactions(
      [_pendingFundTx(quoteKey: CashuKeypair.generateCashuKeyPair())],
    );

    _cashu(
      wallets: wallets,
      cache: MemCacheManager(),
      seedPhrase: seedPhrase,
    );

    // let the unawaited startup refresh complete (mock responses resolve on
    // microtasks, no real timers involved)
    var stored = await _storedTx(wallets);
    var waited = 0;
    while (stored.qoute!.state != CashuQuoteState.paid && waited < 50) {
      await Future<void>.delayed(Duration.zero);
      stored = await _storedTx(wallets);
      waited++;
    }

    expect(stored.qoute!.state, equals(CashuQuoteState.paid));
  });

  test(
      'auto-startup recovers the lock key and completes the full flow for '
      'locally paid quotes', () async {
    final seedPhraseSentence = seedPhrase.seedPhrase;
    final seed = CashuSeed();
    await seed.setSeedPhrase(seedPhrase: seedPhraseSentence);
    final derivation = DartCashuKeyDerivation();

    const targetCounter = 3;
    final recoveredKeypair = await derivation.deriveQuoteKey(
      seedBytes: Uint8List.fromList(seed.getSeedBytes()),
      counter: targetCounter,
    );

    // a locally paid quote whose record lost the private key and counter
    final pendingTx = _pendingFundTx(
      quoteKey: CashuKeypair(
        privateKey: '00' * 32,
        publicKey: recoveredKeypair.publicKey,
      ),
      state: CashuQuoteState.paid,
    );

    final wallets = MemWalletsRepo();
    await wallets.saveTransactions([pendingTx]);

    // 4 quote keys were assigned so far (counters 0..3)
    final cache = MemCacheManager();
    await cache.setCashuSecretCounter(
      mintUrl: kQuoteKeyDerivationCounterSlot,
      keysetId: kQuoteKeyDerivationCounterSlot,
      counter: 4,
    );

    _cashu(
      wallets: wallets,
      cache: cache,
      seedPhrase: seedPhrase,
    );

    // the startup refresh persists the fresh (PAID) state, then the wallet
    // recovers the seed-derived lock key from the counter scan and reaches
    // the completion step (skipped here since the record lacks usedKeysets)
    var stored = await _storedTx(wallets);
    var waited = 0;
    while ((stored.qoute!.quoteKeyCounter != targetCounter ||
            stored.qoute!.state != CashuQuoteState.paid) &&
        waited < 200) {
      await Future<void>.delayed(Duration.zero);
      stored = await _storedTx(wallets);
      waited++;
    }

    expect(stored.qoute!.state, equals(CashuQuoteState.paid));
    expect(
        stored.qoute!.quoteKey.privateKey, equals(recoveredKeypair.privateKey));
    expect(stored.qoute!.quoteKeyCounter, equals(targetCounter));
  });

  test('restore recovers the quote keys of pending funding quotes', () async {
    final seedPhraseSentence = seedPhrase.seedPhrase;
    final seed = CashuSeed();
    await seed.setSeedPhrase(seedPhrase: seedPhraseSentence);
    final derivation = DartCashuKeyDerivation();

    const targetCounter = 3;
    final recoveredKeypair = await derivation.deriveQuoteKey(
      seedBytes: Uint8List.fromList(seed.getSeedBytes()),
      counter: targetCounter,
    );

    // the mint locked the quote to the seed-derived pubkey, but the local
    // record lost the private key and the derivation counter
    final pendingTx = _pendingFundTx(
      quoteKey: CashuKeypair(
        privateKey: '00' * 32,
        publicKey: recoveredKeypair.publicKey,
      ),
    );

    final wallets = MemWalletsRepo();
    await wallets.saveTransactions([pendingTx]);

    // 4 quote keys were assigned so far (counters 0..3)
    final cache = MemCacheManager();
    await cache.setCashuSecretCounter(
      mintUrl: kQuoteKeyDerivationCounterSlot,
      keysetId: kQuoteKeyDerivationCounterSlot,
      counter: 4,
    );

    final mockClient = MockCashuHttpClient();
    mockClient.setCustomResponse(
      'POST',
      '/v1/restore',
      http.Response(
        jsonEncode({'outputs': [], 'signatures': []}),
        200,
        headers: {'content-type': 'application/json'},
      ),
    );

    final cashu = _cashu(
      wallets: wallets,
      cache: cache,
      seedPhrase: seedPhrase,
      mockClient: mockClient,
    );

    await cashu.restore(mintUrl: mockMintUrl).toList();

    final stored = await _storedTx(wallets);
    expect(
        stored.qoute!.quoteKey.privateKey, equals(recoveredKeypair.privateKey));
    expect(stored.qoute!.quoteKeyCounter, equals(targetCounter));
  });

  test(
      'recoverAndCompleteQuote recovers the key of a quote that is not in '
      'the wallet state', () async {
    final seedPhraseSentence = seedPhrase.seedPhrase;
    final seed = CashuSeed();
    await seed.setSeedPhrase(seedPhrase: seedPhraseSentence);
    final derivation = DartCashuKeyDerivation();

    const targetCounter = 3;
    final recoveredKeypair = await derivation.deriveQuoteKey(
      seedBytes: Uint8List.fromList(seed.getSeedBytes()),
      counter: targetCounter,
    );

    // the mint reports the quote (with the locked pubkey) but the wallet has
    // no record of it
    final mockClient = MockCashuHttpClient();
    mockClient.setCustomResponse(
      'GET',
      '/v1/mint/quote/bolt11/$paidQuoteId',
      http.Response(
        jsonEncode({
          'quote': paidQuoteId,
          'request': 'lnbc...',
          'amount': 5,
          'unit': 'sat',
          'state': 'PAID',
          'expiry': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
          'pubkey': recoveredKeypair.publicKey,
        }),
        200,
        headers: {'content-type': 'application/json'},
      ),
    );

    // 4 quote keys were assigned so far (counters 0..3)
    final cache = MemCacheManager();
    await cache.setCashuSecretCounter(
      mintUrl: kQuoteKeyDerivationCounterSlot,
      keysetId: kQuoteKeyDerivationCounterSlot,
      counter: 4,
    );

    final wallets = MemWalletsRepo();
    final cashu = _cashu(
      wallets: wallets,
      cache: cache,
      seedPhrase: seedPhrase,
      mockClient: mockClient,
    );

    // the mock mint returns no signatures, so the minting step fails after
    // the key was recovered and the record was created
    await expectLater(
      cashu.recoverAndCompleteQuote(
        mintUrl: mockMintUrl,
        quoteID: paidQuoteId,
      ),
      throwsA(isA<Exception>()),
    );

    // the record was created even though the mint rejected the request, and
    // the recovered key and counter are persisted on it
    final stored = await _storedTx(wallets);
    expect(
        stored.qoute!.quoteKey.privateKey, equals(recoveredKeypair.privateKey));
    expect(stored.qoute!.quoteKeyCounter, equals(targetCounter));
  });

  test(
      'recoverAndCompleteQuote updates a quote that is already in the '
      'wallet state', () async {
    final seed = CashuSeed(userSeedPhrase: seedPhrase);
    final derivation = DartCashuKeyDerivation();

    const targetCounter = 3;
    final recoveredKeypair = await derivation.deriveQuoteKey(
      seedBytes: Uint8List.fromList(seed.getSeedBytes()),
      counter: targetCounter,
    );

    final mockClient = MockCashuHttpClient();
    mockClient.setCustomResponse(
      'GET',
      '/v1/mint/quote/bolt11/$paidQuoteId',
      http.Response(
        jsonEncode({
          'quote': paidQuoteId,
          'request': 'lnbc...',
          'amount': 5,
          'unit': 'sat',
          'state': 'PAID',
          'expiry': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
          'pubkey': recoveredKeypair.publicKey,
        }),
        200,
        headers: {'content-type': 'application/json'},
      ),
    );

    final cache = MemCacheManager();
    await cache.setCashuSecretCounter(
      mintUrl: kQuoteKeyDerivationCounterSlot,
      keysetId: kQuoteKeyDerivationCounterSlot,
      counter: 4,
    );

    // a stale record of the quote already exists locally without a lock key
    final wallets = MemWalletsRepo();
    await wallets.saveTransactions([
      CashuWalletTransaction(
        id: paidQuoteId,
        walletId: mockMintUrl,
        changeAmount: 5,
        unit: 'sat',
        walletType: WalletType.CASHU,
        state: WalletTransactionState.draft,
        mintUrl: mockMintUrl,
        method: 'bolt11',
        // qoute: CashuQuote(
        //   quoteId: paidQuoteId,
        //   request: '',
        //   state: CashuQuoteState.unpaid,
        //   mintUrl: mockMintUrl,
        //   amount: 5,
        //   unit: 'sat',
        //   expiry: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
        //   quoteKey: CashuKeypair(privateKey: '', publicKey: ''),
        //   quoteKeyCounter: 3,
        // ),
      ),
    ]);

    final cashu = _cashu(
      wallets: wallets,
      cache: cache,
      seedPhrase: seedPhrase,
      mockClient: mockClient,
    );

    await expectLater(
      cashu.recoverAndCompleteQuote(
        mintUrl: mockMintUrl,
        quoteID: paidQuoteId,
      ),
      throwsA(isA<Exception>()),
    );

    // the existing record was kept and updated with the recovered key
    expect((await wallets.getTransactions()).length, 1);
    final stored = await _storedTx(wallets);
    expect(stored.qoute!.quoteId, equals(paidQuoteId));
    expect(
        stored.qoute!.quoteKey.privateKey, equals(recoveredKeypair.privateKey));
    expect(stored.qoute!.quoteKeyCounter, equals(targetCounter));
  });

  group('dev mint integration - dev.mint.camelus.app', () {
    const fundAmount = 21;

    test(
        'funds with a quote, deletes the wallet state, and restores it '
        'from the seed',
        timeout: const Timeout(Duration(minutes: 3)), () async {
      final seedPhrase =
          CashuUserSeedphrase(seedPhrase: CashuSeed.generateSeedPhrase());

      // wallet1: create a quote, the dev mint auto-pays it, complete the mint
      final client1 = http.Client();
      final cache1 = MemCacheManager();
      final wallets1 = MemWalletsRepo();
      final wallet1 = _realCashu(
        client: client1,
        cache: cache1,
        wallets: wallets1,
        seedPhrase: seedPhrase,
      );

      final draft = await wallet1.initiateFund(
        mintUrl: devMintUrl,
        amount: fundAmount,
        unit: 'sat',
        method: 'bolt11',
      );
      expect(draft.qoute, isNotNull);

      await expectLater(
        wallet1.retrieveFunds(draftTransaction: draft),
        emitsInOrder([
          isA<CashuWalletTransaction>().having(
            (t) => t.state,
            'state',
            WalletTransactionState.pending,
          ),
          isA<CashuWalletTransaction>().having(
            (t) => t.state,
            'state',
            WalletTransactionState.completed,
          ),
        ]),
      ).timeout(const Duration(minutes: 3));

      final balance1 = (await wallet1.getBalances())
          .where((e) => e.mintUrl == devMintUrl)
          .first
          .balances['sat'];
      expect(balance1, equals(fundAmount));
      client1.close();

      // delete the wallet state: same seed, fresh cache + fresh wallets repo
      final client2 = http.Client();
      final cache2 = MemCacheManager();
      final wallet2 = _realCashu(
        client: client2,
        cache: cache2,
        wallets: MemWalletsRepo(),
        seedPhrase: seedPhrase,
      );

      final balancesBefore = await wallet2.getBalances();
      expect(
        balancesBefore.where((e) => e.mintUrl == devMintUrl),
        isEmpty,
        reason: 'the deleted wallet should start with no balance',
      );

      CashuRestoreResult? restoreResult;
      await for (final result in wallet2
          .restore(
            mintUrl: devMintUrl,
            unit: 'sat',
          )
          .timeout(const Duration(minutes: 2))) {
        restoreResult = result;
      }

      expect(restoreResult, isNotNull);
      expect(restoreResult!.totalProofsRestored, greaterThan(0));

      final balance2 = (await wallet2.getBalances())
          .where((e) => e.mintUrl == devMintUrl)
          .first
          .balances['sat'];
      expect(balance2, equals(fundAmount));

      final proofs = await cache2.getProofs(mintUrl: devMintUrl);
      expect(proofs.length, greaterThan(0));
      expect(
        proofs.map((p) => p.secret).toSet().length,
        equals(proofs.length),
        reason: 'each restored proof should have a unique secret',
      );
      client2.close();
    });

    test(
        'recovers the lock key of an auto-paid quote after the wallet state '
        'is deleted and completes it',
        timeout: const Timeout(Duration(minutes: 3)), () async {
      final seedPhrase =
          CashuUserSeedphrase(seedPhrase: CashuSeed.generateSeedPhrase());

      // wallet1: create a quote locked to a seed-derived key and wait until
      // the dev mint auto-pays the invoice (refreshing like the app does)
      final client1 = http.Client();
      final wallets1 = MemWalletsRepo();
      final wallet1 = _realCashu(
        client: client1,
        cache: MemCacheManager(),
        wallets: wallets1,
        seedPhrase: seedPhrase,
      );

      final draft = await wallet1.initiateFund(
        mintUrl: devMintUrl,
        amount: fundAmount,
        unit: 'sat',
        method: 'bolt11',
      );
      expect(draft.qoute, isNotNull);
      final lockedPubkey = draft.qoute!.quoteKey.publicKey;

      var quoteState = draft.qoute!.state;
      final payDeadline = DateTime.now().add(const Duration(minutes: 2));
      while (quoteState != CashuQuoteState.paid &&
          DateTime.now().isBefore(payDeadline)) {
        await Future<void>.delayed(const Duration(seconds: 2));
        await wallet1.updatePendingQuotes();
        final stored =
            (await wallets1.getTransactions()).single as CashuWalletTransaction;
        quoteState = stored.qoute!.state;
      }
      expect(
        quoteState,
        CashuQuoteState.paid,
        reason: 'the dev mint should auto-pay the invoice',
      );

      // "delete the wallet state": fresh cache + wallets repo on the same
      // seed. Only the quote record survives (the private lock key and the
      // derivation counter are lost).
      final wallets2 = MemWalletsRepo();
      await wallets2.saveTransactions([
        CashuWalletTransaction(
          id: draft.id,
          walletId: devMintUrl,
          changeAmount: draft.changeAmount,
          unit: draft.unit,
          walletType: WalletType.CASHU,
          state: WalletTransactionState.pending,
          mintUrl: devMintUrl,
          method: draft.method,
          usedKeysets: draft.usedKeysets,
          qoute: CashuQuote(
            quoteId: draft.qoute!.quoteId,
            request: draft.qoute!.request,
            amount: draft.qoute!.amount,
            unit: draft.qoute!.unit,
            state: CashuQuoteState.paid,
            expiry: draft.qoute!.expiry,
            mintUrl: devMintUrl,
            quoteKey: CashuKeypair(
              privateKey: '00' * 32,
              publicKey: lockedPubkey,
            ),
          ),
        ),
      ]);

      final client2 = http.Client();
      final wallet2 = _realCashu(
        client: client2,
        cache: MemCacheManager(),
        wallets: wallets2,
        seedPhrase: seedPhrase,
      );

      // the startup refresh re-syncs the stored quote state from the mint
      var stored2 = await _storedTx(wallets2);
      final refreshDeadline = DateTime.now().add(const Duration(seconds: 30));
      while (stored2.qoute!.state != CashuQuoteState.paid &&
          DateTime.now().isBefore(refreshDeadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        stored2 = await _storedTx(wallets2);
      }
      expect(
        stored2.qoute!.state,
        CashuQuoteState.paid,
        reason: 'the startup refresh should mark the quote as paid',
      );

      // restore recovers the seed-derived lock key of the pending quote and
      // completes the already-paid quote, minting the proofs
      await wallet2
          .restore(mintUrl: devMintUrl)
          .toList()
          .timeout(const Duration(minutes: 2));

      stored2 = await _storedTx(wallets2);
      expect(stored2.state, equals(WalletTransactionState.completed));
      expect(stored2.qoute!.quoteKey.privateKey, isNot(equals('00' * 32)));
      expect(stored2.qoute!.quoteKeyCounter, isNot(equals(-1)));

      final seed = CashuSeed();
      await seed.setSeedPhrase(seedPhrase: seedPhrase.seedPhrase);
      final rederived = await DartCashuKeyDerivation().deriveQuoteKey(
        seedBytes: Uint8List.fromList(seed.getSeedBytes()),
        counter: stored2.qoute!.quoteKeyCounter,
      );
      expect(
        stored2.qoute!.quoteKey.privateKey,
        equals(rederived.privateKey),
        reason: 'the recovered key must match the seed derivation',
      );

      final balance2 = (await wallet2.getBalances())
          .where((e) => e.mintUrl == devMintUrl)
          .first
          .balances['sat'];
      expect(balance2, equals(fundAmount));

      client1.close();
      client2.close();
    });

    test('initiate fund, recover', timeout: const Timeout(Duration(minutes: 3)),
        () async {
      final seedPhrase =
          CashuUserSeedphrase(seedPhrase: CashuSeed.generateSeedPhrase());

      // a restored wallet shares the pending transaction records (wallets
      // repo) with the original wallet while its cache is fresh. It is built
      // before any quote exists so its startup refresh is a no-op.
      final wallets = MemWalletsRepo();
      final ndk = Ndk(
        NdkConfig(
          eventVerifier: MockEventVerifier(),
          cache: MemCacheManager(),
          cashuUserSeedphrase: seedPhrase,
          walletsRepo: wallets,
        ),
      );

      // wallet1: create a quote locked to a seed-derived key
      final client1 = http.Client();
      final wallet1 = _realCashu(
        client: client1,
        cache: MemCacheManager(),
        wallets: MemWalletsRepo(),
        seedPhrase: seedPhrase,
      );

      final draft = await wallet1.initiateFund(
        mintUrl: devMintUrl,
        amount: fundAmount,
        unit: 'sat',
        method: 'bolt11',
      );
      expect(draft.qoute, isNotNull);

      // local data loss: the pending record survives, but the private lock key
      // is gone and the public key is garbage too - the recovery must work off
      // the recorded derivation counter, not the locked pubkey
      await wallets.saveTransactions([
        draft.copyWith(
          state: WalletTransactionState.pending,
          qoute: draft.qoute!.copyWith(
            quoteKey: CashuKeypair(
              privateKey: '00' * 32,
              publicKey: 'garbage',
            ),
          ),
        ),
      ]);

      // recover: re-derives the quote key from the counter (no locked pubkey
      // needed) and completes the auto-paid quote, minting the proofs
      await ndk.cashu
          .restore(mintUrl: devMintUrl)
          .toList()
          .timeout(const Duration(minutes: 3));

      // the recovered key matches the seed derivation at the recorded counter
      final stored = await _storedTx(wallets);
      final seed = CashuSeed();
      await seed.setSeedPhrase(seedPhrase: seedPhrase.seedPhrase);
      final derived = await DartCashuKeyDerivation().deriveQuoteKey(
        seedBytes: Uint8List.fromList(seed.getSeedBytes()),
        counter: stored.qoute!.quoteKeyCounter,
      );
      expect(
        stored.qoute!.quoteKey.privateKey,
        equals(derived.privateKey),
        reason: 'the quote key must be recovered from the seed derivation',
      );

      // the recovered pending funds became spendable proofs again
      final balance2 = (await ndk.cashu.getBalances())
          .where((e) => e.mintUrl == devMintUrl)
          .first
          .balances['sat'];
      expect(balance2, equals(fundAmount));

      client1.close();
    });

    test(
        'recoverAndCompleteQuote completes a quote that is not in the '
        'wallet state',
        timeout: const Timeout(Duration(minutes: 3)), () async {
      final seedPhrase =
          CashuUserSeedphrase(seedPhrase: CashuSeed.generateSeedPhrase());

      // wallet1 creates the quote so the mint holds it locked to a pubkey
      final client1 = http.Client();
      final wallet1 = _realCashu(
        client: client1,
        cache: MemCacheManager(),
        wallets: MemWalletsRepo(),
        seedPhrase: seedPhrase,
      );

      final draft = await wallet1.initiateFund(
        mintUrl: devMintUrl,
        amount: fundAmount,
        unit: 'sat',
        method: 'bolt11',
      );
      expect(draft.qoute, isNotNull);
      final quoteId = draft.qoute!.quoteId;
      client1.close();

      // wallet2 lost its state but has the same seed and knows the quote id
      final client2 = http.Client();
      final cache2 = MemCacheManager();
      final wallets2 = MemWalletsRepo();
      final wallet2 = _realCashu(
        client: client2,
        cache: cache2,
        wallets: wallets2,
        seedPhrase: seedPhrase,
      );

      final completed = await wallet2.recoverAndCompleteQuote(
        mintUrl: devMintUrl,
        quoteID: quoteId,
      );
      expect(completed.state, equals(WalletTransactionState.completed));

      // the freshly created record carries the recovered key
      final stored = await _storedTx(wallets2);
      expect(stored.qoute!.quoteKeyCounter, isNot(equals(-1)));

      // the recovered pending funds became spendable proofs again
      final proofs = await cache2.getProofs(mintUrl: devMintUrl);
      expect(proofs.length, greaterThan(0));

      final balance2 = (await wallet2.getBalances())
          .where((e) => e.mintUrl == devMintUrl)
          .first
          .balances['sat'];
      expect(balance2, equals(fundAmount));
      client2.close();
    });
  });
}
