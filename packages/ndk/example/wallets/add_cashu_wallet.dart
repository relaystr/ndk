// ignore_for_file: avoid_print

import 'dart:io';

import 'package:ndk/data_layer/repositories/wallets/sembast_wallets_repo.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_user_seedphrase.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet_type.dart';
import 'package:ndk/ndk.dart';

Future<void> main() async {
  final mintUrl = Platform.environment['MINT_URL']!;
  final walletName = Platform.environment['WALLET_NAME'] ?? 'My Cashu Wallet';

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
    final mintInfo = await ndk.cashu.getMintInfoNetwork(mintUrl: mintUrl);

    final wallet = ndk.wallets.createWallet(
      id: 'wallet_${DateTime.now().microsecondsSinceEpoch}',
      name: walletName,
      type: WalletType.CASHU,
      supportedUnits:
          mintInfo.supportedUnits.isEmpty ? {'sat'} : mintInfo.supportedUnits,
      metadata: {
        'mintUrl': mintUrl,
        'mintInfo': mintInfo.toJson(),
      },
    );

    await ndk.wallets.addWallet(wallet);

    print('Added ${wallet.name}.');
    print('');
    final wallets = await ndk.wallets.getWallets();
    print('Wallets (${wallets.length}):');
    for (final wallet in wallets) {
      print(
        '- ${wallet.name} (${wallet.type.value}) id=${wallet.id} '
        'units=${wallet.supportedUnits.join(',')}',
      );
    }
  } finally {
    await ndk.destroy();
  }
}
