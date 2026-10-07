// ignore_for_file: experimental_member_use
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';

import 'main.dart';

class Nip77Page extends StatefulWidget {
  const Nip77Page({super.key});

  @override
  State<Nip77Page> createState() => _Nip77PageState();
}

class _Nip77PageState extends State<Nip77Page> {
  final _relayController = TextEditingController(text: 'wss://relay.ditto.pub');
  final _authorController = TextEditingController(
    text: ndk.accounts.getPublicKey() ?? '',
  );
  final _kindsController = TextEditingController();

  Nip77Response? _response;
  final List<StreamSubscription<String>> _subscriptions = [];
  int _liveNeed = 0;
  int _liveHave = 0;
  Nip77Result? _result;
  String? _reconciledRelay;
  String? _error;
  bool _fetching = false;
  bool _pushing = false;
  String? _transferStatus;

  bool get _reconciling => _response != null;
  bool get _busy => _reconciling || _fetching || _pushing;

  @override
  void dispose() {
    _stopListening();
    final response = _response;
    if (response != null) ndk.nip77.close(response.subscriptionId);
    _relayController.dispose();
    _authorController.dispose();
    _kindsController.dispose();
    super.dispose();
  }

  void _stopListening() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  Filter _buildFilter() {
    final author = _authorController.text.trim();
    String pubkey;
    try {
      pubkey = author.startsWith('npub') ? Nip19.decode(author) : author;
    } catch (_) {
      pubkey = '';
    }
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(pubkey)) {
      throw const FormatException('Author must be an npub or a hex pubkey');
    }

    final kinds = <int>[];
    for (final part in _kindsController.text.split(',')) {
      if (part.trim().isEmpty) continue;
      final kind = int.tryParse(part.trim());
      if (kind == null) {
        throw const FormatException('Kinds must be comma-separated numbers');
      }
      kinds.add(kind);
    }

    return Filter(authors: [pubkey], kinds: kinds.isEmpty ? null : kinds);
  }

  Future<void> _reconcile() async {
    final Filter filter;
    try {
      filter = _buildFilter();
    } on FormatException catch (e) {
      setState(() => _error = e.message);
      return;
    }
    final relayUrl = _relayController.text.trim();

    setState(() {
      _error = null;
      _result = null;
      _transferStatus = null;
      _liveNeed = 0;
      _liveHave = 0;
    });

    try {
      final response = ndk.nip77.reconcile(relayUrl: relayUrl, filter: filter);
      setState(() => _response = response);
      _subscriptions.addAll([
        response.needStream.listen((_) => setState(() => _liveNeed++)),
        response.haveStream.listen((_) => setState(() => _liveHave++)),
      ]);
      final result = await response.future;
      if (!mounted) return;
      setState(() {
        _result = result;
        _reconciledRelay = relayUrl;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _describe(e));
    } finally {
      _stopListening();
      if (mounted) setState(() => _response = null);
    }
  }

  String _describe(Object error) => switch (error) {
        Nip77NotSupportedException(:final relayUrl) =>
          '$relayUrl does not support NIP-77',
        Nip77TimeoutException(:final timeout) =>
          'Reconciliation timed out after ${timeout.inSeconds}s',
        _ => '$error',
      };

  Future<void> _fetchMissing() async {
    final needIds = _result!.needIds;
    final relayUrl = _reconciledRelay!;
    setState(() {
      _fetching = true;
      _transferStatus = null;
    });

    String status;
    try {
      var fetched = 0;
      for (final ids in _chunks(needIds, 250)) {
        final events = await ndk.requests
            .query(filter: Filter(ids: ids), explicitRelays: [relayUrl])
            .future;
        fetched += events.length;
      }
      status = 'Fetched $fetched of ${needIds.length} events into the cache';
    } catch (e) {
      status = 'Fetch failed: $e';
    }

    if (!mounted) return;
    setState(() {
      _fetching = false;
      _transferStatus = status;
    });
  }

  Future<void> _pushMissing() async {
    final haveIds = _result!.haveIds;
    final relayUrl = _reconciledRelay!;
    setState(() {
      _pushing = true;
      _transferStatus = null;
    });

    String status;
    try {
      final events = await ndk.config.cache.loadEvents(ids: haveIds);
      var accepted = 0;
      for (final batch in _chunks(events, 50)) {
        final responses = await Future.wait(
          batch.map(
            (event) => ndk.broadcast
                .broadcast(
                  nostrEvent: event,
                  specificRelays: [relayUrl],
                  saveToCache: false,
                  retryDelivery: false,
                )
                .broadcastDoneFuture,
          ),
        );
        accepted += responses
            .where((relays) => relays.any((r) => r.broadcastSuccessful))
            .length;
      }
      status = 'The relay accepted $accepted of ${events.length} events';
    } catch (e) {
      status = 'Push failed: $e';
    }

    if (!mounted) return;
    setState(() {
      _pushing = false;
      _transferStatus = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = _result;

    return Scaffold(
      appBar: AppBar(title: const Text('NIP-77 Sync')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Negentropy compares the events in your cache with the ones on a '
            'relay and lists what each side is missing, without downloading '
            'anything.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _relayController,
            enabled: !_busy,
            decoration: const InputDecoration(
              labelText: 'Relay',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _authorController,
            enabled: !_busy,
            decoration: const InputDecoration(
              labelText: 'Author',
              hintText: 'npub or hex pubkey',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _kindsController,
            enabled: !_busy,
            decoration: const InputDecoration(
              labelText: 'Kinds',
              hintText: '1, 7 (empty for all kinds)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _reconcile,
            icon: _reconciling
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            label: Text(_reconciling ? 'Reconciling...' : 'Reconcile'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          if (_reconciling || result != null) ...[
            const SizedBox(height: 16),
            _DiffCard(
              icon: Icons.download,
              count: result?.needIds.length ?? _liveNeed,
              title: 'missing locally',
              subtitle: 'On the relay, not in the cache',
              actionLabel: 'Fetch',
              busy: _fetching,
              onAction: result != null && result.needIds.isNotEmpty && !_busy
                  ? _fetchMissing
                  : null,
            ),
            const SizedBox(height: 8),
            _DiffCard(
              icon: Icons.upload,
              count: result?.haveIds.length ?? _liveHave,
              title: 'missing on the relay',
              subtitle: 'In the cache, not on the relay',
              actionLabel: 'Push',
              busy: _pushing,
              onAction: result != null && result.haveIds.isNotEmpty && !_busy
                  ? _pushMissing
                  : null,
            ),
          ],
          if (_transferStatus != null) ...[
            const SizedBox(height: 16),
            Text(_transferStatus!),
          ],
        ],
      ),
    );
  }
}

class _DiffCard extends StatelessWidget {
  final IconData icon;
  final int count;
  final String title;
  final String subtitle;
  final String actionLabel;
  final bool busy;
  final VoidCallback? onAction;

  const _DiffCard({
    required this.icon,
    required this.count,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.busy,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text('$count $title'),
        subtitle: Text(subtitle),
        trailing: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TextButton(onPressed: onAction, child: Text(actionLabel)),
      ),
    );
  }
}

Iterable<List<T>> _chunks<T>(List<T> items, int size) sync* {
  for (var i = 0; i < items.length; i += size) {
    yield items.sublist(i, min(i + size, items.length));
  }
}
