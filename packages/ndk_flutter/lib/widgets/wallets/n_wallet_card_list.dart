import 'package:flutter/material.dart';
import 'package:ndk/entities.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

import '../../l10n/app_localizations.dart';
import 'n_wallet_card.dart';

/// Horizontal list of wallet cards backed by `ndk.wallets.walletsStream`.
class NWalletCardList extends StatelessWidget {
  final NdkFlutter ndkFlutter;
  final String? selectedWalletId;
  final ValueChanged<String> onWalletSelected;
  final VoidCallback? onAddWallet;

  /// Scroll direction for the wallet cards list.
  final Axis scrollDirection;

  /// Optional text to display when there are no wallets.
  /// Defaults to an English string; host apps should prefer
  /// passing a localized value from AppLocalizations.
  final String? emptyTitleText;
  final String? emptySubtitleText;

  /// Custom icon configuration for Cashu wallets
  final WalletIconConfig? cashuIcon;

  /// Custom icon configuration for NWC wallets
  final WalletIconConfig? nwcIcon;

  /// Custom icon configuration for LNURL wallets
  final WalletIconConfig? lnurlIcon;

  /// Whether to show the add-wallet template card.
  final bool showAddWalletCard;

  const NWalletCardList({
    super.key,
    required this.ndkFlutter,
    this.selectedWalletId,
    required this.onWalletSelected,
    this.onAddWallet,
    this.scrollDirection = Axis.horizontal,
    this.emptyTitleText,
    this.emptySubtitleText,
    this.cashuIcon,
    this.nwcIcon,
    this.lnurlIcon,
    this.showAddWalletCard = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<List<Wallet>>(
      stream: ndkFlutter.ndk.wallets.walletsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('${l10n.error}: ${snapshot.error}'));
        }

        final wallets = snapshot.data ?? [];

        if (wallets.isEmpty && !showAddWalletCard) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wallet, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  emptyTitleText ?? l10n.noWalletsYet,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(emptySubtitleText ?? l10n.tapToAddWallet),
              ],
            ),
          );
        }

        final int itemCount =
            wallets.length + (showAddWalletCard ? 1 : 0);

        return ListView.builder(
          scrollDirection: scrollDirection,
          primary: false,
          itemCount: itemCount,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemBuilder: (context, index) {
            if (showAddWalletCard && index == wallets.length) {
              return _AddWalletCard(onTap: onAddWallet);
            }

            final wallet = wallets[index];
            return NWalletCard(
              wallet: wallet,
              ndkFlutter: ndkFlutter,
              isSelected: wallet.id == selectedWalletId,
              onTap: () => onWalletSelected(wallet.id),
              showBudgetRenewalDays: scrollDirection == Axis.vertical,
              cashuIcon: cashuIcon,
              nwcIcon: nwcIcon,
              lnurlIcon: lnurlIcon,
            );
          },
        );
      },
    );
  }
}

class _AddWalletCard extends StatelessWidget {
  final VoidCallback? onTap;

  const _AddWalletCard({this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final Color baseColor = Colors.grey[100]!;
    final Color accentColor = Colors.grey[200]!;
    final Color borderColor = Colors.grey[200]!;
    final Color iconColor = Colors.grey[300]!;
    final Color textColor = Colors.grey[400]!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, color: iconColor, size: 22),
            ),
            const SizedBox(height: 12),
            Container(width: 140, height: 12, color: accentColor),
            const SizedBox(height: 8),
            Container(width: 90, height: 10, color: accentColor),
            const SizedBox(height: 12),
            Text(
              l10n.addWalletTitle,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
