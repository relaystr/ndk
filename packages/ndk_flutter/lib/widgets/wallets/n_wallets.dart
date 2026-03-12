import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';

import '../../l10n/app_localizations.dart';
import 'n_add_wallet_dialogs.dart';
import 'n_wallet_actions.dart';
import 'n_wallet_card.dart';
import 'n_wallet_card_list.dart';
import 'n_pending_transactions.dart';
import 'n_recent_transactions.dart';

/// High-level wallets section widget that mirrors the sample app's wallets tab.
///
/// This keeps built-in English defaults for labels but allows host applications
/// to pass in localized strings (e.g. from AppLocalizations).
class NWallets extends StatefulWidget {
  final Ndk ndk;

  /// Section title above the wallet cards.
  final String? title;

  /// Title above the recent transactions list.
  final String? recentActivityTitle;

  /// Whether to show the pending transactions section.
  final bool showPendingTransactions;

  /// Whether to show the recent transactions section.
  final bool showRecentTransactions;

  /// Whether to show the add-wallet buttons in the header.
  final bool showAddButtons;

  /// Optional callback when add-Cashu button is pressed.
  final VoidCallback? onAddCashu;

  /// Optional callback when add-NWC button is pressed.
  final VoidCallback? onAddNwc;

  /// Optional callback when add-LNURL button is pressed.
  final VoidCallback? onAddLnurl;

  /// Optional widget to replace the entire header row (title + actions).
  final Widget? header;

  /// Optional widget to replace just the add-buttons row.
  final Widget? headerActions;

  /// Padding around the entire section.
  final EdgeInsetsGeometry padding;

  /// Height of the wallet cards list.
  final double walletCardsHeight;

  /// Height of the recent transactions list.
  final double recentTransactionsHeight;

  /// Optional callback when a wallet is selected.
  final ValueChanged<String>? onWalletSelected;

  /// Custom icon configuration for Cashu wallets
  final WalletIconConfig? cashuIcon;

  /// Custom icon configuration for NWC wallets
  final WalletIconConfig? nwcIcon;

  /// Custom icon configuration for LNURL wallets
  final WalletIconConfig? lnurlIcon;

  const NWallets({
    super.key,
    required this.ndk,
    this.title,
    this.recentActivityTitle,
    this.showPendingTransactions = true,
    this.showRecentTransactions = true,
    this.showAddButtons = true,
    this.onAddCashu,
    this.onAddNwc,
    this.onAddLnurl,
    this.header,
    this.headerActions,
    this.padding = const EdgeInsets.all(16.0),
    this.walletCardsHeight = 200,
    this.recentTransactionsHeight = 200,
    this.onWalletSelected,
    this.cashuIcon,
    this.nwcIcon,
    this.lnurlIcon,
  });

  @override
  State<NWallets> createState() => _NWalletsState();
}

class _NWalletsState extends State<NWallets> {
  String? _selectedWalletId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      child: Padding(
        padding: widget.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            widget.header ?? _buildHeader(context, l10n),
            const SizedBox(height: 16),
            SizedBox(
              height: widget.walletCardsHeight,
              child: NWalletCardList(
                ndk: widget.ndk,
                selectedWalletId: _selectedWalletId,
                onWalletSelected: (walletId) {
                  setState(() {
                    _selectedWalletId = walletId;
                  });
                  widget.onWalletSelected?.call(walletId);
                },
                cashuIcon: widget.cashuIcon,
                nwcIcon: widget.nwcIcon,
                lnurlIcon: widget.lnurlIcon,
              ),
            ),
            const SizedBox(height: 24),
            if (_selectedWalletId != null)
              NWalletActions(
                ndk: widget.ndk,
                selectedWalletId: _selectedWalletId!,
                onClearSelection: () {
                  setState(() {
                    _selectedWalletId = null;
                  });
                },
              ),
            const SizedBox(height: 24),
            if (widget.showPendingTransactions)
              NPendingTransactions(ndk: widget.ndk),
            if (widget.showRecentTransactions) ...[
              Text(
                widget.recentActivityTitle ?? l10n.recentActivityTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: widget.recentTransactionsHeight,
                child: NRecentTransactions(ndk: widget.ndk),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.title ?? l10n.walletsTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        widget.headerActions ??
            (widget.showAddButtons
                ? _buildDefaultActions(context, l10n)
                : const SizedBox.shrink()),
      ],
    );
  }

  Widget _buildDefaultActions(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        IconButton(
          onPressed: widget.onAddCashu ?? () => _showAddCashuDialog(context),
          icon: _buildAddButtonIcon(
            widget.cashuIcon,
            'cashu.png',
            Icons.add_card,
          ),
          tooltip: l10n.addCashuTooltip,
        ),
        IconButton(
          onPressed: widget.onAddNwc ?? () => _showAddNwcDialog(context),
          icon: _buildAddButtonIcon(
            widget.nwcIcon,
            'nwc.png',
            Icons.cloud_upload,
          ),
          tooltip: l10n.addNwcTooltip,
        ),
        IconButton(
          onPressed: widget.onAddLnurl ?? () => _showAddLnurlDialog(context),
          icon: _buildAddButtonIcon(widget.lnurlIcon, null, Icons.bolt),
          tooltip: l10n.addLnurlTooltip,
        ),
      ],
    );
  }

  Widget _buildAddButtonIcon(
    WalletIconConfig? iconConfig,
    String? assetName,
    IconData fallbackIcon,
  ) {
    final double size = 24.0;

    if (iconConfig?.iconWidget != null) {
      return SizedBox(width: size, height: size, child: iconConfig!.iconWidget);
    }

    if (assetName != null) {
      return Image.asset(
        'assets/images/$assetName',
        package: 'ndk_flutter',
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) {
          return Icon(fallbackIcon, size: size);
        },
      );
    }

    return Icon(fallbackIcon, size: size);
  }

  void _showAddCashuDialog(BuildContext context) {
    showAddCashuWalletDialog(context, widget.ndk);
  }

  void _showAddNwcDialog(BuildContext context) {
    showAddNwcWalletDialog(context, widget.ndk);
  }

  void _showAddLnurlDialog(BuildContext context) {
    showAddLnurlWalletDialog(context, widget.ndk);
  }
}
