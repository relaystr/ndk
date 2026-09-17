import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ndk/entities.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

import '../../l10n/app_localizations.dart';
import 'cashu_dialog_helpers.dart';

/// Prompts the user for a mint URL and runs [Cashu.restore] with live progress
/// shown in a dialog. Returns the final [CashuRestoreResult], or null when
/// cancelled.
///
/// [defaultMintUrl] pre-fills the mint URL field.
Future<CashuRestoreResult?> showCashuRestoreDialog(
  BuildContext context,
  NdkFlutter ndkFlutter, {
  String defaultMintUrl = '',
}) async {
  return showDialog<CashuRestoreResult>(
    context: context,
    builder: (_) => _CashuRestoreInputDialog(
      ndkFlutter: ndkFlutter,
      defaultMintUrl: defaultMintUrl,
    ),
  );
}

class _CashuRestoreInputDialog extends StatefulWidget {
  final NdkFlutter ndkFlutter;
  final String defaultMintUrl;

  const _CashuRestoreInputDialog({
    required this.ndkFlutter,
    required this.defaultMintUrl,
  });

  @override
  State<_CashuRestoreInputDialog> createState() =>
      _CashuRestoreInputDialogState();
}

class _CashuRestoreInputDialogState extends State<_CashuRestoreInputDialog> {
  late final TextEditingController _mintUrlController = TextEditingController(
    text: widget.defaultMintUrl,
  );
  bool _starting = false;

  @override
  void dispose() {
    _mintUrlController.dispose();
    super.dispose();
  }

  Future<void> _pasteMintUrl() async {
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboard?.text == null || !mounted) return;
    _mintUrlController.text = clipboard!.text!.trim();
  }

  Future<void> _startRestore() async {
    final l10n = AppLocalizations.of(context)!;
    final mintUrl = _mintUrlController.text.trim();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (mintUrl.isEmpty) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseEnterMintUrl),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _starting = true);
    try {
      final result = await showDialog<CashuRestoreResult>(
        context: context,
        barrierDismissible: false,
        builder: (_) => CashuRestoreProgressDialog(
          ndkFlutter: widget.ndkFlutter,
          mintUrl: mintUrl,
        ),
      );

      if (result != null) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.restoredFromMint(result.totalProofsRestored)),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (mounted) Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _starting = false);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('${l10n.restoreFailed}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(l10n.cashuRestoreFundsTitle)),
          IconButton(
            onPressed: _starting ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.cashuRestoreDescription),
          const SizedBox(height: 16),
          TextField(
            controller: _mintUrlController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: l10n.mintUrl,
              hintText: l10n.mintUrlHint,
              suffixIcon: IconButton(
                onPressed: _pasteMintUrl,
                icon: const Icon(Icons.paste),
                tooltip: l10n.paste,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _starting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: _starting ? null : _startRestore,
          child: _starting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.startRestore),
        ),
      ],
    );
  }
}

/// Live-progress dialog for [Cashu.restore]: scans the mint for proofs derived
/// from this wallet's seed and pops with the final [CashuRestoreResult] once
/// the scan completes.
class CashuRestoreProgressDialog extends StatefulWidget {
  final NdkFlutter ndkFlutter;
  final String mintUrl;

  const CashuRestoreProgressDialog({
    super.key,
    required this.ndkFlutter,
    required this.mintUrl,
  });

  @override
  State<CashuRestoreProgressDialog> createState() =>
      _CashuRestoreProgressDialogState();
}

class _CashuRestoreProgressDialogState
    extends State<CashuRestoreProgressDialog> {
  late final Stream<CashuRestoreResult> _progress = widget.ndkFlutter.ndk.cashu
      .restore(mintUrl: widget.mintUrl);
  CashuRestoreResult? _result;
  bool _failed = false;
  bool _closed = false;

  /// Pops the dialog (once) returning [result].
  void _finish(CashuRestoreResult? result) {
    if (_closed) return;
    _closed = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.cashuRestoreFundsTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: StreamBuilder<CashuRestoreResult>(
          stream: _progress,
          builder: (context, snapshot) {
            final result = snapshot.data ?? _result;
            // keyset-level results are cumulative, so keep the last one around
            // for the summary even after the stream completed
            if (result != null) _result = result;
            final bool errored = snapshot.hasError;
            if (errored) _failed = true;
            final bool done =
                !errored && snapshot.connectionState == ConnectionState.done;

            if (done) _finish(result);

            final String? errorMessage = errored
                ? cleanCashuErrorMessage(snapshot.error.toString())
                : null;
            final int totalProofs = result?.totalProofsRestored ?? 0;
            final int keysetCount = result?.keysetResults.length ?? 0;
            final bool hasData = snapshot.hasData || result != null;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CashuStageLine(
                  done: hasData,
                  active: !done && !errored && !hasData,
                  title: l10n.cashuRestoreStageFetchingKeysets,
                ),
                CashuStageLine(
                  done: done,
                  active: !done && !errored && hasData,
                  title: l10n.cashuRestoreStageScanning,
                  subtitle: l10n.cashuRestoreScanProgress(
                    keysetCount,
                    totalProofs,
                  ),
                ),
                CashuStageLine(
                  done: done,
                  active: false,
                  title: l10n.cashuRestoreStageCompleted,
                  subtitle: done
                      ? l10n.restoredFromMint(totalProofs)
                      : l10n.cashuRestoreAlsoRestoresQuotes,
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  CashuErrorPanel(
                    title: l10n.restoreFailed,
                    message: errorMessage,
                  ),
                ],
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _finish(_failed ? null : _result),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
