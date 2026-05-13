// ignore_for_file: avoid_print

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

    print('Wallets (${wallets.length}):');
    for (final wallet in wallets) {
      print(
        '- id=${wallet.id} name=${wallet.name} '
        'type=${wallet.type.value} units=${wallet.supportedUnits.join(',')}',
      );
    }
  } finally {
    await ndk.destroy();
  }
}
