import 'package:flutter/material.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';

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
class NWalletCard extends StatelessWidget {
  final Wallet wallet;
  final Ndk ndk;
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
    required this.ndk,
    required this.isSelected,
    required this.onTap,
    this.onDelete,
    this.width = 280,
    this.cashuIcon,
    this.nwcIcon,
    this.lnurlIcon,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bool isCashu = wallet is CashuWallet;
    final bool isNwc = wallet is NwcWallet;
    final bool isLnurl = wallet is LnurlWallet;

    final String walletName;
    if (isCashu) {
      walletName = (wallet as CashuWallet).mintInfo.name ?? l10n.cashuWallet;
    } else if (isNwc) {
      walletName = (wallet as NwcWallet).name;
    } else if (isLnurl) {
      walletName = (wallet as LnurlWallet).name;
    } else {
      walletName = l10n.unknownWalletType;
    }

    final String subtitle;
    if (isCashu) {
      subtitle = (wallet as CashuWallet).mintUrl.replaceAll('https://', '');
    } else if (isNwc) {
      subtitle = l10n.nwcWalletSubtitle;
    } else if (isLnurl) {
      subtitle = (wallet as LnurlWallet).identifier;
    } else {
      subtitle = '';
    }

    final List<Color> gradientColors;
    final Color shadowColor;
    if (isCashu) {
      gradientColors = [const Color(0xFF7F38CA), const Color(0xFF9B5AD8)];
      shadowColor = const Color(0xFF7F38CA);
    } else if (isNwc) {
      gradientColors = [
        const Color.fromRGBO(137, 127, 255, 1.0),
        const Color.fromRGBO(160, 153, 255, 1.0),
      ];
      shadowColor = const Color.fromRGBO(137, 127, 255, 1.0);
    } else if (isLnurl) {
      gradientColors = [const Color(0xFFFFB300), const Color(0xFFFFC107)];
      shadowColor = const Color(0xFFFFB300);
    } else {
      gradientColors = [Colors.grey[700]!, Colors.grey[400]!];
      shadowColor = Colors.grey;
    }

    // Determine icon configuration based on wallet type
    final WalletIconConfig iconConfig;
    final String? defaultAssetName;
    final IconData fallbackIcon;
    if (isCashu) {
      iconConfig = cashuIcon ?? const WalletIconConfig();
      defaultAssetName = 'cashu.png';
      fallbackIcon = Icons.account_balance_wallet;
    } else if (isNwc) {
      iconConfig = nwcIcon ?? const WalletIconConfig();
      defaultAssetName = 'nwc.png';
      fallbackIcon = Icons.cloud;
    } else if (isLnurl) {
      iconConfig = lnurlIcon ?? const WalletIconConfig();
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
      onTap: onTap,
      child: Container(
        width: width,
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
                      if (isSelected)
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
                          ? _buildLnurlInfo(context, wallet as LnurlWallet)
                          : _buildBalance(context),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white70),
                onPressed: () async {
                  final handler = onDelete;
                  if (handler != null) {
                    await handler(context, wallet);
                  } else {
                    await _defaultDeleteHandler(context);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
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
      stream: ndk.wallets.getBalancesStream(wallet.id),
      builder: (context, snapshot) {
        final balances = snapshot.data ?? [];
        final satBalance = balances
            .firstWhere(
              (b) => b.unit == 'sat',
              orElse: () =>
                  WalletBalance(walletId: wallet.id, unit: 'sat', amount: 0),
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
    try {
      await ndk.wallets.removeWallet(wallet.id);
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
