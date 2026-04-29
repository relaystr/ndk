// ignore_for_file: avoid_print

import 'dart:io';

import 'package:ndk/data_layer/repositories/wallets/sembast_wallets_repo.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_user_seedphrase.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet_type.dart';

Future<void> main() async {
  final nwcUri = Platform.environment['NWC_URI']!;
  final walletName = Platform.environment['WALLET_NAME'] ?? 'My NWC Wallet';

  final examplesDir = Directory.current.absolute;
  final dbPath = '${examplesDir.path}/wallets_db.db';
  final walletsRepo = await SembastWalletsRepo.create(filename: dbPath);
  final ndk = Ndk(
    NdkConfig(
      cache: MemCacheManager(),
      walletsRepo: walletsRepo,
      eventVerifier: Bip340EventVerifier(),
      bootstrapRelays: const [],
      cashuUserSeedphrase: CashuUserSeedphrase(
        seedPhrase: CashuSeed.generateSeedPhrase(),
      ),
    ),
  );

  try {
    NostrWalletConnectUri.parseConnectionUri(nwcUri);

    final wallet = ndk.wallets.createWallet(
      id: 'wallet_${DateTime.now().microsecondsSinceEpoch}',
      name: walletName,
      type: WalletType.NWC,
      supportedUnits: {'sat'},
      metadata: {'nwcUrl': nwcUri},
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
