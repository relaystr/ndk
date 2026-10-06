import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NLnBitsIcon extends StatelessWidget {
  final double size;
  final bool showShadow;

  const NLnBitsIcon({super.key, this.size = 64, this.showShadow = false});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF673AB7),
        borderRadius: BorderRadius.circular(size / 4),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: dark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.25),
                  offset: const Offset(0, 10),
                  blurRadius: 15,
                ),
              ]
            : null,
      ),
      child: SvgPicture.asset(
        'assets/images/lnbits.svg',
        package: 'ndk_flutter',
        width: size,
        height: size,
      ),
    );
  }
}
