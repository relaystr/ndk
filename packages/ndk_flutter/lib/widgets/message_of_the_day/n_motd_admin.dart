import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/l10n/app_localizations.dart';
import 'package:ndk_flutter/main/ndk_flutter.dart';

import 'motd_data.dart';

/// Admin interface to create, update and delete the Message of the Day event.
///
/// The event is authored by [authorPubkey] using the currently logged-in
/// signer, so the logged-in account must be the author. [appVersion] is used
/// to pre-fill the version field.
class NMotdAdmin extends StatefulWidget {
  /// The Flutter wrapper holding the NDK instance.
  final NdkFlutter ndkFlutter;

  /// Public key of the author that publishes the message.
  final String authorPubkey;

  /// `d` tag value identifying the message; defaults to "motd".
  final String dTagValue;

  /// Current app version, pre-filled into the version field.
  final String? appVersion;

  const NMotdAdmin({
    super.key,
    required this.ndkFlutter,
    required this.authorPubkey,
    this.dTagValue = MotdData.kDefaultDTag,
    this.appVersion,
  });

  @override
  State<NMotdAdmin> createState() => _NMotdAdminState();
}

enum _AdminStatus { idle, loading, saving, deleting, error }

class _NMotdAdminState extends State<NMotdAdmin> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _versionController = TextEditingController();

  _AdminStatus _status = _AdminStatus.idle;
  String? _error;
  MotdData? _existing;

  @override
  void initState() {
    super.initState();
    _versionController.text = widget.appVersion ?? '';
    _loadExisting();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _urlController.dispose();
    _versionController.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    setState(() => _status = _AdminStatus.loading);
    try {
      final response = widget.ndkFlutter.ndk.requests.query(
        filter: Filter(
          authors: [widget.authorPubkey],
          kinds: [MotdData.kKind],
          dTags: [widget.dTagValue],
          limit: 1,
        ),
      );
      final events = await response.future;

      Nip01Event? latest;
      for (final event in events) {
        if (event.kind == MotdData.kKind && event.getDtag() == widget.dTagValue) {
          if (latest == null || event.createdAt > latest.createdAt) {
            latest = event;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _existing = latest == null ? null : MotdData.fromEvent(latest);
        _messageController.text = _existing?.message ?? '';
        _urlController.text = _existing?.url ?? '';
        if (_existing?.version != null && _versionController.text.isEmpty) {
          _versionController.text = _existing!.version!;
        }
        _status = _AdminStatus.idle;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _status = _AdminStatus.error;
      });
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final signer = widget.ndkFlutter.ndk.accounts.getLoggedAccount()?.signer;
    if (signer == null) {
      setState(
        () => _error =
            l10n?.motdAdminLoggedInRequired ?? 'Log in to manage the message of the day.',
      );
      return;
    }
    if (signer.getPublicKey() != widget.authorPubkey) {
      setState(
        () => _error =
            l10n?.motdAdminMustBeAuthor ?? 'You are not the message author.',
      );
      return;
    }

    final url = _urlController.text.trim();
    final version = _versionController.text.trim();

    setState(() {
      _status = _AdminStatus.saving;
      _error = null;
    });

    try {
      final event = Nip01Event(
        pubKey: widget.authorPubkey,
        kind: MotdData.kKind,
        tags: [
          ["d", widget.dTagValue],
          if (url.isNotEmpty) ["url", url],
          if (version.isNotEmpty) ["version", version],
        ],
        content: message,
      );
      final result = widget.ndkFlutter.ndk.broadcast.broadcast(
        nostrEvent: event,
        customSigner: signer,
      );
      await result.broadcastDoneFuture;

      // Local copy so a stale QL/CACHE entry does not mask the update.
      if (!mounted) return;
      setState(() {
        _existing = MotdData(
          eventId: event.id,
          pubKey: event.pubKey,
          message: message,
          url: url.isEmpty ? null : url,
          version: version.isEmpty ? null : version,
          createdAt: event.createdAt,
        );
        _status = _AdminStatus.idle;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = l10n?.error(e.toString()) ?? 'Error: $e';
        _status = _AdminStatus.error;
      });
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final signer = widget.ndkFlutter.ndk.accounts.getLoggedAccount()?.signer;
    if (signer == null) {
      setState(
        () => _error =
            l10n?.motdAdminLoggedInRequired ?? 'Log in to manage the message of the day.',
      );
      return;
    }
    if (signer.getPublicKey() != widget.authorPubkey) {
      setState(
        () => _error =
            l10n?.motdAdminMustBeAuthor ?? 'You are not the message author.',
      );
      return;
    }
    final existing = _existing;
    if (existing == null) return;

    setState(() {
      _status = _AdminStatus.deleting;
      _error = null;
    });

    try {
      final event = Nip01Event(
        id: existing.eventId,
        pubKey: existing.pubKey,
        kind: MotdData.kKind,
        tags: [
          ["d", widget.dTagValue],
          if (existing.url != null) ["url", existing.url!],
          if (existing.version != null) ["version", existing.version!],
        ],
        content: existing.message,
        createdAt: existing.createdAt,
      );
      final result = widget.ndkFlutter.ndk.broadcast.broadcastDeletion(
        eventAndAllVersions: event,
        customSigner: signer,
      );
      await result.broadcastDoneFuture;

      if (!mounted) return;
      setState(() {
        _existing = null;
        _messageController.clear();
        _urlController.clear();
        _versionController.text = widget.appVersion ?? '';
        _status = _AdminStatus.idle;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = l10n?.error(e.toString()) ?? 'Error: $e';
        _status = _AdminStatus.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final busy = _status == _AdminStatus.saving ||
        _status == _AdminStatus.deleting;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n?.motdAdminTitle ?? 'Message of the Day',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (_status == _AdminStatus.loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              TextField(
                controller: _messageController,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: l10n?.motdAdminMessageLabel ?? 'Message',
                  hintText: l10n?.motdAdminMessageHint ??
                      'Enter the message to display',
                ),
                enabled: !busy,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: l10n?.motdAdminUrlLabel ?? 'Link (optional)',
                  hintText: 'https://…',
                ),
                enabled: !busy,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _versionController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText:
                      l10n?.motdAdminVersionLabel ?? 'Minimum version (optional)',
                  hintText: '1.2.0',
                ),
                enabled: !busy,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: busy ? null : _save,
                      child: Text(
                        _existing == null
                            ? (l10n?.motdAdminCreate ?? 'Publish')
                            : (l10n?.motdAdminUpdate ?? 'Update'),
                      ),
                    ),
                  ),
                  if (_existing != null) ...[
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: busy ? null : _delete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      child: Text(l10n?.delete ?? 'Delete'),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}