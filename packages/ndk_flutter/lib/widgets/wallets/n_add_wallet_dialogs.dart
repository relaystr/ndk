import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/domain_layer/usecases/nwc/consts/nwc_kind.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:ndk_flutter/ndk_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';

const String _defaultMintUrl = 'https://mint.minibits.cash/Bitcoin';
const String _dialogBackResult = '__back__';
const List<NwcMethod> _defaultAlbyGoRequestMethods = [
  NwcMethod.GET_INFO,
  NwcMethod.GET_BALANCE,
  NwcMethod.GET_BUDGET,
  NwcMethod.MAKE_INVOICE,
  NwcMethod.PAY_INVOICE,
  NwcMethod.LOOKUP_INVOICE,
  NwcMethod.LIST_TRANSACTIONS,
  NwcMethod.SIGN_MESSAGE,
  NwcMethod.MAKE_HOLD_INVOICE,
  NwcMethod.CANCEL_HOLD_INVOICE,
  NwcMethod.SETTLE_HOLD_INVOICE,
];

/// Configuration for launching the Alby Go NWC connection intent.
///
/// Provide raw (unencoded) values. They will be encoded for the intent URL.
class AlbyGoConnectConfig {
  final String appName;
  final String appIconUrl;
  final String callback;
  final String discoveryRelay;
  final List<NwcMethod> requestMethods;
  final String walletName;

  const AlbyGoConnectConfig({
    required this.appName,
    required this.appIconUrl,
    required this.callback,
    this.discoveryRelay = 'wss://relay.getalby.com',
    this.requestMethods = _defaultAlbyGoRequestMethods,
    this.walletName = 'Alby Go',
  });
}

/// Default Alby Go parameters aligned with the sample app's NWC auth flow.
const AlbyGoConnectConfig kDefaultAlbyGoConnectConfig = AlbyGoConnectConfig(
  appName: 'NDK Demo',
  appIconUrl: 'https://logowik.com/content/uploads/images/flutter5786.jpg',
  callback: 'ndk://nwc',
);

class NwcWalletAuthCoordinator {
  _PendingNwcWalletAuthSession? _pendingSession;

  bool get hasPendingSession => _pendingSession != null;

  Future<void> connectAlbyGo(
    BuildContext context,
    NdkFlutter ndkFlutter, {
    AlbyGoConnectConfig config = kDefaultAlbyGoConnectConfig,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return;

    final appKey = Bip340.generatePrivateKey();
    final launchUri = Uri(
      scheme: 'nostr+walletauth',
      host: appKey.publicKey,
      queryParameters: {
        'relay': config.discoveryRelay,
        'name': config.appName,
        'request_methods': config.requestMethods
            .map((method) => method.name)
            .join(' '),
        'icon': config.appIconUrl,
        'return_to': config.callback,
      },
    );

    _pendingSession = _PendingNwcWalletAuthSession(
      appKey: appKey,
      discoveryRelay: config.discoveryRelay,
      returnTo: config.callback,
      walletName: config.walletName,
    );

    try {
      final launched = await launchUrl(
        launchUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw StateError('Could not launch wallet app');
      }
    } catch (e) {
      _pendingSession = null;
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

  Future<bool> processProtocolUrl(
    BuildContext context,
    NdkFlutter ndkFlutter,
    String url,
  ) async {
    final pendingSession = _pendingSession;
    if (pendingSession == null ||
        !_matchesReturnTo(url, pendingSession.returnTo)) {
      return false;
    }

    _pendingSession = null;

    if (!context.mounted) return true;
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: const Text(
          'Wallet callback received. Fetching connection info...',
        ),
      ),
    );

    try {
      final stream = ndkFlutter.ndk.requests
          .query(
            filter: Filter(
              kinds: [NwcKind.INFO.value],
              pTags: [pendingSession.appKey.publicKey],
              limit: 1,
            ),
            explicitRelays: {pendingSession.discoveryRelay},
          )
          .stream
          .timeout(const Duration(seconds: 15));

      final Nip01Event foundWalletAuthEvent = await stream.first;
      final appPrivateKey = pendingSession.appKey.privateKey;

      if (appPrivateKey == null) {
        throw StateError(
          'Generated wallet auth keypair is missing a private key',
        );
      }

      final constructedNwcUri =
          'nostr+walletconnect://${foundWalletAuthEvent.pubKey}?relay=${Uri.encodeComponent(pendingSession.discoveryRelay)}&secret=$appPrivateKey';

      final walletId = DateTime.now().millisecondsSinceEpoch.toString();
      final nwcWallet = NwcWallet(
        id: walletId,
        name: pendingSession.walletName,
        supportedUnits: {'sat'},
        nwcUrl: constructedNwcUri,
      );

      await ndkFlutter.ndk.wallets.addWallet(nwcWallet);

      if (!context.mounted) return true;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(l10n.nwcWalletAdded),
          backgroundColor: Colors.green,
        ),
      );
      return true;
    } on TimeoutException {
      if (!context.mounted) return true;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.error(
              'Timed out while waiting for wallet connection info from ${pendingSession.discoveryRelay}',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return true;
    } catch (e) {
      if (!context.mounted) return true;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(l10n.error(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
      return true;
    }
  }
}

class _PendingNwcWalletAuthSession {
  final KeyPair appKey;
  final String discoveryRelay;
  final String returnTo;
  final String walletName;

  const _PendingNwcWalletAuthSession({
    required this.appKey,
    required this.discoveryRelay,
    required this.returnTo,
    required this.walletName,
  });
}

/// Shows a dialog to add a Cashu wallet.
///
/// Returns the created [CashuWallet] if successful, or null if cancelled.
Future<CashuWallet?> showAddCashuWalletDialog(
  BuildContext context,
  NdkFlutter ndkFlutter, {
  String defaultMintUrl = _defaultMintUrl,
  bool returnToWalletType = false,
  AlbyGoConnectConfig albyGoConnectConfig = kDefaultAlbyGoConnectConfig,
  NwcWalletAuthCoordinator? nwcWalletAuthCoordinator,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final mintUrlController = TextEditingController(text: defaultMintUrl);

  return showDialog<CashuWallet?>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Row(
          children: [
            IconButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                if (returnToWalletType && context.mounted) {
                  await showAddWalletTypeDialog(
                    context,
                    ndkFlutter,
                    albyGoConnectConfig: albyGoConnectConfig,
                    nwcWalletAuthCoordinator: nwcWalletAuthCoordinator,
                  );
                }
              },
              icon: const Icon(Icons.arrow_back),
            ),
            Expanded(child: Text(l10n.addCashuWalletTitle)),
            IconButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
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
            onPressed: () => Navigator.of(dialogContext).pop(),
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
      title: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(child: Text(l10n.addNwcWalletTitle)),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
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
  NdkFlutter ndkFlutter, {
  bool returnToWalletType = false,
  AlbyGoConnectConfig albyGoConnectConfig = kDefaultAlbyGoConnectConfig,
  NwcWalletAuthCoordinator? nwcWalletAuthCoordinator,
}) async {
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
    builder: (dialogContext) {
      return _AddLnurlWalletDialog(
        l10n: l10n,
        identifierController: identifierController,
        profileLud16: profileLud16,
        ndkFlutter: ndkFlutter,
        parentContext: context,
        returnToWalletType: returnToWalletType,
        albyGoConnectConfig: albyGoConnectConfig,
        nwcWalletAuthCoordinator: nwcWalletAuthCoordinator,
      );
    },
  );
}

class _AddLnurlWalletDialog extends StatefulWidget {
  final AppLocalizations l10n;
  final TextEditingController identifierController;
  final String? profileLud16;
  final NdkFlutter ndkFlutter;
  final BuildContext parentContext;
  final bool returnToWalletType;
  final AlbyGoConnectConfig albyGoConnectConfig;
  final NwcWalletAuthCoordinator? nwcWalletAuthCoordinator;

  const _AddLnurlWalletDialog({
    required this.l10n,
    required this.identifierController,
    required this.profileLud16,
    required this.ndkFlutter,
    required this.parentContext,
    required this.returnToWalletType,
    required this.albyGoConnectConfig,
    required this.nwcWalletAuthCoordinator,
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
      title: Row(
        children: [
          IconButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (widget.returnToWalletType && widget.parentContext.mounted) {
                await showAddWalletTypeDialog(
                  widget.parentContext,
                  widget.ndkFlutter,
                  albyGoConnectConfig: widget.albyGoConnectConfig,
                  nwcWalletAuthCoordinator: widget.nwcWalletAuthCoordinator,
                );
              }
            },
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(child: Text(widget.l10n.addLnurlWalletTitle)),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
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
  NwcWalletAuthCoordinator? nwcWalletAuthCoordinator,
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
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _WalletTypeListOption(
                      imageAsset: 'assets/images/nwc.png',
                      title: l10n.nwcWalletTypeTitle,
                      subtitle: l10n.nwcWalletTypeSubtitle,
                      infoUrl: 'https://nwc.dev/',
                      onTap: () async {
                        Navigator.of(dialogContext).pop(true);
                        await showNwcConnectionOptionsDialog(
                          context,
                          ndkFlutter,
                          albyGoConnectConfig: albyGoConnectConfig,
                          nwcWalletAuthCoordinator: nwcWalletAuthCoordinator,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _WalletTypeListOption(
                      icon: Icons.bolt,
                      title: l10n.lnurlWalletTypeTitle,
                      subtitle: l10n.lnurlWalletTypeSubtitle,
                      infoUrl: 'https://lightningaddress.com/',
                      onTap: () async {
                        Navigator.of(dialogContext).pop(true);
                        await showAddLnurlWalletDialog(
                          context,
                          ndkFlutter,
                          returnToWalletType: true,
                          albyGoConnectConfig: albyGoConnectConfig,
                          nwcWalletAuthCoordinator: nwcWalletAuthCoordinator,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _WalletTypeListOption(
                      imageAsset: 'assets/images/cashu.png',
                      title: l10n.cashuWalletTypeTitle,
                      subtitle: l10n.cashuWalletTypeSubtitle,
                      infoUrl: 'https://cashu.space/',
                      onTap: () async {
                        Navigator.of(dialogContext).pop(true);
                        await showAddCashuWalletDialog(
                          context,
                          ndkFlutter,
                          returnToWalletType: true,
                          albyGoConnectConfig: albyGoConnectConfig,
                          nwcWalletAuthCoordinator: nwcWalletAuthCoordinator,
                        );
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
  NwcWalletAuthCoordinator? nwcWalletAuthCoordinator,
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
                    IconButton(
                      onPressed: () async {
                        Navigator.of(dialogContext).pop(false);
                        if (context.mounted) {
                          await showAddWalletTypeDialog(
                            context,
                            ndkFlutter,
                            albyGoConnectConfig: albyGoConnectConfig,
                            nwcWalletAuthCoordinator: nwcWalletAuthCoordinator,
                          );
                        }
                      },
                      icon: const Icon(Icons.arrow_back),
                    ),
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
                          await (nwcWalletAuthCoordinator ??
                                  NwcWalletAuthCoordinator())
                              .connectAlbyGo(
                                context,
                                ndkFlutter,
                                config: albyGoConnectConfig,
                              );
                        },
                      ),
                    // Manual connection button (goes directly to QR scanner)
                    _WalletTypeOptionButton(
                      icon: Icons.qr_code_scanner,
                      label: l10n.manualOption,
                      onTap: () async {
                        Navigator.of(dialogContext).pop(true);
                        await _showNwcScannerAndAddWallet(
                          context,
                          ndkFlutter,
                          returnToNwcOptions: true,
                          albyGoConnectConfig: albyGoConnectConfig,
                          nwcWalletAuthCoordinator: nwcWalletAuthCoordinator,
                        );
                      },
                    ),
                    // Faucet button (only in debug mode)
                    if (kDebugMode)
                      _WalletTypeOptionButton(
                        icon: Icons.water_drop,
                        label: l10n.faucetOption,
                        onTap: () async {
                          Navigator.of(dialogContext).pop(true);
                          await _showNwcFaucetDialog(
                            context,
                            ndkFlutter,
                            returnToNwcOptions: true,
                            albyGoConnectConfig: albyGoConnectConfig,
                            nwcWalletAuthCoordinator: nwcWalletAuthCoordinator,
                          );
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

  const _WalletTypeOptionButton({
    this.icon,
    this.imageAsset,
    required this.label,
    required this.onTap,
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
                    size: 40,
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

class _WalletTypeListOption extends StatelessWidget {
  final IconData? icon;
  final String? imageAsset;
  final String title;
  final String subtitle;
  final String infoUrl;
  final VoidCallback onTap;

  const _WalletTypeListOption({
    this.icon,
    this.imageAsset,
    required this.title,
    required this.subtitle,
    required this.infoUrl,
    required this.onTap,
  }) : assert(
         icon != null || imageAsset != null,
         'Either icon or imageAsset must be provided',
       );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: imageAsset != null
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          imageAsset!,
                          package: 'ndk_flutter',
                          fit: BoxFit.contain,
                        ),
                      )
                    : Icon(
                        icon!,
                        size: 38,
                        color: Theme.of(context).colorScheme.primary,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    InkWell(
                      onTap: () => _launchExternalLink(context, infoUrl),
                      child: Text(
                        infoUrl,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _launchExternalLink(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;

  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (launched || !context.mounted) return;

  final l10n = AppLocalizations.of(context)!;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(l10n.error('Could not open $url')),
      backgroundColor: Colors.red,
    ),
  );
}

bool _matchesReturnTo(String receivedUrl, String expectedReturnTo) {
  if (receivedUrl == expectedReturnTo ||
      receivedUrl.startsWith('$expectedReturnTo?')) {
    return true;
  }

  final receivedUri = Uri.tryParse(receivedUrl);
  final expectedUri = Uri.tryParse(expectedReturnTo);
  if (receivedUri == null || expectedUri == null) return false;

  return receivedUri.scheme == expectedUri.scheme &&
      receivedUri.host == expectedUri.host &&
      receivedUri.path == expectedUri.path;
}

/// Shows QR scanner dialog and then adds the wallet directly
Future<void> _showNwcScannerAndAddWallet(
  BuildContext context,
  NdkFlutter ndkFlutter, {
  bool returnToNwcOptions = false,
  AlbyGoConnectConfig albyGoConnectConfig = kDefaultAlbyGoConnectConfig,
  NwcWalletAuthCoordinator? nwcWalletAuthCoordinator,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await showDialog<String?>(
    context: context,
    builder: (context) => const _NwcQrScannerDialogWithPaste(),
  );

  if (result == _dialogBackResult) {
    if (returnToNwcOptions && context.mounted) {
      await showNwcConnectionOptionsDialog(
        context,
        ndkFlutter,
        albyGoConnectConfig: albyGoConnectConfig,
        nwcWalletAuthCoordinator: nwcWalletAuthCoordinator,
      );
    }
    return;
  }

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
                  IconButton(
                    onPressed: () =>
                        Navigator.of(context).pop(_dialogBackResult),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
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
                  IconButton(
                    onPressed: () =>
                        Navigator.of(context).pop(_dialogBackResult),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
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
  NdkFlutter ndkFlutter, {
  bool returnToNwcOptions = false,
  AlbyGoConnectConfig albyGoConnectConfig = kDefaultAlbyGoConnectConfig,
  NwcWalletAuthCoordinator? nwcWalletAuthCoordinator,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final parentContext = context;
  final balanceController = TextEditingController(text: '10000');

  await showDialog(
    context: parentContext,
    builder: (dialogContext) {
      return AlertDialog(
        title: Row(
          children: [
            IconButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                if (returnToNwcOptions && parentContext.mounted) {
                  await showNwcConnectionOptionsDialog(
                    parentContext,
                    ndkFlutter,
                    albyGoConnectConfig: albyGoConnectConfig,
                    nwcWalletAuthCoordinator: nwcWalletAuthCoordinator,
                  );
                }
              },
              icon: const Icon(Icons.arrow_back),
            ),
            Expanded(child: Text(l10n.faucetOption)),
            IconButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
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
            onPressed: () => Navigator.of(dialogContext).pop(),
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
