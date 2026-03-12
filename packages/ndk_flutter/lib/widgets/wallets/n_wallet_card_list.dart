import 'package:flutter/material.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';

import '../../l10n/app_localizations.dart';
import 'n_wallet_card.dart';

/// Horizontal list of wallet cards backed by `ndk.wallets.walletsStream`.
class NWalletCardList extends StatelessWidget {
  final Ndk ndk;
  final String? selectedWalletId;
  final ValueChanged<String> onWalletSelected;

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

  const NWalletCardList({
    super.key,
    required this.ndk,
    this.selectedWalletId,
    required this.onWalletSelected,
    this.emptyTitleText,
    this.emptySubtitleText,
    this.cashuIcon,
    this.nwcIcon,
    this.lnurlIcon,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<List<Wallet>>(
      stream: ndk.wallets.walletsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('${l10n.error}: ${snapshot.error}'));
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
                  emptyTitleText ?? l10n.noWalletsYet,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(emptySubtitleText ?? l10n.tapToAddWallet),
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
            return NWalletCard(
              wallet: wallet,
              ndk: ndk,
              isSelected: wallet.id == selectedWalletId,
              onTap: () => onWalletSelected(wallet.id),
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
