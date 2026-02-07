import 'package:drift/native.dart';
import 'package:drift_cache_manager/drift_cache_manager.dart';
import 'package:ndk_cache_manager_test_suite/ndk_cache_manager_test_suite.dart';

void main() {
  runCacheManagerTestSuite(
    name: 'DriftCacheManager',
    createCacheManager: () async {
      final db = NdkCacheDatabase.forTesting(NativeDatabase.memory());
      return DriftCacheManager(db);
    },
    cleanUp: (cm) async {
      await cm.close();
    },
  );
}
