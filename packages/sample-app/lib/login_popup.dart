import 'package:material_ui/material_ui.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_demo/l10n/app_localizations_context.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

const _clientMetadata = Nip46ClientMetadata(name: 'NDK sample app');

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
              clientMetadata: _clientMetadata,
              nostrConnect: ndkFlutter.ndk.bunkers.createNostrConnect(
                clientMetadata: _clientMetadata,
                relays: [
                  "wss://promenade.fiatjaf.com",
                  "wss://relay.ditto.pub",
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
