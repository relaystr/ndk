import 'package:flutter/material.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_rust_verifier/data_layer/repositories/verifiers/rust_event_verifier.dart';

class MyVerifiers {
  static final bip340Verifier = Bip340EventVerifier();
  static final rustVerifier = RustEventVerifier();
}

class QueryPerformancePage extends StatefulWidget {
  final Ndk ndk;
  const QueryPerformancePage({super.key, required this.ndk});

  @override
  State<QueryPerformancePage> createState() => _QueryPerformancePageState();
}

class _QueryPerformancePageState extends State<QueryPerformancePage> {
  int _eventCount = 100;
  String _bip340Time = '';
  String _rustTime = '';
  bool _isVerifyingBip340 = false;
  bool _isVerifyingRust = false;

  static const relays = ["ws://localhost:10547"];

  final ndkBip340 = Ndk(NdkConfig(
    eventVerifier: MyVerifiers.bip340Verifier,
    cache: MemCacheManager(),
    bootstrapRelays: relays,
  ));

  final ndkRust = Ndk(NdkConfig(
    eventVerifier: MyVerifiers.rustVerifier,
    cache: MemCacheManager(),
    bootstrapRelays: relays,
  ));

  Future<void> _runBip340Query() async {
    setState(() {
      _isVerifyingBip340 = true;
      _bip340Time = '';
    });

    final stopwatch = Stopwatch()..start();
    await _runQuery(ndkBip340);
    stopwatch.stop();

    setState(() {
      _isVerifyingBip340 = false;
      _bip340Time = '${stopwatch.elapsedMilliseconds}ms';
    });
  }

  Future<void> _runRustQuery() async {
    setState(() {
      _isVerifyingRust = true;
      _rustTime = '';
    });

    final stopwatch = Stopwatch()..start();
    await _runQuery(ndkRust);
    stopwatch.stop();

    setState(() {
      _isVerifyingRust = false;
      _rustTime = '${stopwatch.elapsedMilliseconds}ms';
    });
  }

  _runQuery(Ndk ndk) async {
    final query = ndk.requests.query(
      filters: [
        Filter(
          kinds: [1],
          limit: _eventCount,
        )
      ],
      cacheRead: false,
      cacheWrite: false,
    );
    await query.future;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Query Performance'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Event Count',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _eventCount = int.tryParse(value) ?? 100;
                });
              },
              controller: TextEditingController(text: _eventCount.toString()),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isVerifyingBip340 ? null : _runBip340Query,
              child: _isVerifyingBip340
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Run with BIP340'),
            ),
            const SizedBox(height: 8),
            Text(
              _bip340Time.isEmpty ? 'Not run yet' : 'Time: $_bip340Time',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isVerifyingRust ? null : _runRustQuery,
              child: _isVerifyingRust
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Run with Rust'),
            ),
            const SizedBox(height: 8),
            Text(
              _rustTime.isEmpty ? 'Not run yet' : 'Time: $_rustTime',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
