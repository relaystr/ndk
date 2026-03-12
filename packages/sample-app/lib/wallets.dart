import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:ndk/entities.dart';
import 'package:ndk/domain_layer/entities/wallet/providers/cashu/cashu_wallet.dart';
import 'package:ndk/domain_layer/entities/wallet/providers/lnurl/lnurl_wallet.dart';
import 'package:ndk/domain_layer/entities/wallet/providers/nwc/nwc_wallet.dart';
import 'package:ndk/presentation_layer/ndk.dart';

const String defaultMintUrl = "https://dev.mint.camelus.app";

class WalletsPage extends StatefulWidget {
  final Ndk ndk;
  const WalletsPage({super.key, required this.ndk});

  @override
  State<WalletsPage> createState() => _WalletsPageState();
}

class _WalletsPageState extends State<WalletsPage> {
  String? _selectedWalletId;
  final TextEditingController _mintUrlController = TextEditingController();

  void displayError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error), backgroundColor: Colors.red),
    );
  }

  void displaySuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  void dispose() {
    _mintUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Add buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("My Wallets",
                      style: Theme.of(context).textTheme.headlineSmall),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _showAddCashuWalletDialog(context),
                        icon: const Icon(Icons.add_card),
                        tooltip: "Add Cashu",
                      ),
                      IconButton(
                        onPressed: () => _showAddNwcWalletDialog(context),
                        icon: const Icon(Icons.cloud_upload),
                        tooltip: "Add NWC",
                      ),
                      IconButton(
                        icon: const Icon(Icons.bolt),
                        tooltip: "Add LNURL",
                        onPressed: () => _showAddLnurlWalletDialog(context),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Horizontal Card List
              SizedBox(
                height: 200,
                child: WalletCardsList(
                  ndk: widget.ndk,
                  selectedWalletId: _selectedWalletId,
                  onWalletSelected: (walletId) {
                    setState(() {
                      _selectedWalletId = walletId;
                    });
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Send/Receive Actions (only when wallet selected)
              if (_selectedWalletId != null) _buildWalletActions(context),

              const SizedBox(height: 24),

              // Pending Transactions
              PendingTransactionsSection(ndk: widget.ndk),

              // Recent Transactions
              Text("Recent Activity",
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: RecentTransactions(ndk: widget.ndk),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletActions(BuildContext context) {
    return StreamBuilder<List<Wallet>>(
      stream: widget.ndk.wallets.walletsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final wallet = snapshot.data!.firstWhere(
          (w) => w.id == _selectedWalletId,
          orElse: () => throw Exception("Wallet not found"),
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
                          ? "Cashu Wallet"
                          : isNwc
                              ? "NWC Wallet"
                              : "LNURL Wallet",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _selectedWalletId = null;
                        });
                      },
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showSendDialog(context, wallet),
                        icon: const Icon(Icons.send),
                        label: const Text("Send"),
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
                        label: const Text("Receive"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
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
              Text("Send", style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              if (wallet is CashuWallet) ...[
                ListTile(
                  leading: const Icon(Icons.receipt),
                  title: const Text("Send by Token"),
                  subtitle: const Text("Create an ecash token"),
                  onTap: () {
                    Navigator.pop(context);
                    _showSendTokenDialog(context, wallet);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.flash_on),
                  title: const Text("Send by Lightning"),
                  subtitle: const Text("Pay a BOLT11 invoice"),
                  onTap: () {
                    Navigator.pop(context);
                    _showPayInvoiceDialog(context, wallet);
                  },
                ),
              ] else if (wallet is NwcWallet) ...[
                ListTile(
                  leading: const Icon(Icons.flash_on),
                  title: const Text("Pay Lightning Invoice"),
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
              Text("Receive", style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              if (wallet is CashuWallet) ...[
                ListTile(
                  leading: const Icon(Icons.receipt),
                  title: const Text("Receive by Token"),
                  subtitle: const Text("Redeem an ecash token"),
                  onTap: () {
                    Navigator.pop(context);
                    _showReceiveTokenDialog(context, wallet);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.flash_on),
                  title: const Text("Receive by Lightning"),
                  subtitle: const Text("Create a BOLT11 invoice"),
                  onTap: () {
                    Navigator.pop(context);
                    _showCreateInvoiceDialog(context, wallet);
                  },
                ),
              ] else if (wallet is NwcWallet) ...[
                ListTile(
                  leading: const Icon(Icons.flash_on),
                  title: const Text("Create Lightning Invoice"),
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
                  displayError("Please enter a valid amount");
                  return;
                }

                try {
                  final spendingResult = await widget.ndk.cashu.initiateSpend(
                    mintUrl: wallet.mintUrl,
                    amount: amount,
                    unit: "sat",
                  );
                  final cashuString = spendingResult.token.toV4TokenString();

                  await Clipboard.setData(ClipboardData(text: cashuString));
                  if (mounted) {
                    Navigator.pop(context);
                    displaySuccess("Token copied to clipboard!");
                  }
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
                  displayError("Please enter an invoice");
                  return;
                }

                try {
                  if (wallet is CashuWallet) {
                    final draftTransaction =
                        await widget.ndk.cashu.initiateRedeem(
                      mintUrl: wallet.mintUrl,
                      request: invoice,
                      unit: "sat",
                      method: "bolt11",
                    );

                    await for (final transaction in widget.ndk.cashu.redeem(
                      draftRedeemTransaction: draftTransaction,
                    )) {
                      if (transaction.state ==
                          WalletTransactionState.completed) {
                        if (mounted) {
                          Navigator.pop(context);
                          displaySuccess("Invoice paid!");
                        }
                        break;
                      } else if (transaction.state ==
                          WalletTransactionState.failed) {
                        displayError(
                            "Payment failed: ${transaction.completionMsg}");
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
                      if (mounted) {
                        Navigator.pop(context);
                        displaySuccess("Invoice paid!");
                      }
                    } else {
                      displayError(
                          "Payment failed: ${response.errorMessage ?? 'Unknown error'}");
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
                  displayError("Please enter a token");
                  return;
                }

                try {
                  final rcvStream = widget.ndk.cashu.receive(token);
                  await rcvStream.last;
                  if (mounted) {
                    Navigator.pop(context);
                    displaySuccess("Token received!");
                  }
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
                  displayError("Please enter a valid amount");
                  return;
                }

                try {
                  if (wallet is CashuWallet) {
                    final draftTransaction =
                        await widget.ndk.cashu.initiateFund(
                      mintUrl: wallet.mintUrl,
                      amount: amount,
                      unit: "sat",
                      method: "bolt11",
                    );

                    if (draftTransaction.qoute?.request != null) {
                      final invoice = draftTransaction.qoute!.request;
                      await Clipboard.setData(ClipboardData(text: invoice));

                      if (mounted) {
                        Navigator.pop(context);
                        _showInvoiceTrackingDialog(invoice, draftTransaction);
                      }
                    }
                  } else if (wallet is NwcWallet) {
                    final invoice = await widget.ndk.wallets.receive(
                      wallet.id,
                      amount,
                    );
                    await Clipboard.setData(ClipboardData(text: invoice));
                    if (mounted) {
                      Navigator.pop(context);
                      displaySuccess("Invoice created and copied!");
                    }
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
      String invoice, CashuWalletTransaction draftTransaction) {
    final stream = widget.ndk.cashu.retrieveFunds(
      draftTransaction: draftTransaction,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
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
                        Navigator.of(context).pop();
                        displaySuccess('Payment received!');
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: invoice));
                displaySuccess("Copied!");
              },
              child: const Text('Copy Again'),
            ),
          ],
        );
      },
    );
  }

  void _showAddCashuWalletDialog(BuildContext context) {
    _mintUrlController.text = defaultMintUrl;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Cashu Wallet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter the mint URL:'),
              const SizedBox(height: 16),
              TextField(
                controller: _mintUrlController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Mint URL',
                  hintText: 'https://mint.example.com',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final mintUrl = _mintUrlController.text.trim();
                if (mintUrl.isEmpty) {
                  displayError("Please enter a mint URL");
                  return;
                }

                try {
                  await widget.ndk.cashu.addMintToKnownMints(mintUrl: mintUrl);
                  final mintInfo = await widget.ndk.cashu
                      .getMintInfoNetwork(mintUrl: mintUrl);

                  final cashuWallet = CashuWallet(
                    id: mintUrl,
                    name: mintInfo.name ?? mintUrl,
                    mintUrl: mintUrl,
                    mintInfo: mintInfo,
                    supportedUnits: mintInfo.supportedUnits,
                  );

                  await widget.ndk.wallets.addWallet(cashuWallet);

                  if (mounted) {
                    Navigator.of(context).pop();
                    displaySuccess("Cashu wallet added!");
                    setState(() {
                      _selectedWalletId = cashuWallet.id;
                    });
                  }
                } catch (e) {
                  displayError("Failed to add mint: $e");
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showAddNwcWalletDialog(BuildContext context) {
    final nwcUriController = TextEditingController();
    final balanceController = TextEditingController(text: '10000');
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return DefaultTabController(
          length: 2,
          child: AlertDialog(
            title: const Text('Add NWC Wallet'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Faucet'),
                      Tab(text: 'Manual'),
                    ],
                  ),
                  SizedBox(
                    height: 150,
                    child: TabBarView(
                      children: [
                        // Faucet Tab
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text(
                                'Create a test wallet via NWC Faucet',
                                style: TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: balanceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Starting Balance (sats)',
                                  hintText: '10000',
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Manual Tab
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            controller: nwcUriController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'NWC Connection URI',
                              hintText: 'nostr+walletconnect://...',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              StatefulBuilder(
                builder: (context, setState) {
                  return TextButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            final tabController =
                                DefaultTabController.of(context);
                            final currentTab = tabController.index;

                            if (currentTab == 0) {
                              // Faucet tab
                              setState(() {
                                isLoading = true;
                              });

                              try {
                                final balance =
                                    int.tryParse(balanceController.text) ??
                                        10000;
                                final response = await http.post(
                                  Uri.parse(
                                      'https://faucet.nwc.dev?balance=$balance'),
                                );

                                if (response.statusCode == 200) {
                                  final nwcUri = response.body.trim();

                                  if (nwcUri != null && nwcUri.isNotEmpty) {
                                    final walletId = DateTime.now()
                                        .millisecondsSinceEpoch
                                        .toString();
                                    final nwcWallet = NwcWallet(
                                      id: walletId,
                                      name: "NWC Faucet",
                                      supportedUnits: {'sat'},
                                      nwcUrl: nwcUri,
                                    );
                                    await widget.ndk.wallets
                                        .addWallet(nwcWallet);

                                    if (mounted) {
                                      Navigator.of(context).pop();
                                      displaySuccess(
                                          "NWC faucet wallet added with $balance sats!");
                                      this.setState(() {
                                        _selectedWalletId = nwcWallet.id;
                                      });
                                    }
                                  } else {
                                    displayError(
                                        "Invalid response from faucet");
                                  }
                                } else {
                                  displayError(
                                      "Failed to create wallet: ${response.statusCode}");
                                }
                              } catch (e) {
                                displayError("Error creating wallet: $e");
                              } finally {
                                setState(() {
                                  isLoading = false;
                                });
                              }
                            } else {
                              // Manual tab
                              try {
                                final walletId = DateTime.now()
                                    .millisecondsSinceEpoch
                                    .toString();
                                final nwcWallet = NwcWallet(
                                  id: walletId,
                                  name:
                                      "NWC ${DateTime.now().toString().split(' ')[1].substring(0, 5)}",
                                  supportedUnits: {'sat'},
                                  nwcUrl: nwcUriController.text,
                                );
                                await widget.ndk.wallets.addWallet(nwcWallet);

                                if (mounted) {
                                  Navigator.of(context).pop();
                                  displaySuccess("NWC wallet added!");
                                  this.setState(() {
                                    _selectedWalletId = nwcWallet.id;
                                  });
                                }
                              } catch (e) {
                                displayError(e.toString());
                              }
                            }
                          },
                    child: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Add'),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddLnurlWalletDialog(BuildContext context) {
    final identifierController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add LNURL Wallet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your LNURL identifier:'),
              const SizedBox(height: 16),
              TextField(
                controller: identifierController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'user@domain.com',
                  hintText: 'user@domain.com',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final identifier = identifierController.text.trim();
                if (identifier.isEmpty || !identifier.contains('@')) {
                  displayError(
                      "Please enter a valid identifier (user@domain.com)");
                  return;
                }

                try {
                  final walletId =
                      DateTime.now().millisecondsSinceEpoch.toString();
                  final wallet = widget.ndk.wallets.createWallet(
                    type: WalletType.LNURL,
                    id: walletId,
                    name: "LNURL",
                    supportedUnits: {'sat'},
                    metadata: {'identifier': identifier},
                  );
                  await widget.ndk.wallets.addWallet(wallet);

                  if (mounted) {
                    Navigator.of(context).pop();
                    displaySuccess("LNURL wallet added!");
                    setState(() {
                      _selectedWalletId = wallet.id;
                    });
                  }
                } catch (e) {
                  displayError(e.toString());
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}

// Horizontal Card List Widget
class WalletCardsList extends StatelessWidget {
  final Ndk ndk;
  final String? selectedWalletId;
  final Function(String) onWalletSelected;

  const WalletCardsList({
    super.key,
    required this.ndk,
    this.selectedWalletId,
    required this.onWalletSelected,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Wallet>>(
      stream: ndk.wallets.walletsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final wallets = snapshot.data ?? [];

        if (wallets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wallet, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'No wallets yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const Text('Tap + to add one'),
              ],
            ),
          );
        }

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: wallets.length,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemBuilder: (context, index) {
            final wallet = wallets[index];
            return WalletCard(
              wallet: wallet,
              ndk: ndk,
              isSelected: wallet.id == selectedWalletId,
              onTap: () => onWalletSelected(wallet.id),
            );
          },
        );
      },
    );
  }
}

// Individual Wallet Card
class WalletCard extends StatelessWidget {
  final Wallet wallet;
  final Ndk ndk;
  final bool isSelected;
  final VoidCallback onTap;

  const WalletCard({
    super.key,
    required this.wallet,
    required this.ndk,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCashu = wallet is CashuWallet;
    final bool isNwc = wallet is NwcWallet;
    final bool isLnurl = wallet is LnurlWallet;

    // Determine wallet name based on type
    final String walletName;
    if (isCashu) {
      walletName = (wallet as CashuWallet).mintInfo.name ?? 'Cashu';
    } else if (isNwc) {
      walletName = (wallet as NwcWallet).name;
    } else if (isLnurl) {
      walletName = (wallet as LnurlWallet).name;
    } else {
      walletName = 'Unknown';
    }

    // Determine subtitle based on type
    final String subtitle;
    if (isCashu) {
      subtitle = (wallet as CashuWallet).mintUrl.replaceAll('https://', '');
    } else if (isNwc) {
      subtitle = 'NWC Wallet';
    } else if (isLnurl) {
      subtitle = (wallet as LnurlWallet).identifier;
    } else {
      subtitle = '';
    }

    // Determine gradient colors based on type
    final List<Color> gradientColors;
    final Color shadowColor;
    if (isCashu) {
      gradientColors = [Colors.orange[700]!, Colors.orange[400]!];
      shadowColor = Colors.orange;
    } else if (isNwc) {
      gradientColors = [Colors.blue[700]!, Colors.blue[400]!];
      shadowColor = Colors.blue;
    } else if (isLnurl) {
      gradientColors = [Colors.purple[700]!, Colors.purple[400]!];
      shadowColor = Colors.purple;
    } else {
      gradientColors = [Colors.grey[700]!, Colors.grey[400]!];
      shadowColor = Colors.grey;
    }

    // Determine icon based on type
    final IconData walletIcon;
    if (isCashu) {
      walletIcon = Icons.account_balance_wallet;
    } else if (isNwc) {
      walletIcon = Icons.cloud;
    } else if (isLnurl) {
      walletIcon = Icons.bolt;
    } else {
      walletIcon = Icons.wallet;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withAlpha(100),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                walletIcon,
                size: 120,
                color: Colors.white.withAlpha(30),
              ),
            ),
            // Card content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        walletIcon,
                        color: Colors.white,
                        size: 32,
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'SELECTED',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        walletName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withAlpha(200),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      // Balance display
                      isLnurl
                          ? Text(
                              'Receive-only wallet',
                              style: TextStyle(
                                color: Colors.white.withAlpha(200),
                                fontSize: 14,
                              ),
                            )
                          : StreamBuilder<List<WalletBalance>>(
                              stream: ndk.wallets.getBalancesStream(wallet.id),
                              builder: (context, snapshot) {
                                final balances = snapshot.data ?? [];
                                final satBalance = balances
                                    .firstWhere(
                                      (b) => b.unit == 'sat',
                                      orElse: () => WalletBalance(
                                        walletId: wallet.id,
                                        unit: 'sat',
                                        amount: 0,
                                      ),
                                    )
                                    .amount;

                                return Row(
                                  children: [
                                    Text(
                                      '$satBalance',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'sats',
                                      style: TextStyle(
                                        color: Colors.white.withAlpha(200),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                    ],
                  ),
                ],
              ),
            ),
            // Long press to delete
            Positioned(
              right: 8,
              bottom: 8,
              child: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white70),
                onPressed: () => _showDeleteDialog(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Wallet?'),
          content: const Text(
              'This will remove the wallet from the app. Your funds are not affected.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await ndk.wallets.removeWallet(wallet.id);
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

class PendingTransactionsSection extends StatelessWidget {
  final Ndk ndk;
  const PendingTransactionsSection({super.key, required this.ndk});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: ndk.wallets.combinedPendingTransactions,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Pending", style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
            ],
          );
        }

        final transactions = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Pending", style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  return Card(
                    margin: const EdgeInsets.only(right: 8),
                    child: Container(
                      width: 200,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Icon(
                                tx.changeAmount > 0
                                    ? Icons.download
                                    : Icons.send,
                                size: 16,
                                color: tx.changeAmount > 0
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${tx.changeAmount.abs()} ${tx.unit}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tx.walletType.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tx.state.value,
                            style: TextStyle(
                              fontSize: 11,
                              color: tx.state == WalletTransactionState.pending
                                  ? Colors.orange
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

class RecentTransactions extends StatelessWidget {
  final Ndk ndk;
  const RecentTransactions({super.key, required this.ndk});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: ndk.wallets.combinedRecentTransactions,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No recent transactions'));
        } else {
          final transactions = snapshot.data!;
          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              return ListTile(
                leading: Icon(
                  tx.changeAmount > 0 ? Icons.download : Icons.send,
                  color: tx.changeAmount > 0 ? Colors.green : Colors.orange,
                ),
                title: Text(
                  '${tx.changeAmount.abs()} ${tx.unit}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${tx.walletType.name} • ${tx.state.value}'),
                trailing: tx is CashuWalletTransaction && tx.token != null
                    ? IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: tx.token!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Token copied')),
                          );
                        },
                      )
                    : null,
              );
            },
          );
        }
      },
    );
  }
}
