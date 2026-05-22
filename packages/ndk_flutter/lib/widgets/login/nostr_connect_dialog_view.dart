import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ndk_flutter/l10n/app_localizations.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class NostrConnectDialogView extends StatelessWidget {
  final String nostrConnectURL;

  const NostrConnectDialogView({super.key, required this.nostrConnectURL});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light(),
      child: AlertDialog(
        backgroundColor: Colors.white,
        title: Text(AppLocalizations.of(context)!.nostrConnectUrl),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300, maxHeight: 300),
          child: AspectRatio(
            aspectRatio: 1,
            child: PrettyQrView.data(
              data: nostrConnectURL,
              decoration: const PrettyQrDecoration(
                quietZone: PrettyQrQuietZone.standard,
                shape: PrettyQrSmoothSymbol(
                  roundFactor: 0,
                ),
              ),
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: nostrConnectURL));
            },
            child: Text(AppLocalizations.of(context)!.copy),
          ),
        ],
      ),
    );
  }
}
