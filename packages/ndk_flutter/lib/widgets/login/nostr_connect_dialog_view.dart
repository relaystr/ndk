import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ndk_flutter/l10n/app_localizations.dart';

import '../qr_code_view.dart';

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
            child: QrCodeView(data: nostrConnectURL),
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
