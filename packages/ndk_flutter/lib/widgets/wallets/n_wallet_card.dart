import 'package:flutter/material.dart';
import 'package:ndk/entities.dart';
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
  final VoidCallback onTap;
  final Future<void> Function(BuildContext context, Wallet wallet)? onDelete;

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
    required this.onTap,
    this.onDelete,
    this.width = 280,
    this.cashuIcon,
    this.nwcIcon,
    this.lnurlIcon,
  });

  @override
  State<NWalletCard> createState() => _NWalletCardState();
}

class _NWalletCardState extends State<NWalletCard> {
  List<Color>? _customGradientColors;

  @override
  void initState() {
    super.initState();
    _loadCustomColor();
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
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bool isCashu = widget.wallet is CashuWallet;
    final bool isNwc = widget.wallet is NwcWallet;
    final bool isLnurl = widget.wallet is LnurlWallet;

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
      subtitle = (widget.wallet as LnurlWallet).identifier;
    } else {
      subtitle = '';
    }

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
                      if (widget.isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            l10n.selected,
                            style: const TextStyle(
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
                      isLnurl
                          ? _buildLnurlInfo(
                              context,
                              widget.wallet as LnurlWallet,
                            )
                          : _buildBalance(context),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              right: 4,
              bottom: 4,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white70),
                itemBuilder: (context) => [
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
                ],
                onSelected: (value) async {
                  switch (value) {
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              l10n.sats,
              style: TextStyle(
                color: Colors.white.withAlpha(200),
                fontSize: 14,
              ),
            ),
          ],
        );
      },
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
