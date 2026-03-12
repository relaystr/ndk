import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ndk/entities.dart';
import 'package:ndk_flutter/ndk_flutter.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../l10n/app_localizations.dart';

/// Card with Send/Receive actions and dialogs for a selected wallet.
///
/// This widget encapsulates the wallet operation flows that were previously
/// implemented directly in the sample app.
class NWalletActions extends StatefulWidget {
  final NdkFlutter ndkFlutter;
  final String selectedWalletId;
  final VoidCallback onClearSelection;

  const NWalletActions({
    super.key,
    required this.ndkFlutter,
    required this.selectedWalletId,
    required this.onClearSelection,
  });

  @override
  State<NWalletActions> createState() => _NWalletActionsState();
}

class _NWalletActionsState extends State<NWalletActions> {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<List<Wallet>>(
      stream: widget.ndkFlutter.ndk.wallets.walletsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final wallet = snapshot.data!.firstWhere(
          (w) => w.id == widget.selectedWalletId,
          orElse: () => throw Exception('Wallet not found'),
        );

        final bool isCashu = wallet is CashuWallet;
        final bool isNwc = wallet is NwcWallet;
        final bool isLnurl = wallet is LnurlWallet;

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isCashu)
                      Image.asset(
                        'assets/images/cashu.png',
                        package: 'ndk_flutter',
                        width: 24,
                        height: 24,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.orange,
                          );
                        },
                      )
                    else if (isNwc)
                      Image.asset(
                        'assets/images/nwc.png',
                        package: 'ndk_flutter',
                        width: 24,
                        height: 24,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.cloud, color: Colors.blue);
                        },
                      )
                    else
                      const Icon(Icons.bolt, color: Colors.purple),
                    const SizedBox(width: 8),
                    Text(
                      isCashu
                          ? l10n.cashuWallet
                          : isNwc
                          ? l10n.nwcWallet
                          : l10n.lnurlWallet,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: widget.onClearSelection,
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                if (!isLnurl)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showSendDialog(context, wallet),
                          icon: const Icon(Icons.send),
                          label: Text(l10n.send),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showReceiveDialog(context, wallet),
                          icon: const Icon(Icons.download),
                          label: Text(l10n.receive),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showCreateInvoiceDialog(context, wallet),
                      icon: const Icon(Icons.download),
                      label: Text(l10n.receive),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSendDialog(BuildContext context, Wallet wallet) {
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
                  final spendingResult = await widget.ndkFlutter.ndk.cashu
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
                    final draftTransaction = await widget.ndkFlutter.ndk.cashu
                        .initiateRedeem(
                          mintUrl: wallet.mintUrl,
                          request: invoice,
                          unit: 'sat',
                          method: 'bolt11',
                        );

                    await for (final transaction
                        in widget.ndkFlutter.ndk.cashu.redeem(
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
                    final response = await widget.ndkFlutter.ndk.wallets
                        .payInvoice(wallet.id, invoice);
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
                  final rcvStream = widget.ndkFlutter.ndk.cashu.receive(token);
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
                    final draftTransaction = await widget.ndkFlutter.ndk.cashu
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
                    final invoice = await widget.ndkFlutter.ndk.wallets.receive(
                      wallet.id,
                      amount,
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
    final stream = widget.ndkFlutter.ndk.cashu.retrieveFunds(
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
              Container(width: 200, child:
              PrettyQrView.data(
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
              )),
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
              Container(width: 200, child:
              PrettyQrView.data(
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
              )),
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
