import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ndk/entities.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

import '../../l10n/app_localizations.dart';
import 'cashu_dialog_helpers.dart';

/// Prompts the user for a mint URL and a quote ID, then runs
/// [Cashu.recoverAndCompleteQuote] with live progress shown in a
/// dialog. Returns the final recovered transaction, or null when cancelled.
///
/// [defaultMintUrl] and [defaultQuoteID] pre-fill the input fields.
Future<CashuWalletTransaction?> showCashuQuoteRecoveryDialog(
  BuildContext context,
  NdkFlutter ndkFlutter, {
  String defaultMintUrl = '',
  String defaultQuoteID = '',
}) async {
  return showDialog<CashuWalletTransaction>(
    context: context,
    builder: (_) => _CashuQuoteRecoveryInputDialog(
      ndkFlutter: ndkFlutter,
      defaultMintUrl: defaultMintUrl,
      defaultQuoteID: defaultQuoteID,
    ),
  );
}

class _CashuQuoteRecoveryInputDialog extends StatefulWidget {
  final NdkFlutter ndkFlutter;
  final String defaultMintUrl;
  final String defaultQuoteID;

  const _CashuQuoteRecoveryInputDialog({
    required this.ndkFlutter,
    required this.defaultMintUrl,
    required this.defaultQuoteID,
  });

  @override
  State<_CashuQuoteRecoveryInputDialog> createState() =>
      _CashuQuoteRecoveryInputDialogState();
}

class _CashuQuoteRecoveryInputDialogState
    extends State<_CashuQuoteRecoveryInputDialog> {
  late final TextEditingController _mintUrlController = TextEditingController(
    text: widget.defaultMintUrl,
  );
  late final TextEditingController _quoteIdController = TextEditingController(
    text: widget.defaultQuoteID,
  );
  bool _starting = false;

  @override
  void dispose() {
    _mintUrlController.dispose();
    _quoteIdController.dispose();
    super.dispose();
  }

  Future<void> _pasteQuoteId() async {
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboard?.text == null || !mounted) return;
    _quoteIdController.text = clipboard!.text!.trim();
  }

  Future<void> _startRecovery() async {
    final l10n = AppLocalizations.of(context)!;
    final mintUrl = _mintUrlController.text.trim();
    final quoteId = _quoteIdController.text.trim();
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
    if (quoteId.isEmpty) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseEnterQuoteId),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _starting = true);
    try {
      final transaction = await showDialog<CashuWalletTransaction>(
        context: context,
        barrierDismissible: false,
        builder: (_) => CashuQuoteRecoveryProgressDialog(
          ndkFlutter: widget.ndkFlutter,
          mintUrl: mintUrl,
          quoteID: quoteId,
        ),
      );

      if (transaction != null) {
        final completed = transaction.state == WalletTransactionState.completed;
        final detail = transaction.completionMsg?.trim() ?? '';
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              completed
                  ? l10n.cashuQuoteRecoveryCompleted
                  : detail.isNotEmpty
                  ? '${l10n.quoteRecoveryFailed}: $detail'
                  : l10n.quoteRecoveryFailed,
            ),
            backgroundColor: completed ? Colors.green : Colors.red,
          ),
        );
      }

      if (mounted) Navigator.of(context).pop(transaction);
    } catch (e) {
      if (!mounted) return;
      setState(() => _starting = false);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('${l10n.quoteRecoveryFailed}: $e'),
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
          Expanded(child: Text(l10n.cashuQuoteRecoveryTitle)),
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
          Text(l10n.enterQuoteId),
          const SizedBox(height: 16),
          TextField(
            controller: _mintUrlController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: l10n.mintUrl,
              hintText: l10n.mintUrlHint,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _quoteIdController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: l10n.quoteId,
              hintText: l10n.quoteIdHint,
              suffixIcon: IconButton(
                onPressed: _pasteQuoteId,
                icon: const Icon(Icons.paste),
                tooltip: l10n.copy,
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
          onPressed: _starting ? null : _startRecovery,
          child: _starting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.recoverQuote),
        ),
      ],
    );
  }
}

/// Live-progress dialog for [Cashu.recoverAndCompleteQuote]: shows
/// each recovery stage and the funding transaction state while the mint is
/// completed. Pops with the final transaction once it completes or fails.
class CashuQuoteRecoveryProgressDialog extends StatefulWidget {
  final NdkFlutter ndkFlutter;
  final String mintUrl;
  final String quoteID;

  const CashuQuoteRecoveryProgressDialog({
    super.key,
    required this.ndkFlutter,
    required this.mintUrl,
    required this.quoteID,
  });

  @override
  State<CashuQuoteRecoveryProgressDialog> createState() =>
      _CashuQuoteRecoveryProgressDialogState();
}

class _CashuQuoteRecoveryProgressDialogState
    extends State<CashuQuoteRecoveryProgressDialog> {
  late final Stream<CashuQuoteRecoveryProgress> _progress = widget
      .ndkFlutter
      .ndk
      .cashu
      .recoverAndCompleteQuote(
        mintUrl: widget.mintUrl,
        quoteID: widget.quoteID,
      );
  CashuWalletTransaction? _result;
  String? _errorMessage;
  bool _closed = false;

  /// Pops the dialog (once) returning [transaction].
  void _finish(CashuWalletTransaction? transaction) {
    if (_closed) return;
    _closed = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(transaction);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.cashuQuoteRecoveryTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: StreamBuilder<CashuQuoteRecoveryProgress>(
          stream: _progress,
          builder: (context, snapshot) {
            if (snapshot.hasError && _errorMessage == null) {
              _errorMessage = snapshot.error.toString();
            }
            final progress = snapshot.data;
            final tx = progress?.transaction;
            final bool done = tx?.state == WalletTransactionState.completed;
            final String? failureMessage = _failureMessage(snapshot, tx);
            final bool failed = failureMessage != null;
            // -1 while waiting for the first event
            final int currentStage = progress?.stage.index ?? -1;

            if (done) {
              _result = tx;
              _finish(tx);
            } else if (tx?.state == WalletTransactionState.failed) {
              // keep the dialog open so the failure can be read, but return
              // the failed transaction once the user closes it
              _result = tx;
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CashuStageLine(
                  done: done || currentStage > 0,
                  active: !done && !failed && currentStage <= 0,
                  title: l10n.cashuQuoteRecoveryStageFetchingQuote,
                ),
                CashuStageLine(
                  done: done || currentStage > 1,
                  active: !done && !failed && currentStage == 1,
                  title: l10n.cashuQuoteRecoveryStageRecoveringKey,
                  subtitle: progress?.derivationCounter != null
                      ? l10n.cashuQuoteRecoveryKeyRecovered(
                          progress!.derivationCounter!,
                        )
                      : null,
                ),
                CashuStageLine(
                  done: done,
                  active: !done && !failed && currentStage == 2,
                  title: l10n.cashuQuoteRecoveryStageCompletingMint,
                  subtitle: _completionSubtitle(l10n, tx, done),
                ),
                if (failureMessage != null) ...[
                  const SizedBox(height: 12),
                  CashuErrorPanel(
                    title: l10n.quoteRecoveryFailed,
                    message: failureMessage,
                  ),
                ],
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => _finish(_result), child: Text(l10n.close)),
      ],
    );
  }

  /// Unions the stream exception and a failed transaction into a single
  /// user-facing failure message, cleaned for display.
  String? _failureMessage(
    AsyncSnapshot<CashuQuoteRecoveryProgress> snapshot,
    CashuWalletTransaction? tx,
  ) {
    if (snapshot.hasError) {
      return cleanCashuErrorMessage(snapshot.error.toString());
    }
    if (tx?.state == WalletTransactionState.failed) {
      final msg = tx?.completionMsg;
      if (msg != null && msg.trim().isNotEmpty) return msg.trim();
      return cleanCashuErrorMessage('Minting failed');
    }
    return null;
  }

  String? _completionSubtitle(
    AppLocalizations l10n,
    CashuWalletTransaction? tx,
    bool done,
  ) {
    if (tx == null) return null;
    if (done) return l10n.cashuQuoteRecoveryCompleted;
    if (tx.state == WalletTransactionState.pending) {
      return l10n.waitingForPayment;
    }
    return tx.state.value;
  }
}
