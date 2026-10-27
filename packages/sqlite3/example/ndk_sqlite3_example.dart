// ignore_for_file: avoid_print
import 'package:ndk/ndk.dart';
import 'package:ndk_sqlite3/ndk_sqlite3.dart';

Future<void> main() async {
  final cache = SqliteCacheManager.open('ndk_cache.db');
  final ndk = Ndk(
    // NdkEventVerifier lives in ndk_flutter; in production RustEventVerifier() is recommended
    NdkConfig(cache: cache, eventVerifier: Bip340EventVerifier()),
  );

  final metadata = await ndk.metadata.loadMetadata(
    '32e1827635450ebb3c5a7d12c1f8e7b2b514439ac10a67eef3d9fd9c5c68e245',
  );
  print('name: ${metadata?.name}');

  await ndk.destroy();
  await cache.close();
}
