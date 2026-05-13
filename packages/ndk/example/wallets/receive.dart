// ignore_for_file: avoid_print

import 'dart:io';

import 'package:ndk/data_layer/repositories/wallets/sembast_wallets_repo.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_user_seedphrase.dart';
import 'package:ndk/ndk.dart';

Future<void> main() async {
  final ndk = Ndk(
    NdkConfig(
      cache: MemCacheManager(),
      walletsRepo: await SembastWalletsRepo.create(filename: "wallets_db.db"),
      eventVerifier: Bip340EventVerifier(),
      bootstrapRelays: const [],
      cashuUserSeedphrase: CashuUserSeedphrase(
        seedPhrase: CashuSeed.generateSeedPhrase(),
      ),
    ),
  );

  try {
    final amountSats = int.parse(Platform.environment['AMOUNT_SATS'] ?? '1000');
    final wallets = await ndk.wallets.getWallets();
    if (wallets.isEmpty) {
      throw StateError('No wallets stored yet.');
    }
    final walletId = Platform.environment['WALLET_ID'] ?? wallets.first.id;

    final invoice = await ndk.wallets.receive(
      walletId: walletId,
      amountSats: amountSats,
    );

    print('Invoice for $amountSats sats:');
    print(invoice);
  } finally {
    await ndk.destroy();
  }
}
