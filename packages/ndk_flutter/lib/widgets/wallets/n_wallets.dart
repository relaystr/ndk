import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';

import 'n_add_wallet_dialogs.dart';
import 'n_wallet_actions.dart';
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
  });

  @override
  State<NWallets> createState() => _NWalletsState();
}

class _NWalletsState extends State<NWallets> {
  String? _selectedWalletId;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: widget.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            widget.header ?? _buildHeader(context),
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
                widget.recentActivityTitle ?? 'Recent Activity',
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

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.title ?? 'My Wallets',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        widget.headerActions ??
            (widget.showAddButtons
                ? _buildDefaultActions(context)
                : const SizedBox.shrink()),
      ],
    );
  }

  Widget _buildDefaultActions(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: widget.onAddCashu ?? () => _showAddCashuDialog(context),
          icon: const Icon(Icons.add_card),
          tooltip: 'Add Cashu',
        ),
        IconButton(
          onPressed: widget.onAddNwc ?? () => _showAddNwcDialog(context),
          icon: const Icon(Icons.cloud_upload),
          tooltip: 'Add NWC',
        ),
        IconButton(
          onPressed: widget.onAddLnurl ?? () => _showAddLnurlDialog(context),
          icon: const Icon(Icons.bolt),
          tooltip: 'Add LNURL',
        ),
      ],
    );
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
