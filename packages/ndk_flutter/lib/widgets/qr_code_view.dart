import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

class QrCodeView extends StatelessWidget {
  final String data;
  final Color foregroundColor;
  final Color backgroundColor;

  const QrCodeView({
    super.key,
    required this.data,
    this.foregroundColor = Colors.black,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final qrImage = QrImage(
      QrCode(
        payload: QrPayload.fromString(data),
        errorCorrectLevel: QrErrorCorrectLevel.medium,
      ),
    );

    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _QrCodePainter(
          qrImage,
          foregroundColor: foregroundColor,
          backgroundColor: backgroundColor,
        ),
      ),
    );
  }
}

class _QrCodePainter extends CustomPainter {
  final QrImage qrImage;
  final Color foregroundColor;
  final Color backgroundColor;

  const _QrCodePainter(
    this.qrImage, {
    required this.foregroundColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    const quietZone = 4;
    final moduleCount = qrImage.moduleCount;
    final totalModules = moduleCount + quietZone * 2;
    final qrSize = math.min(size.width, size.height);
    final moduleSize = qrSize / totalModules;
    final left = (size.width - qrSize) / 2 + quietZone * moduleSize;
    final top = (size.height - qrSize) / 2 + quietZone * moduleSize;
    final modulesPath = Path();

    for (var row = 0; row < moduleCount; row++) {
      for (var column = 0; column < moduleCount; column++) {
        if (qrImage.isDark(row, column)) {
          modulesPath.addRect(
            Rect.fromLTWH(
              left + column * moduleSize,
              top + row * moduleSize,
              moduleSize,
              moduleSize,
            ),
          );
        }
      }
    }

    canvas.drawPath(
      modulesPath,
      Paint()
        ..color = foregroundColor
        ..isAntiAlias = false,
    );
  }

  @override
  bool shouldRepaint(_QrCodePainter oldDelegate) =>
      qrImage != oldDelegate.qrImage ||
      foregroundColor != oldDelegate.foregroundColor ||
      backgroundColor != oldDelegate.backgroundColor;
}
