// ignore_for_file: avoid_print

import 'dart:io';

import 'package:ndk/data_layer/repositories/wallets/sembast_wallets_repo.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_user_seedphrase.dart';
import 'package:ndk/ndk.dart';

Future<void> main() async {
  final invoice = Platform.environment['INVOICE']!;

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
      throw StateError('No wallets stored yet.');
    }

    final walletId = Platform.environment['WALLET_ID'] ?? wallets.first.id;

    final result = await ndk.wallets.send(
      walletId: walletId,
      invoice: invoice,
    );

    print('Payment result:');
    print('- preimage: ${result.preimage}');
    print('- fees paid: ${result.feesPaid / 1000} sats');
    if (result.errorCode != null || result.errorMessage != null) {
      print('- error code: ${result.errorCode}');
      print('- error message: ${result.errorMessage}');
    }
  } finally {
    await ndk.destroy();
  }
}
