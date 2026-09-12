import 'package:flutter/material.dart';
import 'package:ndk/entities.dart';

/// Displays Cashu mint's NUT-06 icon with bundled Cashu asset fallback.
class NCashuMintIcon extends StatelessWidget {
  final CashuWallet wallet;
  final double size;
  final BorderRadius borderRadius;

  const NCashuMintIcon({
    super.key,
    required this.wallet,
    required this.size,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  Widget _fallback() {
    return Image.asset(
      'assets/images/cashu.png',
      package: 'ndk_flutter',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) =>
          Icon(Icons.account_balance_wallet, color: Colors.orange, size: size),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconUrl = wallet.mintInfo.iconUrl?.trim();
    return ClipRRect(
      borderRadius: borderRadius,
      child: iconUrl?.isNotEmpty == true
          ? Image.network(
              iconUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallback(),
            )
          : _fallback(),
    );
  }
}
