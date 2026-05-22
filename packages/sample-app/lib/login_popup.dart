import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_demo/l10n/app_localizations_context.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

Future<void> showNLoginPopup({
  required BuildContext context,
  required NdkFlutter ndkFlutter,
  required VoidCallback onLoggedIn,
  String title = 'Log in',
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final l10n = dialogContext.l10n;
      return AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 16, 8, 0),
        title: Row(
          children: [
            Expanded(child: Text(title)),
            IconButton(
              tooltip: l10n.closeTooltip,
              onPressed: () => Navigator.of(dialogContext).pop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: NLogin(
              ndkFlutter: ndkFlutter,
              nostrConnect: NostrConnect(
                appName: 'NDK sample app',
                relays: [
                  "wss://relay.damus.io",
                  "wss://relay.primal.net",
                  "wss://relay.nmail.li",
                ],
              ),
              onLoggedIn: () {
                Navigator.of(dialogContext).pop();
                onLoggedIn();
              },
            ),
          ),
        ),
      );
    },
  );
}
