import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'linux_qr_scanner.dart';

/// Camera adapter only. Wallet input UI and navigation belong to ndk_flutter.
Widget buildWalletQrScanner(
  BuildContext context,
  ValueChanged<String> onScan,
  ValueChanged<Object> onError,
) {
  if (kIsWeb || defaultTargetPlatform == TargetPlatform.linux) {
    return FullFrameQrScanner(onScan: onScan, onError: onError);
  }
  return MobileScanner(
    onDetect: (capture) {
      for (final barcode in capture.barcodes) {
        final value = barcode.rawValue?.trim();
        if (value != null && value.isNotEmpty) {
          onScan(value);
          break;
        }
      }
    },
    errorBuilder: (context, error) {
      // Report after build so the parent can display its shared error UI.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) onError(error);
      });
      return const SizedBox.shrink();
    },
  );
}
