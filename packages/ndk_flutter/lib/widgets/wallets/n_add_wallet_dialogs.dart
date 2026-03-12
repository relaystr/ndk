import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';

const String _defaultMintUrl = 'https://dev.mint.camelus.app';

/// Shows a dialog to add a Cashu wallet.
///
/// Returns the created [CashuWallet] if successful, or null if cancelled.
Future<CashuWallet?> showAddCashuWalletDialog(
  BuildContext context,
  Ndk ndk, {
  String defaultMintUrl = _defaultMintUrl,
}) async {
  final mintUrlController = TextEditingController(text: defaultMintUrl);

  return showDialog<CashuWallet?>(
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
              controller: mintUrlController,
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
              final mintUrl = mintUrlController.text.trim();
              if (mintUrl.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a mint URL'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final scaffoldMessenger = ScaffoldMessenger.of(context);

              try {
                await ndk.cashu.addMintToKnownMints(mintUrl: mintUrl);
                final mintInfo = await ndk.cashu.getMintInfoNetwork(
                  mintUrl: mintUrl,
                );

                final cashuWallet = CashuWallet(
                  id: mintUrl,
                  name: mintInfo.name ?? mintUrl,
                  mintUrl: mintUrl,
                  mintInfo: mintInfo,
                  supportedUnits: mintInfo.supportedUnits,
                );

                await ndk.wallets.addWallet(cashuWallet);

                if (context.mounted) {
                  Navigator.of(context).pop(cashuWallet);
                }
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Cashu wallet added!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to add mint: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      );
    },
  );
}

/// Shows a dialog to add an NWC wallet.
///
/// Returns the created [NwcWallet] if successful, or null if cancelled.
Future<NwcWallet?> showAddNwcWalletDialog(
  BuildContext context,
  Ndk ndk, {
  int defaultBalance = 10000,
}) async {
  return showDialog<NwcWallet?>(
    context: context,
    builder: (context) {
      return _AddNwcWalletDialog(ndk: ndk, defaultBalance: defaultBalance);
    },
  );
}

class _AddNwcWalletDialog extends StatefulWidget {
  final Ndk ndk;
  final int defaultBalance;

  const _AddNwcWalletDialog({required this.ndk, required this.defaultBalance});

  @override
  State<_AddNwcWalletDialog> createState() => _AddNwcWalletDialogState();
}

class _AddNwcWalletDialogState extends State<_AddNwcWalletDialog>
    with SingleTickerProviderStateMixin {
  final nwcUriController = TextEditingController();
  late final balanceController = TextEditingController(
    text: widget.defaultBalance.toString(),
  );
  late TabController _tabController;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    nwcUriController.dispose();
    balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add NWC Wallet'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Faucet'),
                Tab(text: 'Manual'),
              ],
            ),
            SizedBox(
              height: 150,
              child: TabBarView(
                controller: _tabController,
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
        TextButton(
          onPressed: isLoading
              ? null
              : () async {
                  final currentTab = _tabController.index;
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);

                  if (currentTab == 0) {
                    // Faucet tab
                    setState(() => isLoading = true);

                    try {
                      final balance =
                          int.tryParse(balanceController.text) ??
                          widget.defaultBalance;
                      final response = await http.post(
                        Uri.parse('https://faucet.nwc.dev?balance=$balance'),
                      );

                      if (response.statusCode == 200) {
                        final nwcUri = response.body.trim();

                        if (nwcUri.isNotEmpty) {
                          final walletId = DateTime.now().millisecondsSinceEpoch
                              .toString();
                          final nwcWallet = NwcWallet(
                            id: walletId,
                            name: 'NWC Faucet',
                            supportedUnits: {'sat'},
                            nwcUrl: nwcUri,
                          );
                          await widget.ndk.wallets.addWallet(nwcWallet);

                          if (!mounted) return;
                          navigator.pop(nwcWallet);
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'NWC faucet wallet added with $balance sats!',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text('Invalid response from faucet'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } else {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to create wallet: ${response.statusCode}',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('Error creating wallet: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } finally {
                      if (mounted) {
                        setState(() => isLoading = false);
                      }
                    }
                  } else {
                    // Manual tab
                    try {
                      final walletId = DateTime.now().millisecondsSinceEpoch
                          .toString();
                      final nwcWallet = NwcWallet(
                        id: walletId,
                        name:
                            'NWC ${DateTime.now().toString().split(' ')[1].substring(0, 5)}',
                        supportedUnits: {'sat'},
                        nwcUrl: nwcUriController.text,
                      );
                      await widget.ndk.wallets.addWallet(nwcWallet);

                      if (!mounted) return;
                      navigator.pop(nwcWallet);
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('NWC wallet added!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: Colors.red,
                        ),
                      );
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
        ),
      ],
    );
  }
}

/// Shows a dialog to add an LNURL wallet.
///
/// Returns the created [Wallet] if successful, or null if cancelled.
Future<Wallet?> showAddLnurlWalletDialog(BuildContext context, Ndk ndk) async {
  final identifierController = TextEditingController();

  return showDialog<Wallet?>(
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Please enter a valid identifier (user@domain.com)',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final scaffoldMessenger = ScaffoldMessenger.of(context);

              try {
                final walletId = DateTime.now().millisecondsSinceEpoch
                    .toString();
                final wallet = ndk.wallets.createWallet(
                  type: WalletType.LNURL,
                  id: walletId,
                  name: 'LNURL',
                  supportedUnits: {'sat'},
                  metadata: {'identifier': identifier},
                );
                await ndk.wallets.addWallet(wallet);

                if (context.mounted) {
                  Navigator.of(context).pop(wallet);
                }
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('LNURL wallet added!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      );
    },
  );
}
