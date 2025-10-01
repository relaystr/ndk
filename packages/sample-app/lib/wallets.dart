import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/presentation_layer/ndk.dart';

const String mintUrl = "https://dev.mint.camelus.app";

class WalletsPage extends StatefulWidget {
  final Ndk ndk;
  const WalletsPage({super.key, required this.ndk});

  @override
  State<WalletsPage> createState() => _WalletsPageState();
}

class _WalletsPageState extends State<WalletsPage> {
  String cashuIn = "";
  TextEditingController cashuInController = TextEditingController();

  displayError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.red,
      ),
    );
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
            // Wallets Balance Section
            Text("Wallets Balance",
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            SizedBox(
              height: 140,
              child: Balances(ndk: widget.ndk),
            ),

            const SizedBox(height: 16),

            // Pending Transactions Section
            Text("Pending transactions",
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              child: Pending(ndk: widget.ndk),
            ),
            Text("Recent transactions",
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              child: RecentTransactions(ndk: widget.ndk),
            ),

            const SizedBox(height: 24),

            // CASHU Section
            Text("CASHU", style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),

            // CASHU Controls
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  TextButton(
                    onPressed: () async {
                      final draftTransaction =
                          await widget.ndk.cashu.initiateFund(
                        mintUrl: mintUrl,
                        amount: 10,
                        unit: "sat",
                        method: "bolt11",
                      );
                      final tStream = widget.ndk.cashu
                          .retrieveFunds(draftTransaction: draftTransaction);
                      await tStream.last;
                    },
                    child: const Text("mint 10 sat"),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      try {
                        final spendingResult =
                            await widget.ndk.cashu.initiateSpend(
                          mintUrl: mintUrl,
                          amount: 10,
                          unit: "sat",
                        );
                        final cashuString =
                            spendingResult.token.toV4TokenString();

                        Clipboard.setData(ClipboardData(text: cashuString));
                      } catch (e) {
                        displayError(e.toString());
                      }
                    },
                    child: const Text("send 10 sat"),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: cashuInController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'CASHU Token',
                      ),
                      onChanged: (value) {
                        cashuIn = value;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      try {
                        final rcvStream = widget.ndk.cashu.receive(cashuIn);
                        await rcvStream.last;
                        setState(() {
                          cashuIn = "";
                          cashuInController.text = "";
                        });
                      } catch (e) {
                        displayError(e.toString());
                      }
                    },
                    child: const Text("receive"),
                  ),
                  TextButton(
                    onPressed: () async {
                      try {
                        final draftTransaction =
                            await widget.ndk.cashu.initiateRedeem(
                          unit: "sat",
                          method: "bolt11",
                          request: "lnbc",
                          mintUrl: mintUrl,
                        );
                        final redeemStream = widget.ndk.cashu
                            .redeem(draftRedeemTransaction: draftTransaction);
                        await redeemStream.last;
                      } catch (e) {
                        displayError(e.toString());
                      }
                    },
                    child: const Text("melt"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text("NWC", style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                _showAddNwcWalletDialog(context);
              },
              child: const Text("Add New NWC Wallet"),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ));
  }

  void _showAddNwcWalletDialog(BuildContext context) {
    final _nwcUriController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New NWC Wallet'),
          content: TextField(
            controller: _nwcUriController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'NWC Connection URI',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final walletId =
                      DateTime.now().millisecondsSinceEpoch.toString();
                  final nwcWallet = NwcWallet(
                    id: walletId,
                    name:
                        "NWC Wallet ${DateTime.now().toString().split(' ')[1].substring(0, 5)}",
                    supportedUnits: {'sat'},
                    nwcUrl: _nwcUriController.text,
                  );
                  await widget.ndk.wallets.addWallet(nwcWallet);
                  Navigator.of(context).pop();
                } catch (e) {
                  displayError(e.toString());
                }
              },
              child: const Text('Add Wallet'),
            ),
          ],
        );
      },
    );
  }
}

class Balances extends StatelessWidget {
  final Ndk ndk;
  const Balances({super.key, required this.ndk});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: ndk.wallets.combinedBalances,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No balances available'));
          } else {
            final balances = snapshot.data!;
            return ListView.builder(
              itemCount: balances.length,
              itemBuilder: (context, index) {
                final balance = balances[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  child: ListTile(
                    dense: true,
                    title: Text('${balance.unit}: ${balance.amount}'),
                  ),
                );
              },
            );
          }
        });
  }
}

class Pending extends StatelessWidget {
  final Ndk ndk;
  const Pending({super.key, required this.ndk});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: ndk.wallets.combinedPendingTransactions,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No pending transactions'));
        } else {
          final transactions = snapshot.data!;
          return ListView.builder(
            reverse: true,
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 2),
                child: ListTile(
                  dense: true,
                  title: Text(
                      '${transaction.changeAmount} ${transaction.unit} type: ${transaction.walletType}'),
                  onTap: () {
                    if (transaction is CashuWalletTransaction) {
                      Clipboard.setData(
                          ClipboardData(text: transaction.token ?? ''));

                      // copy to clipboard
                      const snackBar = SnackBar(
                        content: Text('Copied to clipboard'),
                        duration: Duration(seconds: 1),
                      );

                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    }
                  },
                ),
              );
            },
          );
        }
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
            reverse: true,
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 2),
                child: ListTile(
                  dense: true,
                  title: Text(
                      '${transaction.changeAmount} ${transaction.unit} type: ${transaction.walletType}, state: ${transaction.state}'),
                ),
              );
            },
          );
        }
      },
    );
  }
}
