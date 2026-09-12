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
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) =>
          const Icon(Icons.account_balance_wallet, color: Colors.orange),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconUrl = wallet.mintInfo.iconUrl?.trim();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: borderRadius,
        border: Border.all(color: Colors.white.withAlpha(120)),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: iconUrl?.isNotEmpty == true
            ? Image.network(
                iconUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }
}
