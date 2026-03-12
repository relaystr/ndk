import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/domain_layer/entities/wallet/providers/cashu/cashu_wallet.dart';
import 'package:ndk/domain_layer/entities/wallet/providers/lnurl/lnurl_wallet.dart';
import 'package:ndk/domain_layer/entities/wallet/providers/nwc/nwc_wallet.dart';
import 'package:ndk/ndk.dart';

/// Card with Send/Receive actions and dialogs for a selected wallet.
///
/// This widget encapsulates the wallet operation flows that were previously
/// implemented directly in the sample app.
class NWalletActions extends StatefulWidget {
  final Ndk ndk;
  final String selectedWalletId;
  final VoidCallback onClearSelection;

  const NWalletActions({
    super.key,
    required this.ndk,
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
    return StreamBuilder<List<Wallet>>(
      stream: widget.ndk.wallets.walletsStream,
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
                    Icon(
                      isCashu
                          ? Icons.account_balance_wallet
                          : isNwc
                          ? Icons.cloud
                          : Icons.bolt,
                      color: isCashu
                          ? Colors.orange
                          : isNwc
                          ? Colors.blue
                          : Colors.purple,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isCashu
                          ? 'Cashu Wallet'
                          : isNwc
                          ? 'NWC Wallet'
                          : 'LNURL Wallet',
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
                          label: const Text('Send'),
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
                          label: const Text('Receive'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'Receive-only wallet',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSendDialog(BuildContext context, Wallet wallet) {
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
              Text('Send', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              if (wallet is CashuWallet) ...[
                ListTile(
                  leading: const Icon(Icons.receipt),
                  title: const Text('Send by Token'),
                  subtitle: const Text('Create an ecash token'),
                  onTap: () {
                    Navigator.pop(context);
                    _showSendTokenDialog(context, wallet);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.flash_on),
                  title: const Text('Send by Lightning'),
                  subtitle: const Text('Pay a BOLT11 invoice'),
                  onTap: () {
                    Navigator.pop(context);
                    _showPayInvoiceDialog(context, wallet);
                  },
                ),
              ] else if (wallet is NwcWallet) ...[
                ListTile(
                  leading: const Icon(Icons.flash_on),
                  title: const Text('Pay Lightning Invoice'),
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
              Text('Receive', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              if (wallet is CashuWallet) ...[
                ListTile(
                  leading: const Icon(Icons.receipt),
                  title: const Text('Receive by Token'),
                  subtitle: const Text('Redeem an ecash token'),
                  onTap: () {
                    Navigator.pop(context);
                    _showReceiveTokenDialog(context, wallet);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.flash_on),
                  title: const Text('Receive by Lightning'),
                  subtitle: const Text('Create a BOLT11 invoice'),
                  onTap: () {
                    Navigator.pop(context);
                    _showCreateInvoiceDialog(context, wallet);
                  },
                ),
              ] else if (wallet is NwcWallet) ...[
                ListTile(
                  leading: const Icon(Icons.flash_on),
                  title: const Text('Create Lightning Invoice'),
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
    final amountController = TextEditingController();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Send by Token'),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Amount (sats)',
              hintText: '10',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final amount = int.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  displayError('Please enter a valid amount');
                  return;
                }

                try {
                  final spendingResult = await widget.ndk.cashu.initiateSpend(
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
                      content: Text('Token copied to clipboard!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  displayError(e.toString());
                }
              },
              child: const Text('Create Token'),
            ),
          ],
        );
      },
    );
  }

  void _showPayInvoiceDialog(BuildContext context, Wallet wallet) {
    final invoiceController = TextEditingController();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pay Lightning Invoice'),
          content: TextField(
            controller: invoiceController,
            maxLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Invoice (bolt11)',
              hintText: 'lnbc...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final invoice = invoiceController.text.trim();
                if (invoice.isEmpty) {
                  displayError('Please enter an invoice');
                  return;
                }

                try {
                  if (wallet is CashuWallet) {
                    final draftTransaction = await widget.ndk.cashu
                        .initiateRedeem(
                          mintUrl: wallet.mintUrl,
                          request: invoice,
                          unit: 'sat',
                          method: 'bolt11',
                        );

                    await for (final transaction in widget.ndk.cashu.redeem(
                      draftRedeemTransaction: draftTransaction,
                    )) {
                      if (transaction.state ==
                          WalletTransactionState.completed) {
                        if (!mounted) return;
                        navigator.pop();
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text('Invoice paid!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        break;
                      } else if (transaction.state ==
                          WalletTransactionState.failed) {
                        displayError(
                          'Payment failed: ${transaction.completionMsg}',
                        );
                        break;
                      }
                    }
                  } else if (wallet is NwcWallet) {
                    final response = await widget.ndk.wallets.payInvoice(
                      wallet.id,
                      invoice,
                    );
                    if (response.errorCode == null &&
                        response.preimage != null) {
                      if (!mounted) return;
                      navigator.pop();
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('Invoice paid!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      displayError(
                        'Payment failed: ${response.errorMessage ?? 'Unknown error'}',
                      );
                    }
                  }
                } catch (e) {
                  displayError(e.toString());
                }
              },
              child: const Text('Pay'),
            ),
          ],
        );
      },
    );
  }

  void _showReceiveTokenDialog(BuildContext context, CashuWallet wallet) {
    final tokenController = TextEditingController();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Receive by Token'),
          content: TextField(
            controller: tokenController,
            maxLines: 4,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Cashu Token',
              hintText: 'Paste token here...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final token = tokenController.text.trim();
                if (token.isEmpty) {
                  displayError('Please enter a token');
                  return;
                }

                try {
                  final rcvStream = widget.ndk.cashu.receive(token);
                  await rcvStream.last;
                  if (!mounted) return;
                  navigator.pop();
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Token received!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  displayError(e.toString());
                }
              },
              child: const Text('Receive'),
            ),
          ],
        );
      },
    );
  }

  void _showCreateInvoiceDialog(BuildContext context, Wallet wallet) {
    final amountController = TextEditingController();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Invoice'),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Amount (sats)',
              hintText: '10',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final amount = int.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  displayError('Please enter a valid amount');
                  return;
                }

                try {
                  if (wallet is CashuWallet) {
                    final draftTransaction = await widget.ndk.cashu
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
                      _showInvoiceTrackingDialog(
                        invoice,
                        draftTransaction,
                        scaffoldMessenger,
                      );
                    }
                  } else if (wallet is NwcWallet) {
                    final invoice = await widget.ndk.wallets.receive(
                      wallet.id,
                      amount,
                    );
                    await Clipboard.setData(ClipboardData(text: invoice));
                    if (!mounted) return;
                    navigator.pop();
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Invoice created and copied!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  displayError(e.toString());
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _showInvoiceTrackingDialog(
    String invoice,
    CashuWalletTransaction draftTransaction,
    ScaffoldMessengerState scaffoldMessenger,
  ) {
    final stream = widget.ndk.cashu.retrieveFunds(
      draftTransaction: draftTransaction,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Lightning Invoice'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Invoice created and copied!'),
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
                            content: Text('Payment received!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      });
                      return const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Paid!', style: TextStyle(color: Colors.green)),
                        ],
                      );
                    } else if (tx.state == WalletTransactionState.failed) {
                      return Text(
                        'Failed: ${tx.completionMsg}',
                        style: const TextStyle(color: Colors.red),
                      );
                    }
                  }
                  return const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Waiting for payment...'),
                    ],
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: invoice));
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Copied!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Copy Again'),
            ),
          ],
        );
      },
    );
  }
}
