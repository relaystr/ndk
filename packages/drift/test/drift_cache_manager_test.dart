import 'package:drift/native.dart';
import 'package:ndk_drift/ndk_drift.dart';
import 'package:ndk/testing.dart';

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
