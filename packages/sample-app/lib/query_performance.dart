import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_rust_verifier/data_layer/repositories/verifiers/rust_event_verifier.dart';
import 'package:web_event_verifier/web_event_verifier.dart';

class MyVerifiers {
  static final bip340Verifier = Bip340EventVerifier();
  static final rustVerifier = RustEventVerifier();
  static final webVerifier = kIsWeb ? WebEventVerifier() : null;
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
  String _webTime = '';
  bool _isVerifyingBip340 = false;
  bool _isVerifyingRust = false;
  bool _isVerifyingWeb = false;

  final _relayController = TextEditingController(text: 'ws://localhost:10547');

  List<String> get _relays => [_relayController.text];

  Ndk _createNdk(EventVerifier verifier) {
    return Ndk(NdkConfig(
      eventVerifier: verifier,
      cache: MemCacheManager(),
      bootstrapRelays: _relays,
    ));
  }

  Future<void> _runBip340Query() async {
    setState(() {
      _isVerifyingBip340 = true;
      _bip340Time = '';
    });

    final ndk = _createNdk(MyVerifiers.bip340Verifier);
    final stopwatch = Stopwatch()..start();
    await _runQuery(ndk);
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

    final ndk = _createNdk(MyVerifiers.rustVerifier);
    final stopwatch = Stopwatch()..start();
    await _runQuery(ndk);
    stopwatch.stop();

    setState(() {
      _isVerifyingRust = false;
      _rustTime = '${stopwatch.elapsedMilliseconds}ms';
    });
  }

  Future<void> _runWebQuery() async {
    if (!kIsWeb || MyVerifiers.webVerifier == null) return;
    setState(() {
      _isVerifyingWeb = true;
      _webTime = '';
    });

    final ndk = _createNdk(MyVerifiers.webVerifier!);
    final stopwatch = Stopwatch()..start();
    await _runQuery(ndk);
    stopwatch.stop();

    setState(() {
      _isVerifyingWeb = false;
      _webTime = '${stopwatch.elapsedMilliseconds}ms';
    });
  }

  _runQuery(Ndk ndk) async {
    final query = ndk.requests.query(
      filter: Filter(
        kinds: [1],
        limit: _eventCount,
      ),
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
    _relayController.dispose();
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
                labelText: 'Relay URL',
                border: OutlineInputBorder(),
              ),
              controller: _relayController,
            ),
            const SizedBox(height: 16),
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
            if (kIsWeb) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isVerifyingWeb ? null : _runWebQuery,
                child: _isVerifyingWeb
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Run with Web (nostr-tools)'),
              ),
              const SizedBox(height: 8),
              Text(
                _webTime.isEmpty ? 'Not run yet' : 'Time: $_webTime',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
