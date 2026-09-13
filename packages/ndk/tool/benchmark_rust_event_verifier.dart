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

  final results = <Map<String, Object>>[
    await _benchmark(verifier, event, name: 'RustEventVerifier.verify'),
  ];

  // Build and sign the larger fixture outside the timed verification loops.
  final largeTags = List.generate(
    200,
    (index) => ['x', '$index-${'a' * 1024}'],
  );
  final largeContent = 'b' * (64 * 1024);
  final largeId = Nip01Utils.calculateEventIdSync(
    pubKey: keyPair.publicKey,
    createdAt: createdAt,
    kind: 1,
    tags: largeTags,
    content: largeContent,
  );
  final largeEvent = Nip01Event(
    id: largeId,
    pubKey: keyPair.publicKey,
    createdAt: createdAt,
    kind: 1,
    tags: largeTags,
    content: largeContent,
    sig: Bip340.sign(largeId, keyPair.privateKey!),
  );
  results.add(await _benchmark(
    verifier,
    largeEvent,
    name: 'RustEventVerifier.verify.large_event',
    warmupIterations: 100,
    sampleIterations: 500,
    details: '; 200 tags with 1 KiB values, 64 KiB content',
  ));

  // ignore: avoid_print
  print(jsonEncode(results));
}

Future<Map<String, Object>> _benchmark(
  RustEventVerifier verifier,
  Nip01Event event, {
  required String name,
  int warmupIterations = _warmupIterations,
  int sampleIterations = _sampleIterations,
  String details = '',
}) async {
  for (var iteration = 0; iteration < warmupIterations; iteration++) {
    if (!await verifier.verify(event)) {
      throw StateError('$name warmup verification failed.');
    }
  }

  final samples = <double>[];
  for (var sample = 0; sample < _sampleCount; sample++) {
    final stopwatch = Stopwatch()..start();
    for (var iteration = 0; iteration < sampleIterations; iteration++) {
      if (!await verifier.verify(event)) {
        throw StateError('$name verification failed.');
      }
    }
    stopwatch.stop();
    samples.add(stopwatch.elapsedMicroseconds * 1000 / sampleIterations);
  }

  samples.sort();
  final medianNanosecondsPerOperation = samples[samples.length ~/ 2];
  return {
    'name': name,
    'unit': 'ns/op',
    'value': medianNanosecondsPerOperation,
    'range':
        '${samples.first.toStringAsFixed(0)}-${samples.last.toStringAsFixed(0)}',
    'extra': '$_sampleCount samples x $sampleIterations operations after '
        '$warmupIterations warmup operations$details',
  };
}
