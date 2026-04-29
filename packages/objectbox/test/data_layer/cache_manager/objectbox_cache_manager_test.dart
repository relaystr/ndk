// ignore_for_file: avoid_print

import 'dart:io';

import 'package:ndk/entities.dart';
import 'package:ndk/testing.dart';
import 'package:ndk_objectbox/ndk_objectbox.dart';
import 'package:test/test.dart';

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

  test('saveProofs and getProofs', () async {
    sharedTempDir =
        await Directory.systemTemp.createTemp('objectbox_shared_test');
    final cacheManager = DbObjectBox(directory: sharedTempDir.path);
    await cacheManager.dbRdy;

    final proof = CashuProof(
      keysetId: 'test_keyset',
      amount: 10,
      secret: 'test_secret',
      unblindedSig: 'test_sig',
      state: CashuProofState.unspend,
    );

    final cashuKeyset = CahsuKeyset(
      id: 'test_keyset',
      active: true,
      inputFeePPK: 0,
      mintKeyPairs: {},
      mintUrl: 'https://test.mint.com',
      unit: 'sat',
    );
    cacheManager.saveKeyset(cashuKeyset);

    await cacheManager
        .saveProofs(proofs: [proof], mintUrl: 'https://test.mint.com');
    final loadedProofs = await cacheManager.getProofs(
      mintUrl: 'https://test.mint.com',
      state: CashuProofState.unspend,
    );

    expect(loadedProofs.length, equals(1));
    expect(loadedProofs[0].keysetId, equals(proof.keysetId));
    expect(loadedProofs[0].amount, equals(proof.amount));
  });
}
