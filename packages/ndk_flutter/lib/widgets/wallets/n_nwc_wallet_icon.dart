import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ndk/entities.dart';

class NNwcWalletIcon extends StatelessWidget {
  final NwcWallet wallet;
  final double size;

  const NNwcWalletIcon({super.key, required this.wallet, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return switch (wallet.providerId) {
      'alby' => _BrandIconFrame(
        size: size,
        backgroundColor: Colors.white,
        child: SvgPicture.asset(
          'assets/images/albyhub.svg',
          package: 'ndk_flutter',
          width: size * 0.625,
          height: size * 0.625,
        ),
      ),
      'coinos' => _BrandIconFrame(
        size: size,
        backgroundColor: Colors.white,
        child: SvgPicture.asset(
          'assets/images/coinos.svg',
          package: 'ndk_flutter',
          width: size * 0.75,
          height: size * 0.75,
        ),
      ),
      _ => Image.asset(
        'assets/images/nwc.png',
        package: 'ndk_flutter',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    };
  }
}

class _BrandIconFrame extends StatelessWidget {
  final double size;
  final Color backgroundColor;
  final Widget child;

  const _BrandIconFrame({
    required this.size,
    required this.backgroundColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Center(child: child),
    );
  }
}
