import 'package:flutter/material.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

import '../../l10n/app_localizations.dart';

/// Configuration for wallet type icons
class WalletIconConfig {
  /// Widget to display as the main icon (e.g., in the top left)
  final Widget? iconWidget;

  /// Widget to display as the background decoration
  /// If null, the iconWidget will be used with reduced opacity
  final Widget? backgroundWidget;

  /// Size of the main icon
  final double iconSize;

  /// Size of the background decoration
  final double backgroundSize;

  /// Opacity of the background decoration (0.0 - 1.0)
  final double backgroundOpacity;

  const WalletIconConfig({
    this.iconWidget,
    this.backgroundWidget,
    this.iconSize = 32,
    this.backgroundSize = 120,
    this.backgroundOpacity = 0.12,
  });
}

/// Individual wallet card widget used by the wallets UI.
class NWalletCard extends StatefulWidget {
  final Wallet wallet;
  final NdkFlutter ndkFlutter;
  final bool isSelected;
  final bool isDefaultForReceiving;
  final bool isDefaultForSending;
  final VoidCallback onTap;
  final VoidCallback? onDefaultWalletChanged;
  final Future<void> Function(BuildContext context, Wallet wallet)? onDelete;
  final bool showBudgetRenewalDays;

  /// Width of the card. Defaults to 280.
  final double width;

  /// Custom icon configuration for Cashu wallets
  final WalletIconConfig? cashuIcon;

  /// Custom icon configuration for NWC wallets
  final WalletIconConfig? nwcIcon;

  /// Custom icon configuration for LNURL wallets
  final WalletIconConfig? lnurlIcon;

  const NWalletCard({
    super.key,
    required this.wallet,
    required this.ndkFlutter,
    required this.isSelected,
    this.isDefaultForReceiving = false,
    this.isDefaultForSending = false,
    required this.onTap,
    this.onDefaultWalletChanged,
    this.onDelete,
    this.width = 280,
    this.showBudgetRenewalDays = false,
    this.cashuIcon,
    this.nwcIcon,
    this.lnurlIcon,
  });

  @override
  State<NWalletCard> createState() => _NWalletCardState();
}

class _NWalletCardState extends State<NWalletCard> {
  List<Color>? _customGradientColors;
  GetBudgetResponse? _budgetResponse;
  bool _isFetchingBudget = false;

  @override
  void initState() {
    super.initState();
    _loadCustomColor();
    _initializeNwcBalanceIfNeeded();
    _fetchBudgetIfNeeded();
  }

  void _initializeNwcBalanceIfNeeded() {
    if (widget.wallet is! NwcWallet) return;
    try {
      widget.ndkFlutter.ndk.wallets.getBalance(widget.wallet.id, 'sat');
    } catch (_) {
      // Keep initialization best-effort.
    }
  }

  void _fetchBudgetIfNeeded() {
    if (widget.wallet is NwcWallet) {
      _fetchBudgetWhenReady();
    }
  }

  Future<void> _fetchBudgetWhenReady() async {
    if (widget.wallet is! NwcWallet) return;
    if (_isFetchingBudget) return;
    _isFetchingBudget = true;

    final nwcWallet = widget.wallet as NwcWallet;

    try {
      // Ensure NWC wallet balance stream is initialized.
      _initializeNwcBalanceIfNeeded();

      // Use the balance stream to detect when wallet is fully initialized.
      await for (final _
          in widget.ndkFlutter.ndk.wallets
              .getBalancesStream(nwcWallet.id)
              .take(1)
              .timeout(const Duration(seconds: 10))) {
        break;
      }

      final connection = nwcWallet.connection;
      if (connection == null || connection.permissions.isEmpty) {
        if (mounted) {
          setState(() {
            _budgetResponse = null;
          });
        }
        return;
      }

      // Check if get_budget permission is available
      if (!connection.permissions.contains(NwcMethod.GET_BUDGET.name)) {
        if (mounted) {
          setState(() {
            _budgetResponse = null;
          });
        }
        return;
      }

      final budget = await widget.ndkFlutter.ndk.nwc.getBudget(connection);

      if (mounted) {
        setState(() {
          _budgetResponse = budget;
        });
      }
    } finally {
      _isFetchingBudget = false;
    }
  }

  void _loadCustomColor() {
    final customColorValue = widget.wallet.metadata['cardColor'] as int?;
    if (customColorValue != null) {
      final color = Color(customColorValue);
      final hsl = HSLColor.fromColor(color);
      final lighterColor = hsl
          .withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0))
          .toColor();
      _customGradientColors = [color, lighterColor];
    } else {
      _customGradientColors = null;
    }
  }

  @override
  void didUpdateWidget(NWalletCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload color when wallet changes or is updated
    if (oldWidget.wallet.id != widget.wallet.id ||
        oldWidget.wallet.metadata['cardColor'] !=
            widget.wallet.metadata['cardColor']) {
      setState(() {
        _loadCustomColor();
      });
    }
    final isCurrentNwc = widget.wallet is NwcWallet;
    final isOldNwc = oldWidget.wallet is NwcWallet;
    final walletIdChanged = oldWidget.wallet.id != widget.wallet.id;

    if (isCurrentNwc) {
      _initializeNwcBalanceIfNeeded();
    }

    // Refresh budget when switching wallet OR when NWC connection/permissions changed.
    if (isCurrentNwc) {
      bool shouldRefreshBudget = walletIdChanged || !isOldNwc;

      if (!shouldRefreshBudget && isOldNwc) {
        final oldNwc = oldWidget.wallet as NwcWallet;
        final newNwc = widget.wallet as NwcWallet;
        final oldConnection = oldNwc.connection;
        final newConnection = newNwc.connection;

        final oldPermissions = oldConnection?.permissions.toSet() ?? <String>{};
        final newPermissions = newConnection?.permissions.toSet() ?? <String>{};

        final connectionChanged = oldConnection?.uri != newConnection?.uri;

        final permissionsChanged = oldPermissions.length != newPermissions.length ||
            oldPermissions.difference(newPermissions).isNotEmpty ||
            newPermissions.difference(oldPermissions).isNotEmpty;

        shouldRefreshBudget = connectionChanged || permissionsChanged;
      }

      if (shouldRefreshBudget) {
        _fetchBudgetWhenReady();
      }
    } else if (isOldNwc && !isCurrentNwc) {
      // Switched away from NWC wallet; clear stale budget state.
      if (_budgetResponse != null) {
        setState(() {
          _budgetResponse = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bool isCashu = widget.wallet is CashuWallet;
    final bool isNwc = widget.wallet is NwcWallet;
    final bool isLnurl = widget.wallet is LnurlWallet;
    final bool canShowNwcBalance =
        !isNwc ||
        ((widget.wallet as NwcWallet).connection?.permissions.contains(
              NwcMethod.GET_BALANCE.name,
            ) ??
            false);
    final bool showBudgetInfo = isNwc && _shouldShowBudgetInfo();
    final bool isNwcReceiveOnly =
        isNwc && widget.wallet.canReceive && !widget.wallet.canSend;

    final String walletName;
    if (isCashu) {
      final cashuWallet = widget.wallet as CashuWallet;
      // Use custom wallet.name if set, otherwise fall back to mint name
      walletName = cashuWallet.name.isNotEmpty
          ? cashuWallet.name
          : (cashuWallet.mintInfo.name ?? l10n.cashuWallet);
    } else if (isNwc) {
      walletName = (widget.wallet as NwcWallet).name;
    } else if (isLnurl) {
      walletName = (widget.wallet as LnurlWallet).name;
    } else {
      walletName = l10n.unknownWalletType;
    }

    final String subtitle;
    if (isCashu) {
      subtitle = (widget.wallet as CashuWallet).mintUrl.replaceAll(
        'https://',
        '',
      );
    } else if (isNwc) {
      subtitle = l10n.nwcWalletSubtitle;
    } else if (isLnurl) {
      final lnurlWallet = widget.wallet as LnurlWallet;
      subtitle = lnurlWallet.identifier == lnurlWallet.name
          ? ''
          : lnurlWallet.identifier;
    } else {
      subtitle = '';
    }
    final bool showSubtitle = !isNwc && subtitle.isNotEmpty;

    // Use custom gradient if set (immediate UI update), otherwise load from metadata
    final List<Color> gradientColors;
    if (_customGradientColors != null) {
      gradientColors = _customGradientColors!;
    } else {
      final customColorValue = widget.wallet.metadata['cardColor'] as int?;
      if (customColorValue != null) {
        final color = Color(customColorValue);
        final hsl = HSLColor.fromColor(color);
        final lighterColor = hsl
            .withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0))
            .toColor();
        gradientColors = [color, lighterColor];
      } else {
        gradientColors = _getDefaultGradientColors(isCashu, isNwc, isLnurl);
      }
    }
    final Color shadowColor = gradientColors[0];

    // Determine icon configuration based on wallet type
    final WalletIconConfig iconConfig;
    final String? defaultAssetName;
    final IconData fallbackIcon;
    if (isCashu) {
      iconConfig = widget.cashuIcon ?? const WalletIconConfig();
      defaultAssetName = 'cashu.png';
      fallbackIcon = Icons.account_balance_wallet;
    } else if (isNwc) {
      iconConfig = widget.nwcIcon ?? const WalletIconConfig();
      defaultAssetName = 'nwc.png';
      fallbackIcon = Icons.cloud;
    } else if (isLnurl) {
      iconConfig = widget.lnurlIcon ?? const WalletIconConfig();
      defaultAssetName = null; // LNURL uses bolt icon, not PNG
      fallbackIcon = Icons.bolt;
    } else {
      iconConfig = const WalletIconConfig();
      defaultAssetName = 'wallet.png';
      fallbackIcon = Icons.wallet;
    }

    // Build main icon widget (full color, not monochromatic)
    final Widget mainIcon =
        iconConfig.iconWidget ??
        (defaultAssetName != null
            ? Image.asset(
                'assets/images/$defaultAssetName',
                package: 'ndk_flutter',
                width: iconConfig.iconSize,
                height: iconConfig.iconSize,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    fallbackIcon,
                    color: Colors.white,
                    size: iconConfig.iconSize,
                  );
                },
              )
            : Icon(
                fallbackIcon,
                color: Colors.white,
                size: iconConfig.iconSize,
              ));

    // Build background widget
    final Widget backgroundWidget =
        iconConfig.backgroundWidget ??
        (defaultAssetName != null
            ? Image.asset(
                'assets/images/$defaultAssetName',
                package: 'ndk_flutter',
                width: iconConfig.backgroundSize,
                height: iconConfig.backgroundSize,
                color: Colors.white.withAlpha(
                  (iconConfig.backgroundOpacity * 255).round(),
                ),
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    fallbackIcon,
                    size: iconConfig.backgroundSize,
                    color: Colors.white.withAlpha(30),
                  );
                },
              )
            : Icon(
                fallbackIcon,
                size: iconConfig.backgroundSize,
                color: Colors.white.withAlpha(30),
              ));

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.width,
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
          border: widget.isSelected
              ? Border.all(color: Colors.white, width: 3)
              : null,
        ),
        child: Stack(
          children: [
            Positioned(right: -20, top: -20, child: backgroundWidget),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      mainIcon,
                      // if (widget.isSelected)
                      //   Container(
                      //     margin: const EdgeInsets.only(right: 32),
                      //     padding: const EdgeInsets.symmetric(
                      //       horizontal: 8,
                      //       vertical: 4,
                      //     ),
                      //     decoration: BoxDecoration(
                      //       color: Colors.white.withAlpha(200),
                      //       borderRadius: BorderRadius.circular(12),
                      //     ),
                      //     child: Text(
                      //       l10n.selected,
                      //       style: const TextStyle(
                      //         color: Colors.black87,
                      //         fontSize: 10,
                      //         fontWeight: FontWeight.bold,
                      //       ),
                      //     ),
                      //   ),
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
                      if (showSubtitle) ...[
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
                      ],
                      if (isNwcReceiveOnly) ...[
                        const SizedBox(height: 4),
                        Text(
                          l10n.receiveOnlyWallet,
                          style: TextStyle(
                            color: Colors.white.withAlpha(200),
                            fontSize: 12,
                          ),
                        ),
                      ],
                      SizedBox(height: showBudgetInfo ? 4 : 16),
                      isLnurl
                          ? _buildLnurlInfo(
                              context,
                              widget.wallet as LnurlWallet,
                            )
                          : (canShowNwcBalance
                                ? _buildBalance(context)
                                : const SizedBox.shrink()),
                      if (showBudgetInfo) _buildBudgetInfo(context),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              right: 4,
              top: 4,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white70),
                itemBuilder: (context) {
                  final defaultItems = <PopupMenuEntry<String>>[
                    if (widget.wallet.canReceive)
                      PopupMenuItem(
                        value: 'set_default_receive',
                        enabled: !widget.isDefaultForReceiving,
                        child: Row(
                          children: [
                            Icon(
                              widget.isDefaultForReceiving
                                  ? Icons.check_circle
                                  : Icons.call_received,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.isDefaultForReceiving
                                  ? l10n.defaultForReceiving
                                  : l10n.setAsDefaultForReceiving,
                              style: widget.isDefaultForReceiving
                                  ? const TextStyle(color: Colors.grey)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    if (widget.wallet.canSend)
                      PopupMenuItem(
                        value: 'set_default_send',
                        enabled: !widget.isDefaultForSending,
                        child: Row(
                          children: [
                            Icon(
                              widget.isDefaultForSending
                                  ? Icons.check_circle
                                  : Icons.call_made,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.isDefaultForSending
                                  ? l10n.defaultForSending
                                  : l10n.setAsDefaultForSending,
                              style: widget.isDefaultForSending
                                  ? const TextStyle(color: Colors.grey)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                  ];

                  return [
                    ...defaultItems,
                    if (defaultItems.isNotEmpty) const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n.renameWallet),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'color',
                      child: Row(
                        children: [
                          const Icon(Icons.palette, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n.pickColor),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.deleteWallet,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ];
                },
                onSelected: (value) async {
                  switch (value) {
                    case 'set_default_receive':
                      widget.ndkFlutter.ndk.wallets
                          .setDefaultWalletForReceiving(widget.wallet.id);
                      widget.onDefaultWalletChanged?.call();
                      break;
                    case 'set_default_send':
                      widget.ndkFlutter.ndk.wallets.setDefaultWalletForSending(
                        widget.wallet.id,
                      );
                      widget.onDefaultWalletChanged?.call();
                      break;
                    case 'rename':
                      await _showRenameDialog(context);
                      break;
                    case 'color':
                      await _showColorPickerDialog(context);
                      break;
                    case 'delete':
                      final handler = widget.onDelete;
                      if (handler != null) {
                        await handler(context, widget.wallet);
                      } else {
                        await _defaultDeleteHandler(context);
                      }
                      break;
                  }
                },
              ),
            ),
            if (widget.isDefaultForReceiving || widget.isDefaultForSending)
              Positioned(right: 50, top: -1, child: _buildDefaultRibbons()),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultRibbons() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.isDefaultForReceiving)
          _buildDefaultRibbonTag(
            icon: Icons.call_received,
            tooltipMessage: l10n.defaultWalletForReceivingTooltip,
          ),
        if (widget.isDefaultForReceiving && widget.isDefaultForSending)
          const SizedBox(width: 6),
        if (widget.isDefaultForSending)
          _buildDefaultRibbonTag(
            icon: Icons.call_made,
            tooltipMessage: l10n.defaultWalletForSendingTooltip,
          ),
      ],
    );
  }

  Widget _buildDefaultRibbonTag({
    required IconData icon,
    required String tooltipMessage,
  }) {
    const Color ribbonColor = Color(0xFFcccccc);
    const Color foldColor = Color(0xFFEDEDED);
    const Color borderColor = Colors.black;
    const Color iconColor = Colors.black;

    return Tooltip(
      message: tooltipMessage,
      triggerMode: TooltipTriggerMode.tap,
      waitDuration: const Duration(milliseconds: 200),
      child: SizedBox(
        width: 20,
        height: 48,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              left: 2,
              right: 2,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: foldColor,
                  border: Border.all(color: borderColor, width: 1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(2),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 1,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 42,
                child: CustomPaint(
                  painter: const _RibbonPainter(
                    fillColor: ribbonColor,
                    borderColor: borderColor,
                  ),
                  child: Align(
                    alignment: const Alignment(0, -0.08),
                    child: Icon(icon, size: 12, color: iconColor),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getDefaultGradientColors(
    bool isCashu,
    bool isNwc,
    bool isLnurl,
  ) {
    if (isCashu) {
      return [const Color(0xFF7F38CA), const Color(0xFF9B5AD8)];
    } else if (isNwc) {
      return [
        const Color.fromRGBO(137, 127, 255, 1.0),
        const Color.fromRGBO(160, 153, 255, 1.0),
      ];
    } else if (isLnurl) {
      return [const Color(0xFFFFB300), const Color(0xFFFFC107)];
    } else {
      return [Colors.grey[700]!, Colors.grey[400]!];
    }
  }

  Future<void> _showRenameDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: widget.wallet.name);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final String? newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.renameWallet),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: l10n.walletName,
              hintText: l10n.walletNameHint,
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, nameController.text.trim()),
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );

    if (newName != null &&
        newName.isNotEmpty &&
        newName != widget.wallet.name) {
      try {
        setState(() {
          widget.wallet.name = newName;
        });
        await widget.ndkFlutter.ndk.wallets.addWallet(widget.wallet);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.walletRenamed),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.error(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showColorPickerDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    final List<Color> presetColors = [
      const Color(0xFF7F38CA), // Cashu purple
      const Color(0xFF9B5AD8), // Light purple
      const Color.fromRGBO(137, 127, 255, 1.0), // NWC blue
      const Color.fromRGBO(160, 153, 255, 1.0), // Light blue
      const Color(0xFFFFB300), // LNURL amber
      const Color(0xFFFFC107), // Amber light
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
    ];

    Color selectedColor = presetColors[0];

    final Color? result = await showDialog<Color>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.pickColor),
              content: SizedBox(
                width: double.maxFinite,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: presetColors.map((color) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(20),
                          border: selectedColor == color
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(50),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, selectedColor),
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        // Create a gradient from the selected color to a lighter version
        final hsl = HSLColor.fromColor(result);
        final lighterColor = hsl
            .withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0))
            .toColor();
        _customGradientColors = [result, lighterColor];
      });

      // Save color to wallet metadata by creating updated wallet
      try {
        final updatedMetadata = Map<String, dynamic>.from(
          widget.wallet.metadata,
        );
        updatedMetadata['cardColor'] = result.value;

        Wallet updatedWallet;
        if (widget.wallet is CashuWallet) {
          final w = widget.wallet as CashuWallet;
          updatedWallet = CashuWallet(
            id: w.id,
            name: w.name,
            supportedUnits: w.supportedUnits,
            mintUrl: w.mintUrl,
            mintInfo: w.mintInfo,
            metadata: updatedMetadata,
          );
        } else if (widget.wallet is NwcWallet) {
          final w = widget.wallet as NwcWallet;
          updatedWallet = NwcWallet(
            id: w.id,
            name: w.name,
            supportedUnits: w.supportedUnits,
            nwcUrl: w.nwcUrl,
            metadata: updatedMetadata,
          );
        } else if (widget.wallet is LnurlWallet) {
          final w = widget.wallet as LnurlWallet;
          updatedWallet = LnurlWallet(
            id: w.id,
            name: w.name,
            supportedUnits: w.supportedUnits,
            identifier: w.identifier,
            lnurlPayUrl: w.lnurlPayUrl,
            minSendable: w.minSendable,
            maxSendable: w.maxSendable,
            metadataFetchedAt: w.metadataFetchedAt,
            metadata: updatedMetadata,
          );
        } else {
          throw UnsupportedError('Unknown wallet type');
        }

        await widget.ndkFlutter.ndk.wallets.addWallet(updatedWallet);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save color: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildLnurlInfo(BuildContext context, LnurlWallet lnWallet) {
    final l10n = AppLocalizations.of(context)!;
    if (lnWallet.minSendable != null && lnWallet.maxSendable != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.receiveOnlyWallet,
            style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.receiveRange(
              lnWallet.minSendable! ~/ 1000,
              lnWallet.maxSendable! ~/ 1000,
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    return Text(
      l10n.limitsUnavailable,
      style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12),
    );
  }

  Widget _buildBalance(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isCompactNwc = widget.wallet is NwcWallet && _shouldShowBudgetInfo();
    final balanceFontSize = isCompactNwc ? 24.0 : 28.0;
    final unitFontSize = isCompactNwc ? 12.0 : 14.0;
    return StreamBuilder<List<WalletBalance>>(
      stream: widget.ndkFlutter.ndk.wallets.getBalancesStream(widget.wallet.id),
      builder: (context, snapshot) {
        final balances = snapshot.data ?? [];
        final satBalance = balances
            .firstWhere(
              (b) => b.unit == 'sat',
              orElse: () => WalletBalance(
                walletId: widget.wallet.id,
                unit: 'sat',
                amount: 0,
              ),
            )
            .amount;

        return Row(
          children: [
            Text(
              '$satBalance',
              style: TextStyle(
                color: Colors.white,
                fontSize: balanceFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              l10n.sats,
              style: TextStyle(
                color: Colors.white.withAlpha(200),
                fontSize: unitFontSize,
              ),
            ),
          ],
        );
      },
    );
  }

  bool _shouldShowBudgetInfo() {
    final budget = _budgetResponse;
    if (budget == null) return false;
    return !(budget.usedBudget == 0 && budget.totalBudget == 0);
  }

  Widget _buildBudgetInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final budget = _budgetResponse!;

    final usedSats = budget.usedBudget ~/ 1000;
    final totalSats = budget.totalBudget ~/ 1000;
    final progress = totalSats > 0 ? usedSats / totalSats : 0.0;

    String renewalText;
    if (budget.renewalPeriod == BudgetRenewalPeriod.never) {
      renewalText = '';
    } else {
      String periodText;
      switch (budget.renewalPeriod) {
        case BudgetRenewalPeriod.daily:
          periodText = l10n.budgetDaily;
          break;
        case BudgetRenewalPeriod.weekly:
          periodText = l10n.budgetWeekly;
          break;
        case BudgetRenewalPeriod.monthly:
          periodText = l10n.budgetMonthly;
          break;
        case BudgetRenewalPeriod.yearly:
          periodText = l10n.budgetYearly;
          break;
        default:
          periodText = '';
      }

      if (widget.showBudgetRenewalDays && budget.renewsAt != null) {
        final renewsAt = DateTime.fromMillisecondsSinceEpoch(
          budget.renewsAt! * 1000,
        );
        final now = DateTime.now();
        final daysUntilRenewal = renewsAt.difference(now).inDays;

        if (daysUntilRenewal > 0) {
          renewalText = periodText.isNotEmpty
              ? '${l10n.budgetRenewsIn(daysUntilRenewal)} ($periodText)'
              : '';
        } else {
          renewalText = periodText;
        }
      } else {
        renewalText = periodText;
      }
    }
    final bool showRenewalText = renewalText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(1.5),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.white.withAlpha(50),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress > 0.9 ? Colors.red[300]! : Colors.white.withAlpha(200),
            ),
            minHeight: 3,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                l10n.budgetUsedOf(usedSats, totalSats),
                style: TextStyle(
                  color: Colors.white.withAlpha(200),
                  fontSize: 9,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showRenewalText) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  renewalText,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white.withAlpha(200),
                    fontSize: 9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        // Text(
        //   renewalText,
        //   style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 9),
        //   maxLines: 1,
        //   overflow: TextOverflow.ellipsis,
        // ),
      ],
    );
  }

  Future<void> _defaultDeleteHandler(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.deleteWalletConfirmation),
          content: Text(l10n.deleteWalletConfirmationMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await widget.ndkFlutter.ndk.wallets.removeWallet(widget.wallet.id);
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(l10n.error(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _RibbonPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;

  const _RibbonPainter({required this.fillColor, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final notchDepth = size.height * 0.2;
    final notchHalfWidth = size.width * 0.28;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo((size.width / 2) + notchHalfWidth, size.height)
      ..lineTo(size.width / 2, size.height - notchDepth)
      ..lineTo((size.width / 2) - notchHalfWidth, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawShadow(path, Colors.black.withAlpha(150), 2.5, false);

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _RibbonPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor;
  }
}
