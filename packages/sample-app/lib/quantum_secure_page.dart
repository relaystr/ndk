import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ndk/data_layer/repositories/signers/qs_rust_event_signer.dart';
import 'package:ndk/data_layer/repositories/verifiers/qs_rust_event_verifier.dart';
import 'package:ndk/ndk.dart';

class QuantumSecurePage extends StatefulWidget {
  const QuantumSecurePage({super.key});

  @override
  State<QuantumSecurePage> createState() => _QuantumSecurePageState();
}

class _QuantumSecurePageState extends State<QuantumSecurePage> {
  // Quantum secure parameters
  int _level = 5;

  final TextEditingController _messageController = TextEditingController();
  int _eventCount = 1000;
  String? _lastEventJson;
  bool _hasSignature = false;

  // Timing results
  double? _signTimeMs;
  double? _verifyTimeMs;
  int? _failedVerifications;

  // Signer and verifier instances
  QsRustEventSigner? _signer;
  QsRustEventVerifier? _verifier;
  QsKeypair? _keyPair;

  // Store signed events globally
  List<Nip01Event> _signedEvents = [];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _generateEvents() async {
    if (_verifier != null || _signer != null) {
      setState(() {
        _hasSignature = true; // Reuse existing keys
      });
    } else {
      // Generate new keypair
      final myKeyPair = QsRustEventSigner.generateKeypair(level: _level);

      final eventVerifier = QsRustEventVerifier(level: _level);
      final signer = QsRustEventSigner(level: _level, keypair: myKeyPair);

      setState(() {
        _keyPair = myKeyPair;
        _verifier = eventVerifier;
        _signer = signer;
        _hasSignature = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Generated $_eventCount events for quantum secure signing')),
      );
    }

    // Sign events
    try {
      if (_signer == null || _keyPair == null) {
        throw Exception('Signer not initialized');
      }

      // Create unsigned events
      final unsignedEvents = List.generate(
        _eventCount,
        (index) => Nip01Event(
          content: _messageController.text.isEmpty
              ? 'hello message $index'
              : _messageController.text,
          kind: 1,
          pubKey: '',
          tags: [],
        ),
      );

      final startTime = DateTime.now();

      // Sign all events in parallel
      final signedEvents = await Future.wait(
        unsignedEvents.map((event) => _signer!.sign(event)),
      );

      final endTime = DateTime.now();
      _signTimeMs =
          (endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch)
              .toDouble();

      // Get the last signed event details
      final lastSignedEvent = signedEvents.last;
      setState(() {
        // Manually construct JSON-like representation from Nip01Event fields
        _lastEventJson =
            jsonEncode(Nip01EventModel.fromEntity(lastSignedEvent).toJson());
        // Store all signed events globally for verification
        _signedEvents = List.from(signedEvents);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Signed $_eventCount events in ${_signTimeMs!.toStringAsFixed(2)} ms'),
        ),
      );
    } catch (e) {
      setState(() {
        _signTimeMs = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing events: $e')),
      );
    }
  }

  Future<void> _verifyEvents() async {
    if (_signer == null || _verifier == null || _signedEvents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please generate events first')),
      );
      return;
    }

    setState(() {
      _verifyTimeMs = null;
      _failedVerifications = null;
    });

    try {
      if (_verifier == null) {
        throw Exception('Verifier not initialized');
      }

      final startTime = DateTime.now();

      // Verify all stored signed events
      final isValidations = await Future.wait(
        _signedEvents.map((signedEvent) => _verifier!.verify(signedEvent)),
      );

      final endTime = DateTime.now();
      _verifyTimeMs =
          (endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch)
              .toDouble();

      // Check if all verifications passed
      int failedCount = isValidations.where((valid) => !valid).length;
      setState(() {
        _failedVerifications = failedCount;
      });

      bool allValid = isValidations.every((valid) => valid);

      String statusMessage =
          'Verified ${_signedEvents.length} events in ${_verifyTimeMs!.toStringAsFixed(2)} ms';
      if (failedCount > 0) {
        statusMessage += ' ($failedCount failed)';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(statusMessage)),
      );

      if (!allValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Some verifications failed!')),
        );
      }
    } catch (e) {
      setState(() {
        _verifyTimeMs = null;
        _failedVerifications = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error verifying events: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quantum Secure Sign/Verify Demo'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Information text
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'This is an experiment to test the feasibility of Dilithium in Nostr.\n\n'
                    'Please note that the ID is still generated the conventional way.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Configuration Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configuration',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),

                      // Level Selector
                      DropdownButtonFormField<int>(
                        initialValue: _level,
                        items: [2, 3, 5].map((level) {
                          return DropdownMenuItem(
                            value: level,
                            child: Text('Level $level'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _level = value!);
                        },
                      ),

                      const SizedBox(height: 8),

                      // Event Count Slider (steps of 1000)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Events to Process: $_eventCount'),
                          if (_eventCount < 5000)
                            TextButton(
                              onPressed: () {
                                setState(() => _eventCount += 1000);
                              },
                              child: const Text('+1000'),
                            ),
                        ],
                      ),
                      Slider(
                        value: (_eventCount / 1000).toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: '$_eventCount events',
                        onChanged: (value) {
                          setState(() => _eventCount = (value * 1000).toInt());
                        },
                      ),

                      // Message Input (optional)
                      TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          labelText:
                              'Message content (leave empty for default)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),

                      const SizedBox(height: 16),

                      // Generate Button
                      ElevatedButton.icon(
                        onPressed: _generateEvents,
                        icon: const Icon(Icons.arrow_downward),
                        label: const Text('Generate Events'),
                      ),

                      if (_hasSignature) const SizedBox(height: 12),

                      // Verify Button
                      ElevatedButton.icon(
                        onPressed: _verifyEvents,
                        icon: const Icon(Icons.arrow_upward),
                        label: const Text('Verify Events'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Performance Results Section
              if (_signTimeMs != null || _verifyTimeMs != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Performance Results',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Divider(),
                        if (_signTimeMs != null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Sign Time:'),
                                Text(
                                  '${_signTimeMs!.toStringAsFixed(2)} ms',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_verifyTimeMs != null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Verify Time:'),
                                Text(
                                  '${_verifyTimeMs!.toStringAsFixed(2)} ms',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_failedVerifications != null &&
                            _failedVerifications! > 0) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              'Failed Verifications: $_failedVerifications',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Results Section
              if (_lastEventJson != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last Event JSON',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Divider(),
                        SelectableText(
                          _lastEventJson!,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
