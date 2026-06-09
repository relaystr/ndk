import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ndk/entities.dart';
import 'package:ndk_flutter/ndk_flutter.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../l10n/app_localizations.dart';

/// Funding transactions reclaimable via [Cashu.retrieveFunds]: they carry a
/// mint quote, method and used keysets. Pending sends/redeems have none and are
/// skipped. Optionally filtered to a single [mintUrl].
List<CashuWalletTransaction> reclaimablePending(
  Iterable<WalletTransaction> transactions, {
  String? mintUrl,
}) {
  return transactions
      .whereType<CashuWalletTransaction>()
      .where(
        (tx) =>
            (mintUrl == null || tx.mintUrl == mintUrl) &&
            tx.qoute != null &&
            tx.method != null &&
            tx.usedKeysets != null,
      )
      .toList();
}

/// Runs [Cashu.retrieveFunds] for each [reclaimable] funding transaction and
/// shows live per-transaction status in a dialog.
Future<void> showReclaimDialog(
  BuildContext context,
  NdkFlutter ndkFlutter,
  List<CashuWalletTransaction> reclaimable,
) async {
  final l10n = AppLocalizations.of(context)!;

  // Start the reclaim stream for each transaction exactly once so the
  // StreamBuilder tiles don't restart the process on every rebuild.
  final streams = <CashuWalletTransaction, Stream<CashuWalletTransaction>>{
    for (final tx in reclaimable)
      tx: ndkFlutter.ndk.cashu
          .retrieveFunds(draftTransaction: tx)
          .asBroadcastStream(),
  };

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.reclaimPendingTitle),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final tx in reclaimable)
                ReclaimPendingTile(transaction: tx, stream: streams[tx]!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.close),
          ),
        ],
      );
    },
  );
}

/// Single row in the reclaim-pending dialog showing the live state of one
/// [Cashu.retrieveFunds] stream.
class ReclaimPendingTile extends StatelessWidget {
  final CashuWalletTransaction transaction;
  final Stream<CashuWalletTransaction> stream;

  const ReclaimPendingTile({
    super.key,
    required this.transaction,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<CashuWalletTransaction>(
      stream: stream,
      builder: (context, snapshot) {
        final state = snapshot.data?.state ?? transaction.state;
        final bool errored =
            snapshot.hasError || state == WalletTransactionState.failed;
        final bool completed = state == WalletTransactionState.completed;

        // Reason for the red mark: stream exception, or the failed tx message.
        final String? reason = snapshot.hasError
            ? snapshot.error.toString()
            : (state == WalletTransactionState.failed
                  ? snapshot.data?.completionMsg
                  : null);

        final Widget trailing;
        if (errored) {
          trailing = Tooltip(
            message: reason ?? state.value,
            triggerMode: TooltipTriggerMode.tap,
            child: const Icon(Icons.error, color: Colors.red, size: 20),
          );
        } else if (completed) {
          trailing = const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 20,
          );
        } else {
          trailing = const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        // While still pending the loop polls the mint until the invoice is
        // paid; make that explicit instead of showing a bare spinner.
        final String subtitle;
        if (errored && reason != null) {
          subtitle = reason;
        } else if (completed) {
          subtitle = state.value;
        } else {
          subtitle = l10n.waitingForPayment;
        }

        return ListTile(
          dense: true,
          leading: const Icon(Icons.download),
          title: Text('${transaction.changeAmount.abs()} ${transaction.unit}'),
          subtitle: Text(
            subtitle,
            style: errored ? const TextStyle(color: Colors.red) : null,
          ),
          trailing: trailing,
        );
      },
    );
  }
}

/// Send/Receive/Reclaim wallet operation flows shared by the wallet actions
/// panel and the wallet card menu. Mix into any [State] that exposes an
/// [ndkFlutter] instance.
mixin WalletActionDialogsMixin<T extends StatefulWidget> on State<T> {
  /// The NDK instance used to perform wallet operations.
  NdkFlutter get ndkFlutter;

  void displayError(String error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
  }

  void displaySuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  /// Receive flow that picks the right dialog per wallet type.
  void showReceiveFlow(BuildContext context, Wallet wallet) {
    if (wallet is NwcWallet || wallet is LnurlWallet) {
      _showCreateInvoiceDialog(context, wallet);
    } else {
      _showReceiveDialog(context, wallet);
    }
  }

  /// Reclaims all reclaimable pending funding transactions of [wallet].
  Future<void> showReclaimPending(
    BuildContext context,
    CashuWallet wallet,
  ) async {
    final reclaimable = reclaimablePending(
      ndkFlutter.ndk.cashu.pendingTransactions.valueOrNull ??
          const <CashuWalletTransaction>[],
      mintUrl: wallet.mintUrl,
    );
    await showReclaimDialog(context, ndkFlutter, reclaimable);
  }

  /// Shows the cashu backup dialog: generates a JSON backup of the local cashu
  /// database (proofs, keysets, counters, transactions) and lets the user copy
  /// it. The seed phrase is global and backed up separately, so it is not
  /// included here. Proofs are bearer funds, hence the warning.
  void showBackupDialog(BuildContext context, CashuWallet wallet) {
    final l10n = AppLocalizations.of(context)!;
    String? backupJson;
    bool generating = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> generate() async {
              setDialogState(() => generating = true);
              try {
                final json =
                    await ndkFlutter.ndk.cashu.exportBackupJsonString();
                setDialogState(() {
                  backupJson = json;
                  generating = false;
                });
              } catch (e) {
                setDialogState(() => generating = false);
                displayError(e.toString());
              }
            }

            return AlertDialog(
              title: Text(l10n.cashuBackupTitle),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(l10n.cashuBackupWarning)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (backupJson != null)
                      Flexible(
                        child: SingleChildScrollView(
                          child: Container(
                            width: double.maxFinite,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SelectableText(
                              backupJson!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.close),
                ),
                if (backupJson == null)
                  TextButton(
                    onPressed: generating ? null : generate,
                    child: Text(
                      generating ? l10n.generatingBackup : l10n.backup,
                    ),
                  )
                else
                  TextButton(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: backupJson!),
                      );
                      displaySuccess(l10n.backupCopiedToClipboard);
                    },
                    child: Text(l10n.copyBackup),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  /// Shows the cashu restore dialog: the user pastes a backup JSON and it is
  /// imported into local storage. The seed phrase is managed separately and is
  /// not part of this backup.
  void showRestoreDialog(BuildContext context, CashuWallet wallet) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    bool restoring = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.cashuRestoreTitle),
              content: TextField(
                controller: controller,
                maxLines: 6,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: l10n.backupJson,
                  hintText: l10n.backupJsonHint,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: restoring
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: restoring
                      ? null
                      : () async {
                          final json = controller.text.trim();
                          if (json.isEmpty) {
                            displayError(l10n.pleaseEnterBackup);
                            return;
                          }
                          setDialogState(() => restoring = true);
                          try {
                            final result = await ndkFlutter.ndk.cashu
                                .importBackupJsonString(json);

                            // Close via the dialog's own navigator and report
                            // through the captured messenger so teardown does
                            // not depend on this card's State staying mounted
                            // (restoring refreshes balances, which can rebuild
                            // and dispose this widget).
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.restoreSuccess(result.restoredProofs),
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => restoring = false);
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: Text(restoring ? l10n.restoringBackup : l10n.restore),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showSendDialog(BuildContext context, Wallet wallet) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.sendOptionsTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              if (wallet is CashuWallet) ...[
                ListTile(
                  leading: const Icon(Icons.receipt),
                  title: Text(l10n.sendByToken),
                  subtitle: Text(l10n.sendByTokenDescription),
                  onTap: () {
                    Navigator.pop(context);
                    _showSendTokenDialog(context, wallet);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.flash_on),
                  title: Text(l10n.sendByLightning),
                  subtitle: Text(l10n.sendByLightningDescription),
                  onTap: () {
                    Navigator.pop(context);
                    _showPayInvoiceDialog(context, wallet);
                  },
                ),
              ] else if (wallet is NwcWallet) ...[
                ListTile(
                  leading: const Icon(Icons.flash_on),
                  title: Text(l10n.payInvoiceTitle),
                  onTap: () {
                    Navigator.pop(context);
                    _showPayInvoiceDialog(context, wallet);
                  },
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showReceiveDialog(BuildContext context, Wallet wallet) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.receiveOptionsTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              if (wallet is CashuWallet) ...[
                ListTile(
                  leading: const Icon(Icons.receipt),
                  title: Text(l10n.receiveByToken),
                  subtitle: Text(l10n.receiveByTokenDescription),
                  onTap: () {
                    Navigator.pop(context);
                    _showReceiveTokenDialog(context, wallet);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.flash_on),
                  title: Text(l10n.receiveByLightning),
                  subtitle: Text(l10n.receiveByLightningDescription),
                  onTap: () {
                    Navigator.pop(context);
                    _showCreateInvoiceDialog(context, wallet);
                  },
                ),
              ] else if (wallet is NwcWallet) ...[
                ListTile(
                  leading: const Icon(Icons.flash_on),
                  title: Text(l10n.createInvoiceTitle),
                  onTap: () {
                    Navigator.pop(context);
                    _showCreateInvoiceDialog(context, wallet);
                  },
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showSendTokenDialog(BuildContext context, CashuWallet wallet) {
    final l10n = AppLocalizations.of(context)!;
    final amountController = TextEditingController();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.sendByToken),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: l10n.amount,
              hintText: l10n.amountHint,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                final amount = int.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  displayError(l10n.pleaseEnterValidAmount);
                  return;
                }

                try {
                  final spendingResult = await ndkFlutter.ndk.cashu
                      .initiateSpend(
                        mintUrl: wallet.mintUrl,
                        amount: amount,
                        unit: 'sat',
                      );
                  final cashuString = spendingResult.token.toV4TokenString();

                  await Clipboard.setData(ClipboardData(text: cashuString));
                  if (!mounted) return;
                  navigator.pop();
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(l10n.tokenCopiedToClipboard),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  displayError(e.toString());
                }
              },
              child: Text(l10n.createToken),
            ),
          ],
        );
      },
    );
  }

  void _showPayInvoiceDialog(BuildContext context, Wallet wallet) {
    final l10n = AppLocalizations.of(context)!;
    final invoiceController = TextEditingController();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.payInvoiceTitle),
          content: TextField(
            controller: invoiceController,
            maxLines: 3,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: l10n.invoice,
              hintText: l10n.invoiceHint,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                final invoice = invoiceController.text.trim();
                if (invoice.isEmpty) {
                  displayError(l10n.pleaseEnterInvoice);
                  return;
                }

                try {
                  if (wallet is CashuWallet) {
                    final draftTransaction = await ndkFlutter.ndk.cashu
                        .initiateRedeem(
                          mintUrl: wallet.mintUrl,
                          request: invoice,
                          unit: 'sat',
                          method: 'bolt11',
                        );

                    await for (final transaction
                        in ndkFlutter.ndk.cashu.redeem(
                          draftRedeemTransaction: draftTransaction,
                        )) {
                      if (transaction.state ==
                          WalletTransactionState.completed) {
                        if (!mounted) return;
                        navigator.pop();
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(l10n.invoicePaid),
                            backgroundColor: Colors.green,
                          ),
                        );
                        break;
                      } else if (transaction.state ==
                          WalletTransactionState.failed) {
                        displayError(
                          l10n.paymentFailed(transaction.completionMsg ?? ''),
                        );
                        break;
                      }
                    }
                  } else if (wallet is NwcWallet) {
                    final response = await ndkFlutter.ndk.wallets.send(
                      walletId: wallet.id,
                      invoice: invoice,
                    );
                    if (response.errorCode == null &&
                        response.preimage != null) {
                      if (!mounted) return;
                      navigator.pop();
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(l10n.invoicePaid),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      displayError(
                        l10n.paymentFailed(
                          response.errorMessage ?? l10n.unknownWalletType,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  displayError(e.toString());
                }
              },
              child: Text(l10n.pay),
            ),
          ],
        );
      },
    );
  }

  void _showReceiveTokenDialog(BuildContext context, CashuWallet wallet) {
    final l10n = AppLocalizations.of(context)!;
    final tokenController = TextEditingController();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.receiveByTokenTitle),
          content: TextField(
            controller: tokenController,
            maxLines: 4,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: l10n.token,
              hintText: l10n.tokenHint,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                final token = tokenController.text.trim();
                if (token.isEmpty) {
                  displayError(l10n.pleaseEnterToken);
                  return;
                }

                try {
                  final rcvStream = ndkFlutter.ndk.cashu.receive(token);
                  await rcvStream.last;
                  if (!mounted) return;
                  navigator.pop();
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(l10n.tokenReceived),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  displayError(e.toString());
                }
              },
              child: Text(l10n.receive),
            ),
          ],
        );
      },
    );
  }

  void _showCreateInvoiceDialog(BuildContext context, Wallet wallet) {
    final l10n = AppLocalizations.of(context)!;
    final amountController = TextEditingController();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.createInvoiceTitle),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: l10n.amount,
              hintText: l10n.amountHint,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                final amount = int.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  displayError(l10n.pleaseEnterValidAmount);
                  return;
                }

                try {
                  if (wallet is CashuWallet) {
                    final draftTransaction = await ndkFlutter.ndk.cashu
                        .initiateFund(
                          mintUrl: wallet.mintUrl,
                          amount: amount,
                          unit: 'sat',
                          method: 'bolt11',
                        );

                    if (draftTransaction.qoute?.request != null) {
                      final invoice = draftTransaction.qoute!.request;
                      await Clipboard.setData(ClipboardData(text: invoice));

                      if (!mounted) return;
                      navigator.pop();
                      _showCashuInvoiceTrackingDialog(
                        invoice,
                        draftTransaction,
                        scaffoldMessenger,
                      );
                    }
                  } else if (wallet is NwcWallet || wallet is LnurlWallet) {
                    final invoice = await ndkFlutter.ndk.wallets.receive(
                      walletId: wallet.id,
                      amountSats: amount,
                    );
                    await Clipboard.setData(ClipboardData(text: invoice));
                    if (!mounted) return;
                    navigator.pop();
                    _showGenericInvoiceTrackingDialog(
                      invoice,
                      scaffoldMessenger,
                    );
                  }
                } catch (e) {
                  displayError(e.toString());
                }
              },
              child: Text(l10n.create),
            ),
          ],
        );
      },
    );
  }

  void _showCashuInvoiceTrackingDialog(
    String invoice,
    CashuWalletTransaction draftTransaction,
    ScaffoldMessengerState scaffoldMessenger,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final stream = ndkFlutter.ndk.cashu.retrieveFunds(
      draftTransaction: draftTransaction,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.invoiceTrackingTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.invoiceCreatedMessage),
              const SizedBox(height: 12),
              SizedBox(
                width: 200,
                child: PrettyQrView.data(
                  data: invoice.toUpperCase(),
                  errorCorrectLevel: QrErrorCorrectLevel.M,
                  decoration: const PrettyQrDecoration(
                    quietZone: PrettyQrQuietZone.standart,
                    background: Colors.white,
                    shape: PrettyQrSmoothSymbol(
                      color: Colors.black,
                      roundFactor: 0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  invoice,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder<CashuWalletTransaction>(
                stream: stream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final tx = snapshot.data!;
                    if (tx.state == WalletTransactionState.completed) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Navigator.of(dialogContext).pop();
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(l10n.paymentReceived),
                            backgroundColor: Colors.green,
                          ),
                        );
                      });
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            l10n.paid,
                            style: const TextStyle(color: Colors.green),
                          ),
                        ],
                      );
                    } else if (tx.state == WalletTransactionState.failed) {
                      return Text(
                        l10n.paymentFailed(tx.completionMsg ?? ''),
                        style: const TextStyle(color: Colors.red),
                      );
                    }
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(l10n.waitingForPayment),
                    ],
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.close),
            ),
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: invoice));
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(l10n.copied),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text(l10n.copyAgain),
            ),
          ],
        );
      },
    );
  }

  void _showGenericInvoiceTrackingDialog(
    String invoice,
    ScaffoldMessengerState scaffoldMessenger,
  ) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.invoiceTrackingTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.invoiceCreatedMessage),
              const SizedBox(height: 12),
              SizedBox(
                width: 200,
                child: PrettyQrView.data(
                  data: invoice.toUpperCase(),
                  errorCorrectLevel: QrErrorCorrectLevel.M,
                  decoration: const PrettyQrDecoration(
                    quietZone: PrettyQrQuietZone.standart,
                    background: Colors.white,
                    shape: PrettyQrSmoothSymbol(
                      color: Colors.black,
                      roundFactor: 0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  invoice,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      l10n.waitingForPayment,
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.close),
            ),
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: invoice));
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(l10n.copied),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text(l10n.copyAgain),
            ),
          ],
        );
      },
    );
  }
}
