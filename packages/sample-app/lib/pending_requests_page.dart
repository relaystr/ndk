import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';

import 'main.dart';

class PendingRequestsPage extends StatefulWidget {
  const PendingRequestsPage({super.key});

  @override
  State<PendingRequestsPage> createState() => _PendingRequestsPageState();
}

class _PendingRequestsPageState extends State<PendingRequestsPage> {
  String? _lastResult;
  String? _lastError;
  String? _ciphertext;

  void _showResult(String result) {
    setState(() {
      _lastResult = result;
      _lastError = null;
    });
  }

  void _showError(String error) {
    setState(() {
      _lastResult = null;
      _lastError = error;
    });
  }

  Future<void> _signEvent(EventSigner signer) async {
    try {
      final event = Nip01Event(
        pubKey: signer.getPublicKey(),
        kind: 1,
        tags: [],
        content: 'Test event from pending requests demo - ${DateTime.now()}',
      );
      final signed = await signer.sign(event);
      _showResult('Signed! ID: ${signed.id.substring(0, 16)}...');
    } catch (e) {
      _showError('Sign failed: $e');
    }
  }

  Future<void> _encryptNip44(EventSigner signer) async {
    try {
      final pubkey = signer.getPublicKey();
      final result = await signer.encryptNip44(
        plaintext: 'Hello from pending requests demo!',
        recipientPubKey: pubkey,
      );
      _ciphertext = result;
      _showResult('Encrypted: ${result?.substring(0, 30)}...');
    } catch (e) {
      _showError('Encrypt failed: $e');
    }
  }

  Future<void> _decryptNip44(EventSigner signer) async {
    if (_ciphertext == null) {
      _showError('Encrypt first to get ciphertext');
      return;
    }
    try {
      final pubkey = signer.getPublicKey();
      final result = await signer.decryptNip44(
        ciphertext: _ciphertext!,
        senderPubKey: pubkey,
      );
      _showResult('Decrypted: $result');
    } catch (e) {
      _showError('Decrypt failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedInAccount = ndk.accounts.getLoggedAccount();
    final signer = loggedInAccount?.signer;

    if (signer == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Please log in via the "Accounts" tab to see pending requests.\n\n'
            'This demo works best with external signers (Bunker, NIP-07, Amber) '
            'that require user approval.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pending Signer Requests',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Requests waiting for approval from your signer.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trigger Requests',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _signEvent(signer),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Sign Event'),
                      ),
                      FilledButton.icon(
                        onPressed: () => _encryptNip44(signer),
                        icon: const Icon(Icons.lock, size: 18),
                        label: const Text('Encrypt'),
                      ),
                      FilledButton.icon(
                        onPressed: () => _decryptNip44(signer),
                        icon: const Icon(Icons.lock_open, size: 18),
                        label: const Text('Decrypt'),
                      ),
                    ],
                  ),
                  if (_lastResult != null || _lastError != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _lastError != null
                            ? Colors.red.withValues(alpha: 0.1)
                            : Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _lastResult ?? _lastError ?? '',
                        style: TextStyle(
                          color: _lastError != null ? Colors.red : Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Pending requests list
          Expanded(
            child: StreamBuilder<List<PendingSignerRequest>>(
              stream: signer.pendingRequestsStream,
              initialData: signer.pendingRequests,
              builder: (context, snapshot) {
                final requests = snapshot.data ?? [];

                if (requests.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.green,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No pending requests',
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Use the buttons above to trigger requests.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return _PendingRequestCard(
                      request: request,
                      onCancel: () {
                        final cancelled = signer.cancelRequest(request.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              cancelled
                                  ? 'Request cancelled'
                                  : 'Failed to cancel request',
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingRequestCard extends StatelessWidget {
  final PendingSignerRequest request;
  final VoidCallback onCancel;

  const _PendingRequestCard({
    required this.request,
    required this.onCancel,
  });

  IconData _getIconForMethod(SignerMethod method) {
    switch (method) {
      case SignerMethod.signEvent:
        return Icons.edit;
      case SignerMethod.getPublicKey:
        return Icons.key;
      case SignerMethod.nip04Encrypt:
      case SignerMethod.nip44Encrypt:
        return Icons.lock;
      case SignerMethod.nip04Decrypt:
      case SignerMethod.nip44Decrypt:
        return Icons.lock_open;
      case SignerMethod.ping:
        return Icons.network_ping;
      case SignerMethod.connect:
        return Icons.link;
    }
  }

  Color _getColorForMethod(SignerMethod method) {
    switch (method) {
      case SignerMethod.signEvent:
        return Colors.blue;
      case SignerMethod.getPublicKey:
        return Colors.purple;
      case SignerMethod.nip04Encrypt:
      case SignerMethod.nip44Encrypt:
        return Colors.green;
      case SignerMethod.nip04Decrypt:
      case SignerMethod.nip44Decrypt:
        return Colors.orange;
      case SignerMethod.ping:
        return Colors.grey;
      case SignerMethod.connect:
        return Colors.teal;
    }
  }

  String _getMethodDisplayName(SignerMethod method) {
    switch (method) {
      case SignerMethod.signEvent:
        return 'Sign Event';
      case SignerMethod.getPublicKey:
        return 'Get Public Key';
      case SignerMethod.nip04Encrypt:
        return 'NIP-04 Encrypt';
      case SignerMethod.nip04Decrypt:
        return 'NIP-04 Decrypt';
      case SignerMethod.nip44Encrypt:
        return 'NIP-44 Encrypt';
      case SignerMethod.nip44Decrypt:
        return 'NIP-44 Decrypt';
      case SignerMethod.ping:
        return 'Ping';
      case SignerMethod.connect:
        return 'Connect';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s ago';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m ago';
    } else {
      return '${duration.inHours}h ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final method = request.method;
    final duration = DateTime.now().difference(request.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      _getColorForMethod(method).withValues(alpha: 0.2),
                  child: Icon(
                    _getIconForMethod(method),
                    color: _getColorForMethod(method),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getMethodDisplayName(method),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text('Cancel'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
            if (request.event != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Event Kind: ${request.event!.kind}',
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Content: ${_truncate(request.event!.content, 100)}',
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ],
            if (request.content != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (request.counterpartyPubkey != null)
                      Text(
                        'Counterparty: ${_truncate(request.counterpartyPubkey!, 20)}...',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      request.plaintext != null
                          ? 'Plaintext: ${_truncate(request.content!, 100)}'
                          : 'Ciphertext: ${_truncate(request.content!, 50)}...',
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'ID: ${request.id}',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
