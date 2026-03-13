import 'dart:io' show Platform;

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ndk/entities.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

import '../../l10n/app_localizations.dart';

const String _defaultMintUrl = 'https://dev.mint.camelus.app';
const String _albyGoIntentHost = 'bla';

/// Configuration for launching the Alby Go NWC connection intent.
///
/// Provide raw (unencoded) values. They will be encoded for the intent URL.
class AlbyGoConnectConfig {
  final String appName;
  final String appIconUrl;
  final String callback;

  const AlbyGoConnectConfig({
    required this.appName,
    required this.appIconUrl,
    required this.callback,
  });
}

/// Default Alby Go parameters aligned with the sample app's NWC auth flow.
const AlbyGoConnectConfig kDefaultAlbyGoConnectConfig = AlbyGoConnectConfig(
  appName: 'NDK Demo',
  appIconUrl:
      'https://logowik.com/content/uploads/images/flutter5786.jpg',
  callback: 'ndk://nwc',
);

/// Shows a dialog to add a Cashu wallet.
///
/// Returns the created [CashuWallet] if successful, or null if cancelled.
Future<CashuWallet?> showAddCashuWalletDialog(
  BuildContext context,
  NdkFlutter ndkFlutter, {
  String defaultMintUrl = _defaultMintUrl,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final mintUrlController = TextEditingController(text: defaultMintUrl);

  return showDialog<CashuWallet?>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(l10n.addCashuWalletTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.enterMintUrl),
            const SizedBox(height: 16),
            TextField(
              controller: mintUrlController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.mintUrl,
                hintText: l10n.mintUrlHint,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final mintUrl = mintUrlController.text.trim();
              if (mintUrl.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.pleaseEnterMintUrl),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final scaffoldMessenger = ScaffoldMessenger.of(context);

              try {
                await ndkFlutter.ndk.cashu.addMintToKnownMints(
                  mintUrl: mintUrl,
                );
                final mintInfo = await ndkFlutter.ndk.cashu.getMintInfoNetwork(
                  mintUrl: mintUrl,
                );

                final cashuWallet = CashuWallet(
                  id: mintUrl,
                  name: mintInfo.name ?? mintUrl,
                  mintUrl: mintUrl,
                  mintInfo: mintInfo,
                  supportedUnits: mintInfo.supportedUnits,
                );

                await ndkFlutter.ndk.wallets.addWallet(cashuWallet);

                if (context.mounted) {
                  Navigator.of(context).pop(cashuWallet);
                }
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(l10n.cashuWalletAdded),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('${l10n.failedToAddMint}: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(l10n.add),
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
  NdkFlutter ndkFlutter, {
  int defaultBalance = 10000,
}) async {
  return showDialog<NwcWallet?>(
    context: context,
    builder: (context) {
      return _AddNwcWalletDialog(
        ndkFlutter: ndkFlutter,
        defaultBalance: defaultBalance,
      );
    },
  );
}

class _AddNwcWalletDialog extends StatefulWidget {
  final NdkFlutter ndkFlutter;
  final int defaultBalance;

  const _AddNwcWalletDialog({
    required this.ndkFlutter,
    required this.defaultBalance,
  });

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
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.addNwcWalletTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: l10n.faucet),
                Tab(text: l10n.manual),
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
                        Text(
                          l10n.nwcFaucetDescription,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: balanceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: '${l10n.startingBalance} (sats)',
                            hintText: l10n.startingBalanceHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Manual Tab
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: nwcUriController,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: l10n.nwcConnectionUri,
                            hintText: l10n.nwcConnectionUriHint,
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () async {
                                    final clipboardData =
                                        await Clipboard.getData(
                                          Clipboard.kTextPlain,
                                        );
                                    if (clipboardData?.text != null) {
                                      nwcUriController.text =
                                          clipboardData!.text!;
                                    }
                                  },
                                  icon: const Icon(Icons.paste),
                                  tooltip: l10n.copy,
                                ),
                                if (!kIsWeb &&
                                    (Platform.isAndroid || Platform.isIOS))
                                  IconButton(
                                    onPressed: () async {
                                      final scannedUri =
                                          await showDialog<String>(
                                            context: context,
                                            builder: (context) =>
                                                const _NwcQrScannerDialog(),
                                          );
                                      if (scannedUri != null) {
                                        nwcUriController.text = scannedUri;
                                      }
                                    },
                                    icon: const Icon(Icons.qr_code_scanner),
                                    tooltip: l10n.copy,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
          child: Text(l10n.cancel),
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
                          await widget.ndkFlutter.ndk.wallets.addWallet(
                            nwcWallet,
                          );

                          if (!mounted) return;
                          navigator.pop(nwcWallet);
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(l10n.nwcFaucetWalletAdded(balance)),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(l10n.invalidFaucetResponse),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } else {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              '${l10n.errorCreatingWallet}: ${response.statusCode}',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('${l10n.errorCreatingWallet}: $e'),
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
                        name: 'NWC',
                        supportedUnits: {'sat'},
                        nwcUrl: nwcUriController.text,
                      );
                      await widget.ndkFlutter.ndk.wallets.addWallet(nwcWallet);

                      if (!mounted) return;
                      navigator.pop(nwcWallet);
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(l10n.nwcWalletAdded),
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
              : Text(l10n.add),
        ),
      ],
    );
  }
}

/// Shows a dialog to add an LNURL wallet.
///
/// Returns the created [Wallet] if successful, or null if cancelled.
Future<Wallet?> showAddLnurlWalletDialog(
  BuildContext context,
  NdkFlutter ndkFlutter,
) async {
  final l10n = AppLocalizations.of(context)!;
  final identifierController = TextEditingController();

  // Check if user is logged in and has lud16 in their profile
  String? profileLud16;
  if (ndkFlutter.ndk.accounts.isLoggedIn) {
    final pubkey = ndkFlutter.ndk.accounts.getPublicKey();
    if (pubkey != null) {
      try {
        final metadata = await ndkFlutter.ndk.metadata.loadMetadata(pubkey);
        profileLud16 = metadata?.lud16;
      } catch (e) {
        // Ignore errors loading metadata
      }
    }
  }

  if (!context.mounted) return null;

  return showDialog<Wallet?>(
    context: context,
    builder: (context) {
      return _AddLnurlWalletDialog(
        l10n: l10n,
        identifierController: identifierController,
        profileLud16: profileLud16,
        ndkFlutter: ndkFlutter,
      );
    },
  );
}

class _AddLnurlWalletDialog extends StatefulWidget {
  final AppLocalizations l10n;
  final TextEditingController identifierController;
  final String? profileLud16;
  final NdkFlutter ndkFlutter;

  const _AddLnurlWalletDialog({
    required this.l10n,
    required this.identifierController,
    required this.profileLud16,
    required this.ndkFlutter,
  });

  @override
  State<_AddLnurlWalletDialog> createState() => _AddLnurlWalletDialogState();
}

class _AddLnurlWalletDialogState extends State<_AddLnurlWalletDialog> {
  Future<void> _addWalletWithIdentifier(String identifier) async {
    if (identifier.isEmpty || !identifier.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.l10n.pleaseEnterValidIdentifier),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final walletId = DateTime.now().millisecondsSinceEpoch.toString();
      final wallet = widget.ndkFlutter.ndk.wallets.createWallet(
        type: WalletType.LNURL,
        id: walletId,
        name: identifier,
        supportedUnits: {'sat'},
        metadata: {'identifier': identifier},
      );
      await widget.ndkFlutter.ndk.wallets.addWallet(wallet);

      if (!mounted) return;
      Navigator.of(context).pop(wallet);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(widget.l10n.lnurlWalletAdded),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _addManualWallet() async {
    final identifier = widget.identifierController.text.trim();
    await _addWalletWithIdentifier(identifier);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.l10n.addLnurlWalletTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.l10n.enterLnurlIdentifier),
          const SizedBox(height: 16),
          // Show profile lud16 option if available
          if (widget.profileLud16 != null &&
              widget.profileLud16!.isNotEmpty) ...[
            Card(
              child: ListTile(
                leading: NPicture(
                  ndkFlutter: widget.ndkFlutter,
                  circleAvatarRadius: 20,
                ),
                title: Text(widget.profileLud16!),
                subtitle: Text(widget.l10n.fromYourProfile),
                trailing: TextButton(
                  onPressed: () =>
                      _addWalletWithIdentifier(widget.profileLud16!),
                  child: Text(widget.l10n.add),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              widget.l10n.orEnterManually,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: widget.identifierController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: widget.l10n.lnurlIdentifierHint,
              hintText: widget.l10n.lnurlIdentifierHint,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.l10n.cancel),
        ),
        TextButton(onPressed: _addManualWallet, child: Text(widget.l10n.add)),
      ],
    );
  }
}

/// Shows a dialog to choose wallet type (Cashu, NWC, or LNURL).
///
/// Returns true if a wallet type was selected, false if cancelled.
/// Use [albyGoConnectConfig] to override Alby Go app metadata.
Future<bool> showAddWalletTypeDialog(
  BuildContext context,
  NdkFlutter ndkFlutter, {
  AlbyGoConnectConfig albyGoConnectConfig = kDefaultAlbyGoConnectConfig,
}) async {
  final l10n = AppLocalizations.of(context)!;

  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 24),
                    Expanded(
                      child: Text(
                        l10n.addWalletTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(dialogContext).pop(false),
                      child: const Icon(Icons.close, size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.chooseWalletType,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Grid of wallet type options
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    // Cashu option
                    _WalletTypeOptionButton(
                      imageAsset: 'assets/images/cashu.png',
                      label: l10n.cashuOption,
                      onTap: () async {
                        Navigator.of(dialogContext).pop(true);
                        await showAddCashuWalletDialog(context, ndkFlutter);
                      },
                    ),
                    // NWC option
                    _WalletTypeOptionButton(
                      imageAsset: 'assets/images/nwc.png',
                      label: l10n.nwcOption,
                      onTap: () async {
                        Navigator.of(dialogContext).pop(true);
                        await showNwcConnectionOptionsDialog(
                          context,
                          ndkFlutter,
                          albyGoConnectConfig: albyGoConnectConfig,
                        );
                      },
                    ),
                    // LNURL option
                    _WalletTypeOptionButton(
                      icon: Icons.bolt,
                      label: l10n.lnurlOption,
                      onTap: () async {
                        Navigator.of(dialogContext).pop(true);
                        await showAddLnurlWalletDialog(context, ndkFlutter);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ) ??
      false;
}

/// Shows a dialog to choose NWC connection method.
///
/// Returns true if a connection method was selected, false if cancelled.
/// Use [albyGoConnectConfig] to override Alby Go app metadata.
Future<bool> showNwcConnectionOptionsDialog(
  BuildContext context,
  NdkFlutter ndkFlutter, {
  AlbyGoConnectConfig albyGoConnectConfig = kDefaultAlbyGoConnectConfig,
}) async {
  final l10n = AppLocalizations.of(context)!;

  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 24),
                    Expanded(
                      child: Text(
                        l10n.connectNwcTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(dialogContext).pop(false),
                      child: const Icon(Icons.close, size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.chooseNwcMethod,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Grid of connection options
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    // Alby Go button (only on Android, not web)
                    if (!kIsWeb && Platform.isAndroid)
                      _WalletTypeOptionButton(
                        imageAsset: 'assets/images/albygo.png',
                        label: l10n.albyGoOption,
                        onTap: () async {
                          Navigator.of(dialogContext).pop(true);
                          await _connectAlbyGo(
                            context,
                            albyGoConnectConfig,
                          );
                        },
                      ),
                    // Manual connection button (goes directly to QR scanner)
                    _WalletTypeOptionButton(
                      icon: Icons.qr_code_scanner,
                      label: l10n.manualOption,
                      onTap: () async {
                        Navigator.of(dialogContext).pop(true);
                        await _showNwcScannerAndAddWallet(context, ndkFlutter);
                      },
                    ),
                    // Faucet button (only in debug mode)
                    if (kDebugMode)
                      _WalletTypeOptionButton(
                        icon: Icons.water_drop,
                        label: l10n.faucetOption,
                        onTap: () async {
                          Navigator.of(dialogContext).pop(true);
                          await _showNwcFaucetDialog(context, ndkFlutter);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ) ??
      false;
}

/// A styled button for wallet type options
class _WalletTypeOptionButton extends StatelessWidget {
  final IconData? icon;
  final String? imageAsset;
  final String label;
  final VoidCallback onTap;
  final double iconSize;

  const _WalletTypeOptionButton({
    this.icon,
    this.imageAsset,
    required this.label,
    required this.onTap,
    this.iconSize = 40,
  }) : assert(
         icon != null || imageAsset != null,
         'Either icon or imageAsset must be provided',
       );

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: imageAsset != null
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Image.asset(
                      imageAsset!,
                      package: 'ndk_flutter',
                      fit: BoxFit.contain,
                    ),
                  )
                : Icon(
                    icon!,
                    size: iconSize,
                    color: Theme.of(context).colorScheme.primary,
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Launches the Alby Go app via Android intent
Future<void> _connectAlbyGo(
  BuildContext context,
  AlbyGoConnectConfig config,
) async {
  if (kIsWeb || !Platform.isAndroid) return;

  final appName = _encodeComponentIfNeeded(config.appName);
  final appIcon = _encodeComponentIfNeeded(config.appIconUrl);
  final callback = _encodeComponentIfNeeded(config.callback);
  final data =
      'nostrnwc://$_albyGoIntentHost?appname=$appName&appicon=$appIcon&callback=$callback';
  final intent = AndroidIntent(action: 'action_view', data: data);

  try {
    await intent.launch();
  } catch (e) {
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.error(e.toString())),
        backgroundColor: Colors.red,
      ),
    );
  }
}

String _encodeComponentIfNeeded(String value) {
  try {
    final decoded = Uri.decodeComponent(value);
    if (decoded != value) {
      return value;
    }
  } catch (_) {
    // If it's not valid percent-encoding, encode it.
  }
  return Uri.encodeComponent(value);
}

/// Shows QR scanner dialog and then adds the wallet directly
Future<void> _showNwcScannerAndAddWallet(
  BuildContext context,
  NdkFlutter ndkFlutter,
) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await showDialog<String?>(
    context: context,
    builder: (context) => _NwcQrScannerDialogWithPaste(),
  );

  if (result == null || result.isEmpty || !context.mounted) return;

  final scaffoldMessenger = ScaffoldMessenger.of(context);

  try {
    final walletId = DateTime.now().millisecondsSinceEpoch.toString();
    final nwcWallet = NwcWallet(
      id: walletId,
      name: 'NWC',
      supportedUnits: {'sat'},
      nwcUrl: result,
    );
    await ndkFlutter.ndk.wallets.addWallet(nwcWallet);

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(l10n.nwcWalletAdded),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
    );
  }
}

/// A dialog for scanning NWC QR codes.
class _NwcQrScannerDialog extends StatefulWidget {
  const _NwcQrScannerDialog();

  @override
  State<_NwcQrScannerDialog> createState() => _NwcQrScannerDialogState();
}

class _NwcQrScannerDialogState extends State<_NwcQrScannerDialog> {
  MobileScannerController? _scannerController;
  bool _hasScanned = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
      );
    }
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_hasScanned) return;

    final l10n = AppLocalizations.of(context)!;
    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.startsWith('nostr+walletconnect://')) {
        setState(() => _hasScanned = true);
        Navigator.of(context).pop(rawValue);
        return;
      } else if (rawValue != null) {
        setState(() {
          _errorMessage = l10n.invalidNwcQrCode;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: Colors.black,
      child: SizedBox(
        width: 400,
        height: 500,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.scanNwcQrCodeTitle,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Scanner
            Expanded(
              child: Stack(
                children: [
                  if (_scannerController != null)
                    MobileScanner(
                      controller: _scannerController!,
                      onDetect: _onBarcodeDetected,
                    )
                  else
                    Center(
                      child: Text(
                        l10n.cameraNotAvailable,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),

                  // Scan overlay
                  if (_scannerController != null)
                    Center(
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                  // Error message
                  if (_errorMessage != null)
                    Positioned(
                      top: 20,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                  // Scanning indicator
                  if (_hasScanned)
                    Container(
                      color: Colors.black.withValues(alpha: 0.7),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.scanNwcInstructions,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A dialog for scanning NWC QR codes with paste from clipboard option.
class _NwcQrScannerDialogWithPaste extends StatefulWidget {
  const _NwcQrScannerDialogWithPaste();

  @override
  State<_NwcQrScannerDialogWithPaste> createState() =>
      _NwcQrScannerDialogWithPasteState();
}

class _NwcQrScannerDialogWithPasteState
    extends State<_NwcQrScannerDialogWithPaste> {
  MobileScannerController? _scannerController;
  bool _hasScanned = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
      );
    }
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_hasScanned) return;

    final l10n = AppLocalizations.of(context)!;
    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.startsWith('nostr+walletconnect://')) {
        setState(() => _hasScanned = true);
        Navigator.of(context).pop(rawValue);
        return;
      } else if (rawValue != null) {
        setState(() {
          _errorMessage = l10n.invalidNwcQrCode;
        });
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    final l10n = AppLocalizations.of(context)!;
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipboardData?.text?.trim();

    if (text != null && text.startsWith('nostr+walletconnect://')) {
      if (mounted) {
        Navigator.of(context).pop(text);
      }
    } else {
      setState(() {
        _errorMessage = l10n.invalidNwcUri;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bool hasCamera = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    return Dialog(
      backgroundColor: Colors.black,
      child: SizedBox(
        width: 400,
        height: hasCamera ? 560 : 200,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.scanNwcQrCodeTitle,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Scanner (only on mobile)
            if (hasCamera)
              Expanded(
                child: Stack(
                  children: [
                    MobileScanner(
                      controller: _scannerController!,
                      onDetect: _onBarcodeDetected,
                    ),

                    // Scan overlay
                    Center(
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    // Error message
                    if (_errorMessage != null)
                      Positioned(
                        top: 20,
                        left: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                    // Scanning indicator
                    if (_hasScanned)
                      Container(
                        color: Colors.black.withValues(alpha: 0.7),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              )
            else
              Expanded(
                child: Center(
                  child: Text(
                    l10n.cameraNotAvailable,
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // Instructions or paste button area
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasCamera)
                    Text(
                      l10n.scanNwcInstructions,
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  if (hasCamera) const SizedBox(height: 12),
                  // Paste from clipboard button
                  ElevatedButton.icon(
                    onPressed: _pasteFromClipboard,
                    icon: const Icon(Icons.paste),
                    label: Text(l10n.paste),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a dialog to add an NWC wallet via faucet.
Future<void> _showNwcFaucetDialog(
  BuildContext context,
  NdkFlutter ndkFlutter,
) async {
  final l10n = AppLocalizations.of(context)!;
  final balanceController = TextEditingController(text: '10000');

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(l10n.faucetOption),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.nwcFaucetDescription),
            const SizedBox(height: 16),
            TextField(
              controller: balanceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.startingBalance,
                hintText: l10n.startingBalanceHint,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);

              try {
                final balance = int.tryParse(balanceController.text) ?? 10000;
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
                    await ndkFlutter.ndk.wallets.addWallet(nwcWallet);

                    if (context.mounted) {
                      navigator.pop();
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(l10n.nwcFaucetWalletAdded(balance)),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(l10n.invalidFaucetResponse),
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
                    content: Text('${l10n.errorCreatingWallet}: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(l10n.add),
          ),
        ],
      );
    },
  );
}
