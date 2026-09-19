import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ndk/entities.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

import '../../l10n/app_localizations.dart';

/// Shows a dialog to set or override the global Cashu seed phrase.
///
/// The seed phrase is **global**: it is used to derive keys for *every* Cashu
/// wallet, so replacing it is a destructive action. The dialog therefore shows
/// an explicit warning and requires the user to confirm the change before it
/// is applied.
///
/// When confirmed, the phrase is validated as a BIP39 mnemonic, applied to the
/// running NDK instance via [Cashu.setCashuSeedPhrase] and persisted to secure
/// storage through [CashuSeedStore] so it survives restarts.
///
/// Returns `true` when the seed phrase was updated, `false` when cancelled,
/// and `null` when dismissed without an explicit choice.
Future<bool?> showCashuSeedPhraseDialog(
  BuildContext context,
  NdkFlutter ndkFlutter, {
  CashuSeedStore seedStore = const CashuSeedStore(),
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) =>
        _CashuSeedPhraseDialog(ndkFlutter: ndkFlutter, seedStore: seedStore),
  );
}

class _CashuSeedPhraseDialog extends StatefulWidget {
  final NdkFlutter ndkFlutter;
  final CashuSeedStore seedStore;

  const _CashuSeedPhraseDialog({
    required this.ndkFlutter,
    required this.seedStore,
  });

  @override
  State<_CashuSeedPhraseDialog> createState() => _CashuSeedPhraseDialogState();
}

class _CashuSeedPhraseDialogState extends State<_CashuSeedPhraseDialog> {
  final TextEditingController _seedController = TextEditingController();
  bool _confirmChecked = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _seedController.dispose();
    super.dispose();
  }

  Future<void> _pasteSeedPhrase() async {
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboard?.text == null || !mounted) return;
    setState(() {
      _seedController.text = clipboard!.text!.trim();
      _error = null;
    });
  }

  /// Returns a user-facing error message when [phrase] is not a valid BIP39
  /// mnemonic, or null when it can be used as the cashu seed phrase.
  String? _validateSeedPhrase(String phrase, AppLocalizations l10n) {
    final words = phrase.trim().split(RegExp(r'\s+'));
    // BIP39 sentences are 12, 15, 18, 21 or 24 words long.
    if (!{12, 15, 18, 21, 24}.contains(words.length)) {
      return l10n.cashuSeedPhraseInvalid;
    }
    try {
      Mnemonic.fromSentence(words.join(' '), Language.english);
    } on MnemonicException {
      return l10n.cashuSeedPhraseInvalid;
    }
    return null;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final phrase = _seedController.text.trim();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final validationError = _validateSeedPhrase(phrase, l10n);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // Apply on the running instance, then persist for future launches.
      widget.ndkFlutter.ndk.cashu.setCashuSeedPhrase(
        CashuUserSeedphrase(seedPhrase: phrase),
      );
      await widget.seedStore.write(phrase);
      // The seed changed, so the previous backup confirmation no longer
      // applies: prompt the user to back up the new phrase again.
      await widget.seedStore.setBackedUp(false);

      if (!mounted) return;
      Navigator.of(context).pop(true);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(l10n.cashuSeedPhraseUpdated),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '${l10n.cashuSeedPhraseUpdateFailed}: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final bool canSave = !_saving && _confirmChecked;

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(l10n.cashuSeedPhraseTitle)),
          IconButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.errorContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: scheme.error),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.cashuSeedPhraseWarning,
                      style: TextStyle(
                        color: scheme.onErrorContainer,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(l10n.cashuSeedPhraseInstructions),
            const SizedBox(height: 12),
            TextField(
              controller: _seedController,
              enabled: !_saving,
              maxLines: 4,
              style: const TextStyle(fontFamily: 'monospace'),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.cashuSeedPhraseLabel,
                hintText: l10n.cashuSeedPhraseHint,
                suffixIcon: IconButton(
                  onPressed: _saving ? null : _pasteSeedPhrase,
                  icon: const Icon(Icons.paste),
                  tooltip: l10n.paste,
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: scheme.error, fontSize: 13),
              ),
            ],
            const SizedBox(height: 4),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _confirmChecked,
              onChanged: _saving
                  ? null
                  : (v) => setState(() => _confirmChecked = v ?? false),
              title: Text(l10n.cashuSeedPhraseConfirmChange),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: canSave ? _save : null,
          child: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.cashuSeedPhraseOption),
        ),
      ],
    );
  }
}
