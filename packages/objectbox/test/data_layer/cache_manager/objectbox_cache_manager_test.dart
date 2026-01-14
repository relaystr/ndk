// ignore_for_file: avoid_print

import 'dart:io';

import 'package:ndk_cache_manager_test_suite/ndk_cache_manager_test_suite.dart';
import 'package:ndk_objectbox/ndk_objectbox.dart';

void main() async {
  // Run shared test suite for comprehensive coverage
  late Directory sharedTempDir;

  runCacheManagerTestSuite(
    name: 'ObjectBoxCacheManager (Shared Suite)',
    createCacheManager: () async {
      sharedTempDir =
          await Directory.systemTemp.createTemp('objectbox_shared_test');
      final cacheManager = DbObjectBox(directory: sharedTempDir.path);
      await cacheManager.dbRdy;
      return cacheManager;
    },
    cleanUp: (cacheManager) async {
      await cacheManager.close();
      try {
        await sharedTempDir.delete(recursive: true);
      } catch (_) {}
    },
  );
}
