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
        title: Text(AppLocalizations.of(context)!.nostrConnectUrl),
        content: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Spacer(),
            AspectRatio(
              aspectRatio: 1,
              child: PrettyQrView.data(
                data: nostrConnectURL,
                decoration: const PrettyQrDecoration(
                  shape: PrettyQrShape.custom(PrettyQrDotsSymbol()),
                ),
              ),
            ),
            Spacer(),
          ],
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
