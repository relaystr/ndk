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

import 'mocks/cashu_http_client_mock.dart';

const mockMintUrl = 'http://mock.mint';
const paidQuoteId = 'd00e6cbc-04c9-4661-8909-e47c19612bf0';

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
}
