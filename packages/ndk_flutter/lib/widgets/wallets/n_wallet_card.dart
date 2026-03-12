import 'package:flutter/material.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/domain_layer/entities/wallet/providers/cashu/cashu_wallet.dart';
import 'package:ndk/domain_layer/entities/wallet/providers/lnurl/lnurl_wallet.dart';
import 'package:ndk/domain_layer/entities/wallet/providers/nwc/nwc_wallet.dart';
import 'package:ndk/ndk.dart';

/// Individual wallet card widget used by the wallets UI.
class NWalletCard extends StatelessWidget {
  final Wallet wallet;
  final Ndk ndk;
  final bool isSelected;
  final VoidCallback onTap;
  final Future<void> Function(BuildContext context, Wallet wallet)? onDelete;

  /// Width of the card. Defaults to 280.
  final double width;

  const NWalletCard({
    super.key,
    required this.wallet,
    required this.ndk,
    required this.isSelected,
    required this.onTap,
    this.onDelete,
    this.width = 280,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCashu = wallet is CashuWallet;
    final bool isNwc = wallet is NwcWallet;
    final bool isLnurl = wallet is LnurlWallet;

    final String walletName;
    if (isCashu) {
      walletName = (wallet as CashuWallet).mintInfo.name ?? 'Cashu';
    } else if (isNwc) {
      walletName = (wallet as NwcWallet).name;
    } else if (isLnurl) {
      walletName = (wallet as LnurlWallet).name;
    } else {
      walletName = 'Unknown';
    }

    final String subtitle;
    if (isCashu) {
      subtitle = (wallet as CashuWallet).mintUrl.replaceAll('https://', '');
    } else if (isNwc) {
      subtitle = 'NWC Wallet';
    } else if (isLnurl) {
      subtitle = (wallet as LnurlWallet).identifier;
    } else {
      subtitle = '';
    }

    final List<Color> gradientColors;
    final Color shadowColor;
    if (isCashu) {
      gradientColors = [Colors.orange[700]!, Colors.orange[400]!];
      shadowColor = Colors.orange;
    } else if (isNwc) {
      gradientColors = [Colors.blue[700]!, Colors.blue[400]!];
      shadowColor = Colors.blue;
    } else if (isLnurl) {
      gradientColors = [Colors.purple[700]!, Colors.purple[400]!];
      shadowColor = Colors.purple;
    } else {
      gradientColors = [Colors.grey[700]!, Colors.grey[400]!];
      shadowColor = Colors.grey;
    }

    final IconData walletIcon;
    if (isCashu) {
      walletIcon = Icons.account_balance_wallet;
    } else if (isNwc) {
      walletIcon = Icons.cloud;
    } else if (isLnurl) {
      walletIcon = Icons.bolt;
    } else {
      walletIcon = Icons.wallet;
    }

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
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                walletIcon,
                size: 120,
                color: Colors.white.withAlpha(30),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(walletIcon, color: Colors.white, size: 32),
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
                          child: const Text(
                            'SELECTED',
                            style: TextStyle(
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
    if (lnWallet.minSendable != null && lnWallet.maxSendable != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Receive-only wallet',
            style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Receive: ${lnWallet.minSendable! ~/ 1000} - ${lnWallet.maxSendable! ~/ 1000} sats',
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
      'Limits unavailable',
      style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12),
    );
  }

  Widget _buildBalance(BuildContext context) {
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
              'sats',
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
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await ndk.wallets.removeWallet(wallet.id);
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
