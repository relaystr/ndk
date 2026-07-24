import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ndk/entities.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

import '../../l10n/app_localizations.dart';

/// Standalone warning banner shown when at least one cashu wallet exists and
/// the user has not yet confirmed they backed up the cashu recovery (seed)
/// phrase. The seed is global (not per wallet), so place this once in the
/// wallets screen rather than inside each wallet card.
///
/// Tapping it reveals the words and an explicit confirmation; once confirmed
/// the banner disappears for good.
///
/// The seed phrase controls all cashu funds — losing it without a backup means
/// the funds cannot be recovered.
class NCashuSeedBackupWarning extends StatefulWidget {
  final NdkFlutter ndkFlutter;

  /// Store used to read the backed-up flag. Defaults to [CashuSeedStore] with
  /// the default key — pass a custom one if the app configured a custom key.
  final CashuSeedStore seedStore;

  const NCashuSeedBackupWarning({
    super.key,
    required this.ndkFlutter,
    this.seedStore = const CashuSeedStore(),
  });

  @override
  State<NCashuSeedBackupWarning> createState() =>
      _NCashuSeedBackupWarningState();
}

class _NCashuSeedBackupWarningState extends State<NCashuSeedBackupWarning> {
  late final CashuSeedStore _seedStore = widget.seedStore;

  /// null = loading, true = backed up (hide), false = needs backup (show).
  bool? _backedUp;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final backedUp = await _seedStore.isBackedUp();
    if (mounted) setState(() => _backedUp = backedUp);
  }

  /// Reads the recovery words from the running NDK instance. Returns an empty
  /// list when no seed is configured.
  List<String> _seedWords() {
    try {
      final mnemonic = widget.ndkFlutter.ndk.cashu
          .getCashuSeed()
          .getSeedPhrase();
      return mnemonic.sentence.trim().split(RegExp(r'\s+'));
    } catch (_) {
      return const [];
    }
  }

  Future<void> _showBackupDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final words = _seedWords();
    if (words.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        bool checked = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.backupSeedTitle),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.backupSeedInstructions),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (int i = 0; i < words.length; i++)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${i + 1}. ${words[i]}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.copy, size: 18),
                        label: Text(l10n.copy),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: words.join(' ')),
                          );
                          if (!dialogContext.mounted) return;
                          ScaffoldMessenger.of(
                            dialogContext,
                          ).showSnackBar(SnackBar(content: Text(l10n.copied)));
                        },
                      ),
                    ),
                    const Divider(),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: checked,
                      onChanged: (v) =>
                          setDialogState(() => checked = v ?? false),
                      title: Text(l10n.backupSeedConfirm),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: checked
                      ? () => Navigator.of(dialogContext).pop(true)
                      : null,
                  child: Text(l10n.backupSeedDone),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true) {
      await _seedStore.setBackedUp(true);
      if (mounted) setState(() => _backedUp = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hide while loading, once backed up, or when no seed is configured.
    if (_backedUp != false) return const SizedBox.shrink();
    if (_seedWords().isEmpty) return const SizedBox.shrink();

    // Only warn when at least one cashu wallet actually exists.
    return StreamBuilder<List<Wallet>>(
      stream: widget.ndkFlutter.ndk.wallets.walletsStream,
      builder: (context, snapshot) {
        final hasCashuWallet =
            snapshot.data?.any((w) => w is CashuWallet) ?? false;
        if (!hasCashuWallet) return const SizedBox.shrink();
        return _buildBanner(context);
      },
    );
  }

  Widget _buildBanner(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showBackupDialog,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.amber.withAlpha(40),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.withAlpha(160)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.amber,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.backupSeedWarning,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: scheme.onSurface.withAlpha(140),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
