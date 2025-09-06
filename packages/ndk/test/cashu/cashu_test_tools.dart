import 'package:ndk/data_layer/data_sources/http_request.dart';
import 'package:ndk/data_layer/repositories/cashu/cashu_repo_impl.dart';
import 'package:ndk/domain_layer/repositories/cashu_repo.dart';
import 'package:ndk/ndk.dart';

import 'mocks/cashu_http_client_mock.dart';

class CashuTestTools {
  static Cashu mockHttpCashu({
    MockCashuHttpClient? customMockClient,
    CacheManager? customCache,
  }) {
    final MockCashuHttpClient mockClient =
        customMockClient ?? MockCashuHttpClient();
    final HttpRequestDS httpRequestDS = HttpRequestDS(mockClient);

    final CashuRepo cashuRepo = CashuRepoImpl(
      client: httpRequestDS,
    );

    final CacheManager cache = customCache ?? MemCacheManager();

    final cashu = Cashu(
      cashuRepo: cashuRepo,
      cacheManager: cache,
    );
    return cashu;
  }
}
