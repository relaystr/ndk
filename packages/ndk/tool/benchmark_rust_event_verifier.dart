import 'dart:convert';

import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';

const _warmupIterations = 1000;
const _sampleIterations = 5000;
const _sampleCount = 9;

Future<void> main() async {
  final keyPair = Bip340.generatePrivateKey();
  final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  const content = 'RustEventVerifier benchmark event';
  final id = Nip01Utils.calculateEventIdSync(
    pubKey: keyPair.publicKey,
    createdAt: createdAt,
    kind: 1,
    tags: const [],
    content: content,
  );
  final event = Nip01Event(
    id: id,
    pubKey: keyPair.publicKey,
    createdAt: createdAt,
    kind: 1,
    tags: const [],
    content: content,
    sig: Bip340.sign(id, keyPair.privateKey!),
  );
  final verifier = RustEventVerifier();

  for (var iteration = 0; iteration < _warmupIterations; iteration++) {
    if (!await verifier.verify(event)) {
      throw StateError('Warmup verification failed.');
    }
  }

  final samples = <double>[];
  for (var sample = 0; sample < _sampleCount; sample++) {
    final stopwatch = Stopwatch()..start();
    for (var iteration = 0; iteration < _sampleIterations; iteration++) {
      if (!await verifier.verify(event)) {
        throw StateError('Benchmark verification failed.');
      }
    }
    stopwatch.stop();
    samples.add(stopwatch.elapsedMicroseconds * 1000 / _sampleIterations);
  }

  samples.sort();
  final medianNanosecondsPerOperation = samples[samples.length ~/ 2];
  // ignore: avoid_print
  print(
    jsonEncode([
      {
        'name': 'RustEventVerifier.verify',
        'unit': 'ns/op',
        'value': medianNanosecondsPerOperation,
        'range':
            '${samples.first.toStringAsFixed(0)}-${samples.last.toStringAsFixed(0)}',
        'extra': '$_sampleCount samples x $_sampleIterations operations after '
            '$_warmupIterations warmup operations',
      },
    ]),
  );
}
