import 'package:flutter/material.dart';
import 'package:ndk/entities.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

import '../../l10n/app_localizations.dart';
import 'n_cashu_mint_icon.dart';
import 'wallet_action_dialogs.dart';

/// Card with Send/Receive actions and dialogs for a selected wallet.
///
/// This widget encapsulates the wallet operation flows that were previously
/// implemented directly in the sample app.
class NWalletActions extends StatefulWidget {
  final NdkFlutter ndkFlutter;
  final String selectedWalletId;

  /// Called when the close button is tapped. Required only when
  /// [showCloseButton] is true.
  final VoidCallback? onClearSelection;

  /// Whether to show the wallet-type header (icon + name) and the divider.
  final bool showTitle;

  /// Whether to show the close (X) button in the header.
  final bool showCloseButton;

  /// Condensed layout: drops the [Card] wrapper and tightens padding so the
  /// widget is just the action buttons. Useful when embedding inline.
  final bool condensed;

  const NWalletActions({
    super.key,
    required this.ndkFlutter,
    required this.selectedWalletId,
    this.onClearSelection,
    this.showTitle = true,
    this.showCloseButton = true,
    this.condensed = false,
  }) : assert(
         !showCloseButton || onClearSelection != null,
         'onClearSelection is required when showCloseButton is true',
       );

  @override
  State<NWalletActions> createState() => _NWalletActionsState();
}

class _NWalletActionsState extends State<NWalletActions>
    with WalletActionDialogsMixin {
  bool _selectionClearScheduled = false;

  @override
  NdkFlutter get ndkFlutter => widget.ndkFlutter;

  @override
  void didUpdateWidget(covariant NWalletActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedWalletId != widget.selectedWalletId) {
      _selectionClearScheduled = false;
    }
  }

  void _clearMissingWalletSelection() {
    if (_selectionClearScheduled) return;
    _selectionClearScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onClearSelection?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<List<Wallet>>(
      stream: widget.ndkFlutter.ndk.wallets.walletsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        Wallet? wallet;
        for (final candidate in snapshot.data!) {
          if (candidate.id == widget.selectedWalletId) {
            wallet = candidate;
            break;
          }
        }
        if (wallet == null) {
          _clearMissingWalletSelection();
          return const SizedBox.shrink();
        }
        final selectedWallet = wallet;

        final bool isCashu = selectedWallet is CashuWallet;
        final bool isNwc = selectedWallet is NwcWallet;
        final bool isBolt12 = selectedWallet is Bolt12Wallet;
        final bool canSend = selectedWallet.canSend;
        final bool canReceive = selectedWallet.canReceive;
        final bool condensed = widget.condensed;
        final bool showHeader = widget.showTitle || widget.showCloseButton;
        final double buttonPadding = condensed ? 8 : 16;

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showHeader) ...[
              Row(
                children: [
                  if (widget.showTitle) ...[
                    if (isCashu)
                      NCashuMintIcon(wallet: selectedWallet, size: 24)
                    else if (isNwc)
                      Image.asset(
                        'assets/images/nwc.png',
                        package: 'ndk_flutter',
                        width: 24,
                        height: 24,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.cloud, color: Colors.blue);
                        },
                      )
                    else if (isBolt12)
                      const Icon(Icons.electric_bolt, color: Colors.green)
                    else
                      const Icon(Icons.bolt, color: Colors.purple),
                    const SizedBox(width: 8),
                    Text(
                      isCashu
                          ? l10n.cashuWallet
                          : isNwc
                          ? l10n.nwcWallet
                          : isBolt12
                          ? l10n.bolt12Wallet
                          : l10n.lnurlWallet,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                  const Spacer(),
                  if (widget.showCloseButton)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: widget.onClearSelection,
                    ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
            ],
            if (canSend || canReceive)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (canSend)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            showSendDialog(context, selectedWallet),
                        icon: const Icon(Icons.send),
                        label: Text(l10n.send),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: buttonPadding,
                          ),
                        ),
                      ),
                    ),
                  if (canSend && canReceive)
                    SizedBox(width: condensed ? 8 : 16),
                  if (canReceive)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            showReceiveFlow(context, selectedWallet),
                        icon: const Icon(Icons.download),
                        label: Text(l10n.receive),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: buttonPadding,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        );

        if (condensed) return content;

        return Card(
          elevation: 4,
          child: Padding(padding: const EdgeInsets.all(20), child: content),
        );
      },
    );
  }
}
