import 'package:flutter/material.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';

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

  const NWalletCardList({
    super.key,
    required this.ndk,
    this.selectedWalletId,
    required this.onWalletSelected,
    this.emptyTitleText,
    this.emptySubtitleText,
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
                  emptyTitleText ?? 'No wallets yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  emptySubtitleText ?? 'Tap + to add one',
                ),
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
            );
          },
        );
      },
    );
  }
}

