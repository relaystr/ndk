import 'package:flutter/material.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_rust_verifier/data_layer/repositories/verifiers/rust_event_verifier.dart';

class MyVerifiers {
  static final bip340Verifier = Bip340EventVerifier();
  static final rustVerifier = RustEventVerifier();
}

class VerifiersPerformancePage extends StatefulWidget {
  final Ndk ndk;
  const VerifiersPerformancePage({super.key, required this.ndk});

  @override
  State<VerifiersPerformancePage> createState() =>
      _VerifiersPerformancePageState();
}

class _VerifiersPerformancePageState extends State<VerifiersPerformancePage> {
  bool hasPubkey = false;
  final List<Nip01Event> _events = [];
  double _eventCount = 100;
  String _bip340Time = '';
  String _rustTime = '';
  bool _isGenerating = false;
  bool _isVerifyingBip340 = false;
  bool _isVerifyingRust = false;

  Future<List<Nip01Event>> _generateEvents(int count) async {
    final String? pubkey = widget.ndk.accounts.getPublicKey();
    if (pubkey == null) {
      throw Exception('No public key available');
    }
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final list = List<Nip01Event>.generate(count, (index) {
      return Nip01EventService.createEventCalculateId(
        pubKey: pubkey,
        createdAt: now,
        kind: 1,
        tags: [],
        content: 'This is event number $index',
      );
    });

    final List<Nip01Event> signedList = [];
    for (final event in list) {
      signedList.add(await widget.ndk.accounts.sign(event));
    }
    return signedList;
  }

  _verifyEventsWaiting({required EventVerifier verifier}) async {
    for (final event in _events) {
      await verifier.verify(event);
    }
  }

  _verifyEventsParallel({required EventVerifier verifier}) async {
    final futures = <Future>[];
    for (final event in _events) {
      futures.add(verifier.verify(event));
    }
    await Future.wait(futures);
  }

  Future<void> _handleGenerateEvents() async {
    setState(() {
      _isGenerating = true;
      _bip340Time = '';
      _rustTime = '';
    });
    try {
      final events = await _generateEvents(_eventCount.toInt());
      setState(() {
        _events.clear();
        _events.addAll(events);
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _handleBip340Verify() async {
    if (_events.isEmpty) return;
    setState(() {
      _isVerifyingBip340 = true;
    });
    try {
      final stopwatch = Stopwatch()..start();
      await _verifyEventsParallel(verifier: MyVerifiers.bip340Verifier);
      stopwatch.stop();
      setState(() {
        _bip340Time = '${stopwatch.elapsedMilliseconds}ms';
      });
    } finally {
      setState(() {
        _isVerifyingBip340 = false;
      });
    }
  }

  Future<void> _handleRustVerify() async {
    if (_events.isEmpty) return;
    setState(() {
      _isVerifyingRust = true;
    });
    try {
      final stopwatch = Stopwatch()..start();
      await _verifyEventsParallel(verifier: MyVerifiers.rustVerifier);
      stopwatch.stop();
      setState(() {
        _rustTime = '${stopwatch.elapsedMilliseconds}ms';
      });
    } finally {
      setState(() {
        _isVerifyingRust = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final String? pubkey = widget.ndk.accounts.getPublicKey();
    setState(() {
      hasPubkey = pubkey != null;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifiers Performance'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!hasPubkey)
              const Text(
                'No public key available. Please login first.',
                style: TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 16),
            Text(
              'Event Count: ${_eventCount.toInt()}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: _eventCount,
              min: 10,
              max: 1000,
              divisions: 99,
              label: _eventCount.toInt().toString(),
              onChanged: (value) {
                setState(() {
                  _eventCount = value;
                });
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  hasPubkey && !_isGenerating ? _handleGenerateEvents : null,
              child: _isGenerating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Generate ${_eventCount.toInt()} Events'),
            ),
            const SizedBox(height: 24),
            Text(
              'Events generated: ${_events.length}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _events.isNotEmpty && !_isVerifyingBip340
                  ? _handleBip340Verify
                  : null,
              child: _isVerifyingBip340
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Verify with BIP340'),
            ),
            const SizedBox(height: 8),
            Text(
              _bip340Time.isEmpty ? 'Not tested yet' : 'Time: $_bip340Time',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _events.isNotEmpty && !_isVerifyingRust
                  ? _handleRustVerify
                  : null,
              child: _isVerifyingRust
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Verify with Rust'),
            ),
            const SizedBox(height: 8),
            Text(
              _rustTime.isEmpty ? 'Not tested yet' : 'Time: $_rustTime',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
