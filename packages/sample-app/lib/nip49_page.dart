import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';

class Nip49Page extends StatefulWidget {
  const Nip49Page({super.key});

  @override
  State<Nip49Page> createState() => _Nip49PageState();
}

class _Nip49PageState extends State<Nip49Page> {
  final _privateKeyController = TextEditingController();
  final _encryptPasswordController = TextEditingController();
  final _ncryptsecController = TextEditingController();
  final _decryptPasswordController = TextEditingController();

  int _logN = Nip49.defaultLogN;

  bool _encrypting = false;
  String? _ncryptsec;
  Duration? _encryptDuration;
  String? _encryptError;

  bool _decrypting = false;
  String? _decryptedPrivateKey;
  Duration? _decryptDuration;
  String? _decryptError;

  @override
  void dispose() {
    _privateKeyController.dispose();
    _encryptPasswordController.dispose();
    _ncryptsecController.dispose();
    _decryptPasswordController.dispose();
    super.dispose();
  }

  void _generatePrivateKey() {
    _privateKeyController.text =
        Nip19.encodePrivateKey(Bip340.generatePrivateKey().privateKey!);
  }

  Future<void> _encrypt() async {
    setState(() {
      _encrypting = true;
      _ncryptsec = null;
      _encryptError = null;
    });
    final stopwatch = Stopwatch()..start();
    try {
      final input = _privateKeyController.text.trim();
      final ncryptsec = await Nip49.encrypt(
        Nip19.isPrivateKey(input) ? Nip19.decode(input) : input,
        _encryptPasswordController.text,
        logN: _logN,
      );
      if (!mounted) return;
      _ncryptsec = ncryptsec;
      _encryptDuration = stopwatch.elapsed;
      _ncryptsecController.text = ncryptsec;
    } catch (e) {
      _encryptError = '$e';
    } finally {
      if (mounted) setState(() => _encrypting = false);
    }
  }

  Future<void> _decrypt() async {
    setState(() {
      _decrypting = true;
      _decryptedPrivateKey = null;
      _decryptError = null;
    });
    final stopwatch = Stopwatch()..start();
    try {
      _decryptedPrivateKey = await Nip49.decrypt(
        _ncryptsecController.text.trim(),
        _decryptPasswordController.text,
      );
      _decryptDuration = stopwatch.elapsed;
    } catch (e) {
      _decryptError = '$e';
    } finally {
      if (mounted) setState(() => _decrypting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NIP-49 Private Key Encryption')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: 'Encrypt',
            children: [
              TextField(
                controller: _privateKeyController,
                decoration: InputDecoration(
                  labelText: 'Private key (nsec or hex)',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: 'Generate',
                    icon: const Icon(Icons.casino_outlined),
                    onPressed: _generatePrivateKey,
                  ),
                ),
              ),
              TextField(
                controller: _encryptPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              DropdownButtonFormField<int>(
                initialValue: _logN,
                decoration: const InputDecoration(
                  labelText: 'scrypt log N',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 16, child: Text('16 (64 MiB)')),
                  DropdownMenuItem(value: 18, child: Text('18 (256 MiB)')),
                  DropdownMenuItem(value: 20, child: Text('20 (1 GiB)')),
                ],
                onChanged: (value) => setState(() => _logN = value!),
              ),
              _ActionButton(
                label: 'Encrypt',
                busy: _encrypting,
                onPressed: _encrypt,
              ),
              if (_ncryptsec != null)
                _Result(
                  value: _ncryptsec!,
                  caption:
                      'Encrypted in ${_encryptDuration!.inMilliseconds} ms',
                ),
              if (_encryptError != null) _Error(_encryptError!),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Decrypt',
            children: [
              TextField(
                controller: _ncryptsecController,
                decoration: const InputDecoration(
                  labelText: 'ncryptsec',
                  border: OutlineInputBorder(),
                ),
              ),
              TextField(
                controller: _decryptPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              _ActionButton(
                label: 'Decrypt',
                busy: _decrypting,
                onPressed: _decrypt,
              ),
              if (_decryptedPrivateKey != null)
                _Result(
                  value: Nip19.encodePrivateKey(_decryptedPrivateKey!),
                  caption:
                      'Decrypted in ${_decryptDuration!.inMilliseconds} ms',
                ),
              if (_decryptError != null) _Error(_decryptError!),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            for (final child in children) ...[
              const SizedBox(height: 12),
              child,
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}

class _Result extends StatelessWidget {
  final String value;
  final String caption;

  const _Result({required this.value, required this.caption});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          value,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(caption, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _Error extends StatelessWidget {
  final String message;

  const _Error(this.message);

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );
  }
}
