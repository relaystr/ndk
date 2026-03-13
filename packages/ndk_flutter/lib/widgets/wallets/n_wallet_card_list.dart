import 'package:flutter/material.dart';
import 'package:ndk/entities.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

import '../../l10n/app_localizations.dart';
import 'n_wallet_card.dart';

/// Reorderable list of wallet cards backed by `ndk.wallets.walletsStream`.
class NWalletCardList extends StatefulWidget {
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
  State<NWalletCardList> createState() => _NWalletCardListState();
}

class _NWalletCardListState extends State<NWalletCardList> {
  static const String _walletOrderKey = 'walletOrder';

  List<String>? _overrideOrderIds;

  int? _readWalletOrder(Wallet wallet) {
    final raw = wallet.metadata[_walletOrderKey];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  List<Wallet> _applyOverrideOrder(List<Wallet> wallets) {
    final override = _overrideOrderIds;
    if (override == null || override.isEmpty) {
      return wallets;
    }
    final byId = {for (final wallet in wallets) wallet.id: wallet};
    final ordered = <Wallet>[];
    for (final id in override) {
      final wallet = byId.remove(id);
      if (wallet != null) {
        ordered.add(wallet);
      }
    }
    ordered.addAll(byId.values);
    return ordered;
  }

  List<Wallet> _orderWallets(List<Wallet> wallets) {
    final override = _applyOverrideOrder(wallets);
    if (!identical(override, wallets)) {
      return override;
    }

    final fallbackOrder = <String, int>{
      for (var i = 0; i < wallets.length; i++) wallets[i].id: i,
    };
    final ordered = List<Wallet>.from(wallets);
    ordered.sort((a, b) {
      final orderA = _readWalletOrder(a) ?? fallbackOrder[a.id]!;
      final orderB = _readWalletOrder(b) ?? fallbackOrder[b.id]!;
      if (orderA != orderB) {
        return orderA.compareTo(orderB);
      }
      return fallbackOrder[a.id]!.compareTo(fallbackOrder[b.id]!);
    });
    return ordered;
  }

  Wallet _copyWalletWithMetadata(Wallet wallet, Map<String, dynamic> metadata) {
    if (wallet is CashuWallet) {
      return CashuWallet(
        id: wallet.id,
        name: wallet.name,
        supportedUnits: wallet.supportedUnits,
        mintUrl: wallet.mintUrl,
        mintInfo: wallet.mintInfo,
        metadata: metadata,
      );
    }
    if (wallet is NwcWallet) {
      return NwcWallet(
        id: wallet.id,
        name: wallet.name,
        supportedUnits: wallet.supportedUnits,
        nwcUrl: wallet.nwcUrl,
        metadata: metadata,
      );
    }
    if (wallet is LnurlWallet) {
      return LnurlWallet(
        id: wallet.id,
        name: wallet.name,
        supportedUnits: wallet.supportedUnits,
        identifier: wallet.identifier,
        lnurlPayUrl: wallet.lnurlPayUrl,
        minSendable: wallet.minSendable,
        maxSendable: wallet.maxSendable,
        metadataFetchedAt: wallet.metadataFetchedAt,
        metadata: metadata,
      );
    }
    throw UnsupportedError('Unknown wallet type');
  }

  Future<void> _persistWalletOrder(List<Wallet> orderedWallets) async {
    final updates = <Future<void>>[];
    for (var i = 0; i < orderedWallets.length; i++) {
      final wallet = orderedWallets[i];
      final currentOrder = _readWalletOrder(wallet);
      if (currentOrder == i) {
        continue;
      }
      final updatedMetadata = Map<String, dynamic>.from(wallet.metadata);
      updatedMetadata[_walletOrderKey] = i;
      final updatedWallet = _copyWalletWithMetadata(wallet, updatedMetadata);
      updates.add(widget.ndkFlutter.ndk.wallets.addWallet(updatedWallet));
    }
    if (updates.isNotEmpty) {
      await Future.wait(updates);
    }
  }

  void _handleReorder(
    int oldIndex,
    int newIndex,
    List<Wallet> orderedWallets,
  ) {
    final walletCount = orderedWallets.length;
    if (walletCount == 0) return;
    if (widget.showAddWalletCard && oldIndex == walletCount) {
      return;
    }

    if (widget.showAddWalletCard && newIndex > walletCount) {
      newIndex = walletCount;
    }
    if (widget.showAddWalletCard && newIndex == walletCount) {
      newIndex = walletCount - 1;
    }
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    if (newIndex < 0 || newIndex >= walletCount || oldIndex == newIndex) {
      return;
    }

    final updated = List<Wallet>.from(orderedWallets);
    final moved = updated.removeAt(oldIndex);
    updated.insert(newIndex, moved);

    setState(() {
      _overrideOrderIds = updated.map((wallet) => wallet.id).toList();
    });

    _persistWalletOrder(updated);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<List<Wallet>>(
      stream: widget.ndkFlutter.ndk.wallets.walletsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('${l10n.error}: ${snapshot.error}'));
        }

        final wallets = snapshot.data ?? [];
        final orderedWallets = _orderWallets(wallets);

        if (orderedWallets.isEmpty && !widget.showAddWalletCard) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wallet, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  widget.emptyTitleText ?? l10n.noWalletsYet,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(widget.emptySubtitleText ?? l10n.tapToAddWallet),
              ],
            ),
          );
        }

        final int itemCount =
            orderedWallets.length + (widget.showAddWalletCard ? 1 : 0);

        return ReorderableListView.builder(
          scrollDirection: widget.scrollDirection,
          primary: false,
          itemCount: itemCount,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          buildDefaultDragHandles: false,
          onReorder: (oldIndex, newIndex) =>
              _handleReorder(oldIndex, newIndex, orderedWallets),
          itemBuilder: (context, index) {
            if (widget.showAddWalletCard &&
                index == orderedWallets.length) {
              return _AddWalletCard(
                key: const ValueKey('add_wallet_card'),
                onTap: widget.onAddWallet,
              );
            }

            final wallet = orderedWallets[index];
            return ReorderableDelayedDragStartListener(
              key: ValueKey('wallet-${wallet.id}'),
              index: index,
              child: NWalletCard(
                wallet: wallet,
                ndkFlutter: widget.ndkFlutter,
                isSelected: wallet.id == widget.selectedWalletId,
                onTap: () => widget.onWalletSelected(wallet.id),
                showBudgetRenewalDays:
                    widget.scrollDirection == Axis.vertical,
                cashuIcon: widget.cashuIcon,
                nwcIcon: widget.nwcIcon,
                lnurlIcon: widget.lnurlIcon,
              ),
            );
          },
        );
      },
    );
  }
}

class _AddWalletCard extends StatelessWidget {
  final VoidCallback? onTap;

  const _AddWalletCard({super.key, this.onTap});

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
