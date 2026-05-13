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
    final wallets = await ndk.wallets.getWallets();
    if (wallets.isEmpty) {
      print('No wallets stored yet.');
      return;
    }

    final walletId = Platform.environment['WALLET_ID'] ?? wallets.first.id;
    final wallet = wallets.firstWhere(
      (wallet) => wallet.id == walletId,
      orElse: () => throw StateError('Wallet not found: $walletId'),
    );

    final balances = await ndk.wallets
        .getBalancesStream(wallet.id)
        .first
        .timeout(const Duration(seconds: 12));

    if (balances.isEmpty) {
      print('No balances reported for ${wallet.name} (${wallet.id}).');
      return;
    }

    print('Balances for ${wallet.name} (${wallet.id}):');
    for (final balance in balances) {
      print('- ${balance.amount} ${balance.unit}');
    }
  } finally {
    await ndk.destroy();
  }
}
