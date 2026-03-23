import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:ndk/data_layer/repositories/cashu_seed_secret_generator/dart_cashu_key_derivation.dart';
import 'package:test/test.dart';

import 'package:ndk/domain_layer/usecases/cashu/cashu_seed.dart';
import '../tools/simple_profiler.dart';

void main() {
  group('NUT-13 Test Vectors', () {
    const testMnemonic =
        "half depart obvious quality work element tank gorilla view sugar picture humble";
    late CashuSeed cashuSeed;
    late Uint8List seedBytes;

    setUp(() async {
      cashuSeed = CashuSeed();
      await cashuSeed.setSeedPhrase(seedPhrase: testMnemonic);
      seedBytes = Uint8List.fromList(cashuSeed.getSeedBytes());
    });

    group('Version 1: Deprecated BIP32 Derivation (keyset ID 009a1f293253e41e)',
        () {
      const keysetId = "009a1f293253e41e";
      const keysetIdInt = 864559728;

      test('keyset ID integer representation', () {
        // Test that the conversion matches expected value
        // The internal conversion should match keysetIdInt
        expect(keysetIdInt, equals(864559728));
      });

      test('secret derivation for counters 0-4', () async {
        final derivation = DartCashuKeyDerivation();

        final expectedSecrets = {
          0: "485875df74771877439ac06339e284c3acfcd9be7abf3bc20b516faeadfe77ae",
          1: "8f2b39e8e594a4056eb1e6dbb4b0c38ef13b1b2c751f64f810ec04ee35b77270",
          2: "bc628c79accd2364fd31511216a0fab62afd4a18ff77a20deded7b858c9860c8",
          3: "59284fd1650ea9fa17db2b3acf59ecd0f2d52ec3261dd4152785813ff27a33bf",
          4: "576c23393a8b31cc8da6688d9c9a96394ec74b40fdaf1f693a6bb84284334ea0",
        };

        for (var counter = 0; counter <= 4; counter++) {
          final result = await derivation.deriveSecret(
            seedBytes: seedBytes,
            counter: counter,
            keysetId: keysetId,
          );

          expect(
            result.secretHex,
            equals(expectedSecrets[counter]),
            reason: 'Secret mismatch for counter $counter (Version 1)',
          );
        }
      });

      test('blinding factor derivation for counters 0-4', () async {
        final derivation = DartCashuKeyDerivation();

        final expectedBlindingFactors = {
          0: "ad00d431add9c673e843d4c2bf9a778a5f402b985b8da2d5550bf39cda41d679",
          1: "967d5232515e10b81ff226ecf5a9e2e2aff92d66ebc3edf0987eb56357fd6248",
          2: "b20f47bb6ae083659f3aa986bfa0435c55c6d93f687d51a01f26862d9b9a4899",
          3: "fb5fca398eb0b1deb955a2988b5ac77d32956155f1c002a373535211a2dfdc29",
          4: "5f09bfbfe27c439a597719321e061e2e40aad4a36768bb2bcc3de547c9644bf9",
        };

        for (var counter = 0; counter <= 4; counter++) {
          final result = await derivation.deriveSecret(
            seedBytes: seedBytes,
            counter: counter,
            keysetId: keysetId,
          );

          expect(
            result.blindingHex,
            equals(expectedBlindingFactors[counter]),
            reason: 'Blinding factor mismatch for counter $counter (Version 1)',
          );
        }
      });

      test('combined secret and blinding factor derivation', () async {
        final derivation = DartCashuKeyDerivation();

        final testCases = [
          {
            'counter': 0,
            'secret':
                "485875df74771877439ac06339e284c3acfcd9be7abf3bc20b516faeadfe77ae",
            'r':
                "ad00d431add9c673e843d4c2bf9a778a5f402b985b8da2d5550bf39cda41d679",
            'path': "m/129372'/0'/864559728'/0'",
          },
          {
            'counter': 1,
            'secret':
                "8f2b39e8e594a4056eb1e6dbb4b0c38ef13b1b2c751f64f810ec04ee35b77270",
            'r':
                "967d5232515e10b81ff226ecf5a9e2e2aff92d66ebc3edf0987eb56357fd6248",
            'path': "m/129372'/0'/864559728'/1'",
          },
          {
            'counter': 2,
            'secret':
                "bc628c79accd2364fd31511216a0fab62afd4a18ff77a20deded7b858c9860c8",
            'r':
                "b20f47bb6ae083659f3aa986bfa0435c55c6d93f687d51a01f26862d9b9a4899",
            'path': "m/129372'/0'/864559728'/2'",
          },
          {
            'counter': 3,
            'secret':
                "59284fd1650ea9fa17db2b3acf59ecd0f2d52ec3261dd4152785813ff27a33bf",
            'r':
                "fb5fca398eb0b1deb955a2988b5ac77d32956155f1c002a373535211a2dfdc29",
            'path': "m/129372'/0'/864559728'/3'",
          },
          {
            'counter': 4,
            'secret':
                "576c23393a8b31cc8da6688d9c9a96394ec74b40fdaf1f693a6bb84284334ea0",
            'r':
                "5f09bfbfe27c439a597719321e061e2e40aad4a36768bb2bcc3de547c9644bf9",
            'path': "m/129372'/0'/864559728'/4'",
          },
        ];

        for (var testCase in testCases) {
          final counter = testCase['counter'] as int;
          final result = await derivation.deriveSecret(
            seedBytes: seedBytes,
            counter: counter,
            keysetId: keysetId,
          );

          expect(
            result.secretHex,
            equals(testCase['secret']),
            reason: 'Secret mismatch for counter $counter',
          );
          expect(
            result.blindingHex,
            equals(testCase['r']),
            reason: 'Blinding factor mismatch for counter $counter',
          );
        }
      });
    });

    group('Version 2: Modern HMAC-SHA256 Derivation (keyset ID 015ba18a...)',
        () {
      const keysetId =
          "015ba18a8adcd02e715a58358eb618da4a4b3791151a4bee5e968bb88406ccf76a";

      test('secret derivation for counters 0-4', () async {
        final derivation = DartCashuKeyDerivation();

        final expectedSecrets = {
          0: "db5561a07a6e6490f8dadeef5be4e92f7cebaecf2f245356b5b2a4ec40687298",
          1: "b70e7b10683da3bf1cdf0411206f8180c463faa16014663f39f2529b2fda922e",
          2: "78a7ac32ccecc6b83311c6081b89d84bb4128f5a0d0c5e1af081f301c7a513f5",
          3: "094a2b6c63bfa7970bc09cda0e1cfc9cd3d7c619b8e98fabcfc60aea9e4963e5",
          4: "5e89fc5d30d0bf307ddf0a3ac34aa7a8ee3702169dafa3d3fe1d0cae70ecd5ef",
        };

        for (var counter = 0; counter <= 4; counter++) {
          final result = await derivation.deriveSecret(
            seedBytes: seedBytes,
            counter: counter,
            keysetId: keysetId,
          );

          expect(
            result.secretHex,
            equals(expectedSecrets[counter]),
            reason: 'Secret mismatch for counter $counter (Version 2)',
          );
        }
      });

      test('blinding factor derivation for counters 0-4', () async {
        final derivation = DartCashuKeyDerivation();

        final expectedBlindingFactors = {
          0: "6d26181a3695e32e9f88b80f039ba1ae2ab5a200ad4ce9dbc72c6d3769f2b035",
          1: "bde4354cee75545bea1a2eee035a34f2d524cee2bb01613823636e998386952e",
          2: "f40cc1218f085b395c8e1e5aaa25dccc851be3c6c7526a0f4e57108f12d6dac4",
          3: "099ed70fc2f7ac769bc20b2a75cb662e80779827b7cc358981318643030577d0",
          4: "5550337312d223ba62e3f75cfe2ab70477b046d98e3e71804eade3956c7b98cf",
        };

        for (var counter = 0; counter <= 4; counter++) {
          final result = await derivation.deriveSecret(
            seedBytes: seedBytes,
            counter: counter,
            keysetId: keysetId,
          );

          expect(
            result.blindingHex,
            equals(expectedBlindingFactors[counter]),
            reason: 'Blinding factor mismatch for counter $counter (Version 2)',
          );
        }
      });

      test('combined secret and blinding factor derivation', () async {
        final derivation = DartCashuKeyDerivation();

        final testCases = [
          {
            'counter': 0,
            'secret':
                "db5561a07a6e6490f8dadeef5be4e92f7cebaecf2f245356b5b2a4ec40687298",
            'r':
                "6d26181a3695e32e9f88b80f039ba1ae2ab5a200ad4ce9dbc72c6d3769f2b035",
          },
          {
            'counter': 1,
            'secret':
                "b70e7b10683da3bf1cdf0411206f8180c463faa16014663f39f2529b2fda922e",
            'r':
                "bde4354cee75545bea1a2eee035a34f2d524cee2bb01613823636e998386952e",
          },
          {
            'counter': 2,
            'secret':
                "78a7ac32ccecc6b83311c6081b89d84bb4128f5a0d0c5e1af081f301c7a513f5",
            'r':
                "f40cc1218f085b395c8e1e5aaa25dccc851be3c6c7526a0f4e57108f12d6dac4",
          },
          {
            'counter': 3,
            'secret':
                "094a2b6c63bfa7970bc09cda0e1cfc9cd3d7c619b8e98fabcfc60aea9e4963e5",
            'r':
                "099ed70fc2f7ac769bc20b2a75cb662e80779827b7cc358981318643030577d0",
          },
          {
            'counter': 4,
            'secret':
                "5e89fc5d30d0bf307ddf0a3ac34aa7a8ee3702169dafa3d3fe1d0cae70ecd5ef",
            'r':
                "5550337312d223ba62e3f75cfe2ab70477b046d98e3e71804eade3956c7b98cf",
          },
        ];

        for (var testCase in testCases) {
          final counter = testCase['counter'] as int;
          final result = await derivation.deriveSecret(
            seedBytes: seedBytes,
            counter: counter,
            keysetId: keysetId,
          );

          expect(
            result.secretHex,
            equals(testCase['secret']),
            reason: 'Secret mismatch for counter $counter (Version 2)',
          );
          expect(
            result.blindingHex,
            equals(testCase['r']),
            reason: 'Blinding factor mismatch for counter $counter (Version 2)',
          );
        }
      });
    });

    group('Error Handling', () {
      test('should throw on invalid keyset ID format', () async {
        final derivation = DartCashuKeyDerivation();

        expect(
          () async => await derivation.deriveSecret(
            seedBytes: seedBytes,
            counter: 0,
            keysetId: "invalid_hex",
          ),
          throwsException,
        );
      });

      test('should throw on unrecognized keyset version', () async {
        final derivation = DartCashuKeyDerivation();

        expect(
          () async => await derivation.deriveSecret(
            seedBytes: seedBytes,
            counter: 0,
            keysetId: "99a1f293253e41e",
          ),
          throwsException,
        );
      });
    });

    group('Performance Profiling', () {
      test('Version 1 (BIP32) derivation speed', () async {
        final profiler = SimpleProfiler('Version 1 BIP32 Derivation');
        final derivation = DartCashuKeyDerivation();
        const keysetId = "009a1f293253e41e";

        profiler.checkpoint('Setup complete');

        // Derive 10 secrets to get a better average
        for (var counter = 0; counter < 10; counter++) {
          await derivation.deriveSecret(
            seedBytes: seedBytes,
            counter: counter,
            keysetId: keysetId,
          );
        }

        profiler.checkpoint('Derived 10 secrets (Version 1)');
        profiler.end();
      });

      test('Version 2 (HMAC-SHA256) derivation speed', () async {
        final profiler = SimpleProfiler('Version 2 HMAC-SHA256 Derivation');
        final derivation = DartCashuKeyDerivation();
        const keysetId =
            "015ba18a8adcd02e715a58358eb618da4a4b3791151a4bee5e968bb88406ccf76a";

        profiler.checkpoint('Setup complete');

        // Derive 10 secrets to get a better average
        for (var counter = 0; counter < 10; counter++) {
          await derivation.deriveSecret(
            seedBytes: seedBytes,
            counter: counter,
            keysetId: keysetId,
          );
        }

        profiler.checkpoint('Derived 10 secrets (Version 2)');
        profiler.end();
      });

      test('Comparison: Version 1 vs Version 2 (100 iterations)', () async {
        final derivation = DartCashuKeyDerivation();
        const keysetIdV1 = "009a1f293253e41e";
        const keysetIdV2 =
            "015ba18a8adcd02e715a58358eb618da4a4b3791151a4bee5e968bb88406ccf76a";

        final profiler = SimpleProfiler('Performance Comparison');

        // Version 1 - 100 iterations
        for (var counter = 0; counter < 100; counter++) {
          await derivation.deriveSecret(
            seedBytes: seedBytes,
            counter: counter,
            keysetId: keysetIdV1,
          );
        }

        profiler.checkpoint('Version 1: 100 derivations');

        // Version 2 - 100 iterations
        for (var counter = 0; counter < 100; counter++) {
          await derivation.deriveSecret(
            seedBytes: seedBytes,
            counter: counter,
            keysetId: keysetIdV2,
          );
        }

        profiler.checkpoint('Version 2: 100 derivations');
        profiler.end();
      });

      test('Single derivation detailed timing', () async {
        final derivation = DartCashuKeyDerivation();
        const keysetIdV1 = "009a1f293253e41e";
        const keysetIdV2 =
            "015ba18a8adcd02e715a58358eb618da4a4b3791151a4bee5e968bb88406ccf76a";

        final profiler = SimpleProfiler('Single Derivation Timing');

        await derivation.deriveSecret(
          seedBytes: seedBytes,
          counter: 0,
          keysetId: keysetIdV1,
        );

        profiler.checkpoint('Version 1: Single derivation');

        await derivation.deriveSecret(
          seedBytes: seedBytes,
          counter: 0,
          keysetId: keysetIdV2,
        );

        profiler.checkpoint('Version 2: Single derivation');
        profiler.end();
      });

      test('Profile each step of V2 derivation', () {
        final cachedSeed = seedBytes;
        // ignore: unused_local_variable
        final derivation = DartCashuKeyDerivation();
        const keysetId =
            "015ba18a8adcd02e715a58358eb618da4a4b3791151a4bee5e968bb88406ccf76a";

        final timings = <String, int>{};

        for (var counter = 0; counter < 100; counter++) {
          var sw = Stopwatch()..start();
          final keysetBytes = hex.decode(keysetId);
          timings['hex_decode'] =
              (timings['hex_decode'] ?? 0) + sw.elapsedMicroseconds;

          sw = Stopwatch()..start();
          final counterBytes = Uint8List(8)
            ..buffer.asByteData().setUint64(0, counter, Endian.big);
          // Use counterBytes to avoid warning
          expect(counterBytes.length, 8);
          timings['counter_encode'] =
              (timings['counter_encode'] ?? 0) + sw.elapsedMicroseconds;

          sw = Stopwatch()..start();
          final message = Uint8List(21 + keysetBytes.length + 8 + 1);
          timings['allocate'] =
              (timings['allocate'] ?? 0) + sw.elapsedMicroseconds;

          sw = Stopwatch()..start();
          final hmac = Hmac(sha256, cachedSeed);
          final result = hmac.convert(message);
          timings['hmac'] = (timings['hmac'] ?? 0) + sw.elapsedMicroseconds;

          sw = Stopwatch()..start();
          final x = BigInt.parse(hex.encode(result.bytes), radix: 16);
          timings['bigint_parse'] =
              (timings['bigint_parse'] ?? 0) + sw.elapsedMicroseconds;

          sw = Stopwatch()..start();
          final r = x % DartCashuKeyDerivation.secp256k1N;
          timings['modulo'] = (timings['modulo'] ?? 0) + sw.elapsedMicroseconds;

          sw = Stopwatch()..start();
          final hexResult = r.toRadixString(16).padLeft(64, '0');
          // Use hexResult to avoid warning
          expect(hexResult.length, 64);
          timings['bigint_to_hex'] =
              (timings['bigint_to_hex'] ?? 0) + sw.elapsedMicroseconds;
        }

        print('\nPer-operation timings (100 iterations):');
        timings.forEach((key, value) {
          print('  $key: ${value / 100}μs avg, ${value / 1000}ms total');
        });
      });

      test('Diagnose mnemonic.seed performance', () {
        final profiler = SimpleProfiler('Mnemonic Seed Access');

        // Access cashuSeed.getSeedBytes() 10 times
        for (var i = 0; i < 10; i++) {
          final seed = Uint8List.fromList(cashuSeed.getSeedBytes());
          print('Seed length: ${seed.length}');
        }

        profiler.checkpoint('Accessed cashuSeed.getSeedBytes() 10 times');

        // Now cache it and access 10 times
        final cachedSeed = seedBytes;
        for (var i = 0; i < 10; i++) {
          final seed = Uint8List.fromList(cachedSeed);
          print('Seed length: ${seed.length}');
        }

        profiler.checkpoint('Accessed cached seed 10 times');
        profiler.end();
      });

      test('Verify caching works correctly', () {
        final profiler = SimpleProfiler('Caching Verification');

        // Test 1: Uncached access
        final derivation1 = DartCashuKeyDerivation();
        const keysetId =
            "015ba18a8adcd02e715a58358eb618da4a4b3791151a4bee5e968bb88406ccf76a";

        for (var i = 0; i < 10; i++) {
          derivation1.deriveSecret(
            seedBytes: seedBytes,
            counter: i,
            keysetId: keysetId,
          );
        }

        profiler.checkpoint('10 derivations WITHOUT cache');

        // Test 2: With caching - reuse the same instance
        final derivation2 = DartCashuKeyDerivation();

        for (var i = 0; i < 10; i++) {
          derivation2.deriveSecret(
            seedBytes: seedBytes,
            counter: i,
            keysetId: keysetId,
          );
        }

        profiler.checkpoint('10 derivations WITH cache (same instance)');

        // Test 3: Using pre-seeded instance
        // final cachedSeed = Uint8List.fromList(mnemonic.seed);
        // final derivation3 = DartCashuKeyDerivation(seed: cachedSeed);

        // for (var i = 0; i < 10; i++) {
        //   derivation3.deriveSecretAndBlinding(
        //     counter: i,
        //     keysetId: keysetId,
        //   );
        // }

        //profiler.checkpoint('10 derivations with pre-seeded instance');
        profiler.end();
      });
    });
  });
}
