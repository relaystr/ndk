import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

import '../cashu/cashu_test_tools.dart';

void main() {
  test('cached mint metadata does not discover a Cashu wallet', () async {
    const mintUrl = 'https://mint.example.com';
    final cache = MemCacheManager();
    await cache.saveMintInfo(
      mintInfo: CashuMintInfo(
        name: 'Example Mint',
        nuts: const {},
        urls: const [mintUrl],
      ),
    );
    final cashu = CashuTestTools.mockHttpCashu(customCache: cache);
    await cashu.knownMints.firstWhere((mints) => mints.isNotEmpty);

    final provider = CashuWalletProvider(cashu);

    expect(await provider.discoveredWallets.first, isEmpty);
  });
}
