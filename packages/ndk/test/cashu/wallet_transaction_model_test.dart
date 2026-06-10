import 'dart:convert';
import 'dart:math';

import 'package:test/test.dart';
import 'package:ndk/data_layer/models/wallet_transaction_model.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet_transaction.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet_type.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_keyset.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_quote.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_quote_melt.dart';
import 'package:ndk/domain_layer/usecases/cashu/cashu_keypair.dart';

void main() {
  test('cashu transaction json encode/decode round-trip (many iterations)', () {
    const mintUrl = 'https://mint.test';

    final rnd = Random(42);
    const iterations = 100;

    for (var i = 0; i < iterations; i++) {
      final keyset = CahsuKeyset(
        id: 'keyset-$i',
        mintUrl: mintUrl,
        unit: 'sat',
        active: i % 2 == 0,
        inputFeePPK: i,
        mintKeyPairs: {CahsuMintKeyPair(amount: i + 1, pubkey: 'pk-$i')},
      );

      final quoteKey = CashuKeypair(privateKey: 'priv-$i', publicKey: 'pub-$i');
      final quote = CashuQuote(
        quoteId: 'quote-$i',
        request: 'req-$i',
        amount: i * 10 + 1,
        unit: 'sat',
        state: CashuQuoteState.unpaid,
        expiry: 3600 + i,
        mintUrl: mintUrl,
        quoteKey: quoteKey,
      );

      final quoteMelt = CashuQuoteMelt(
        quoteId: 'melt-$i',
        amount: i + 5,
        feeReserve: i % 3,
        paid: i % 2 == 0,
        expiry: 1000 + i,
        mintUrl: mintUrl,
        state: CashuQuoteState.unpaid,
        unit: 'sat',
        request: 'melt-req-$i',
      );

      final proofCount = 1 + rnd.nextInt(3);
      final proofPks = List.generate(proofCount, (idx) => 'pk-$i-$idx');

      final tx = CashuWalletTransaction(
        id: 'tx-$i',
        walletId: 'wallet-$i',
        changeAmount: i * (i.isEven ? 1 : -1),
        unit: 'sat',
        walletType: WalletType.CASHU,
        state: WalletTransactionState
            .values[i % WalletTransactionState.values.length],
        mintUrl: mintUrl,
        note: 'note-$i',
        method: 'method-${i % 2}',
        qoute: quote,
        qouteMelt: quoteMelt,
        usedKeysets: [keyset],
        token: 'tok-$i',
        proofPubKeys: proofPks,
      );

      final encoded = jsonEncode(WalletTransactionModel.toJson(tx));
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;

      final restored =
          WalletTransactionModel.fromJson(decoded) as CashuWalletTransaction;

      expect(restored.id, equals(tx.id));
      expect(restored.walletId, equals(tx.walletId));
      expect(restored.mintUrl, equals(tx.mintUrl));
      expect(restored.note, equals(tx.note));
      expect(restored.method, equals(tx.method));
      expect(restored.token, equals(tx.token));
      expect(restored.proofPubKeys, equals(tx.proofPubKeys));
      expect(restored.usedKeysets?.first.id, equals(keyset.id));
      expect(restored.qoute?.quoteId, equals(quote.quoteId));
      expect(restored.qoute?.amount, equals(quote.amount));
      expect(restored.qouteMelt?.quoteId, equals(quoteMelt.quoteId));
    }
  });
}
