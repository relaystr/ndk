import 'package:flutter/material.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

import '../../l10n/app_localizations.dart';

/// High-level wallets section widget that mirrors the sample app's wallets tab.
///
/// This keeps built-in English defaults for labels but allows host applications
/// to pass in localized strings (e.g. from AppLocalizations).
class NWallets extends StatefulWidget {
  final NdkFlutter ndkFlutter;

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

  /// Whether to show the wallet operations card for the selected wallet.
  final bool showWalletActions;

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

  /// Scroll direction for the wallet cards list.
  final Axis walletCardsScrollDirection;

  /// Height of the recent transactions list.
  final double recentTransactionsHeight;

  /// Optional callback when a wallet is selected.
  final ValueChanged<String>? onWalletSelected;

  /// Parameters for launching Alby Go NWC connection.
  final AlbyGoConnectConfig albyGoConnectConfig;

  /// Optional coordinator for handling the Alby Go NWC connection flow.
  final NwcWalletAuthCoordinator? nwcWalletAuthCoordinator;

  /// Custom icon configuration for Cashu wallets
  final WalletIconConfig? cashuIcon;

  /// Custom icon configuration for NWC wallets
  final WalletIconConfig? nwcIcon;

  /// Custom icon configuration for LNURL wallets
  final WalletIconConfig? lnurlIcon;

  const NWallets({
    super.key,
    required this.ndkFlutter,
    this.title,
    this.recentActivityTitle,
    this.showPendingTransactions = true,
    this.showRecentTransactions = true,
    this.showAddButtons = true,
    this.showWalletActions = true,
    this.onAddCashu,
    this.onAddNwc,
    this.onAddLnurl,
    this.header,
    this.headerActions,
    this.padding = const EdgeInsets.all(16.0),
    this.walletCardsHeight = 200,
    this.walletCardsScrollDirection = Axis.horizontal,
    this.recentTransactionsHeight = 200,
    this.onWalletSelected,
    this.albyGoConnectConfig = kDefaultAlbyGoConnectConfig,
    this.nwcWalletAuthCoordinator,
    this.cashuIcon,
    this.nwcIcon,
    this.lnurlIcon,
  });

  @override
  State<NWallets> createState() => NWalletsState();
}

class NWalletsState extends State<NWallets> {
  String? _selectedWalletId;
  late final NwcWalletAuthCoordinator _nwcWalletAuthCoordinator;

  @override
  void initState() {
    super.initState();
    _nwcWalletAuthCoordinator =
        widget.nwcWalletAuthCoordinator ?? NwcWalletAuthCoordinator();
  }

  Future<bool> onProtocolUrlReceived(String url) async {
    final handled = await _nwcWalletAuthCoordinator.processProtocolUrl(
      context,
      widget.ndkFlutter,
      url,
    );

    if (!handled || !mounted) return handled;

    final connectedWalletId = _nwcWalletAuthCoordinator
        .takeLastConnectedWalletId();
    if (connectedWalletId != null) {
      setState(() {
        _selectedWalletId = connectedWalletId;
      });
      widget.onWalletSelected?.call(connectedWalletId);
    }
    return handled;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bool hasSelectedWallet = _selectedWalletId != null;
    final bool showActionsSection =
        widget.showWalletActions && hasSelectedWallet;
    final bool showPendingSection =
        widget.showPendingTransactions && hasSelectedWallet;
    final bool showRecentSection =
        widget.showRecentTransactions && hasSelectedWallet;
    final bool useExpandedCardList =
        widget.walletCardsScrollDirection == Axis.vertical &&
        !widget.showWalletActions &&
        !widget.showPendingTransactions &&
        !widget.showRecentTransactions;

    if (useExpandedCardList) {
      return Padding(
        padding: widget.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            widget.header ?? _buildHeader(),
            const SizedBox(height: 16),
            Expanded(
              child: NWalletCardList(
                ndkFlutter: widget.ndkFlutter,
                selectedWalletId: _selectedWalletId,
                onWalletSelected: (walletId) {
                  setState(() {
                    _selectedWalletId = walletId;
                  });
                  widget.onWalletSelected?.call(walletId);
                },
                onAddWallet: widget.showAddButtons
                    ? () => _showAddWalletDialog(context)
                    : null,
                scrollDirection: widget.walletCardsScrollDirection,
                showAddWalletCard: widget.showAddButtons,
                cashuIcon: widget.cashuIcon,
                nwcIcon: widget.nwcIcon,
                lnurlIcon: widget.lnurlIcon,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: widget.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            widget.header ?? _buildHeader(),
            const SizedBox(height: 16),
            SizedBox(
              height: widget.walletCardsHeight,
              child: NWalletCardList(
                ndkFlutter: widget.ndkFlutter,
                selectedWalletId: _selectedWalletId,
                onWalletSelected: (walletId) {
                  setState(() {
                    _selectedWalletId = walletId;
                  });
                  widget.onWalletSelected?.call(walletId);
                },
                onAddWallet: widget.showAddButtons
                    ? () => _showAddWalletDialog(context)
                    : null,
                scrollDirection: widget.walletCardsScrollDirection,
                showAddWalletCard: widget.showAddButtons,
                cashuIcon: widget.cashuIcon,
                nwcIcon: widget.nwcIcon,
                lnurlIcon: widget.lnurlIcon,
              ),
            ),
            if (showActionsSection) ...[
              const SizedBox(height: 24),
              NWalletActions(
                ndkFlutter: widget.ndkFlutter,
                selectedWalletId: _selectedWalletId!,
                onClearSelection: () {
                  setState(() {
                    _selectedWalletId = null;
                  });
                },
              ),
              const SizedBox(height: 24),
            ] else if (showPendingSection || showRecentSection) ...[
              const SizedBox(height: 24),
            ],
            if (showPendingSection)
              NPendingTransactions(
                ndkFlutter: widget.ndkFlutter,
                walletId: _selectedWalletId!,
              ),
            if (showRecentSection) ...[
              Text(
                widget.recentActivityTitle ?? l10n.recentActivityTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: widget.recentTransactionsHeight,
                child: NRecentTransactions(
                  ndkFlutter: widget.ndkFlutter,
                  walletId: _selectedWalletId!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const SizedBox.shrink();
  }

  void _showAddWalletDialog(BuildContext context) {
    showAddWalletTypeDialog(
      context,
      widget.ndkFlutter,
      albyGoConnectConfig: widget.albyGoConnectConfig,
      nwcWalletAuthCoordinator: _nwcWalletAuthCoordinator,
    );
  }
}
