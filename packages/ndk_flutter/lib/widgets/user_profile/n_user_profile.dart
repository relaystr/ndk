import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/l10n/app_localizations.dart';
import 'package:ndk_flutter/ndk_flutter.dart';
import 'package:nip19/nip19.dart';

class NUserProfile extends StatelessWidget {
  final Ndk ndk;
  final String? pubkey;
  final bool showLogoutButton;
  final bool showName;
  final bool showNip05Indicator;
  final bool showNip05;
  final VoidCallback? onLogout;

  String? get profilePubkey => pubkey ?? ndk.accounts.getPublicKey();

  const NUserProfile({
    super.key,
    required this.ndk,
    this.pubkey,
    this.showLogoutButton = true,
    this.showName = true,
    this.showNip05Indicator = true,
    this.showNip05 = true,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    if (profilePubkey == null) return Container();

    final pkColor = NdkFlutter.getColorFromPubkey(profilePubkey!);
    final pubkeyColorScheme = ColorScheme.fromSeed(
      seedColor: pkColor,
      brightness: Theme.of(context).brightness,
    );

    return FutureBuilder(
      future: ndk.metadata.loadMetadata(profilePubkey!),
      builder: (context, snapshot) {
        String name = _formatNpub(profilePubkey!);
        String? nip05;
        Widget banner = Container(
          height: 10,
          width: 10,
          color: pubkeyColorScheme.primaryContainer,
        );
        Widget picture = Container(height: 100, width: 100, color: pkColor);

        if (snapshot.hasData) {
          final metadata = snapshot.data!;
          name = metadata.getName();

          if (metadata.banner != null) {
            banner = Image.network(metadata.banner!, fit: BoxFit.cover);
          }

          if (metadata.picture != null) {
            picture = Image.network(metadata.picture!, fit: BoxFit.cover);
          }

          if (metadata.cleanNip05 != null) {
            nip05 = metadata.cleanNip05;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 100,
                        width: double.maxFinite,
                        child: FittedBox(fit: BoxFit.cover, child: banner),
                      ),
                    ),
                    SizedBox(height: 8),
                    Visibility(
                      visible: showLogoutButton,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FilledButton.icon(
                            onPressed: () async {
                              ndk.accounts.logout();

                              if (ndk.accounts.accounts.isNotEmpty) {
                                final pubkey =
                                    ndk.accounts.accounts.values.first.pubkey;
                                ndk.accounts.switchAccount(pubkey: pubkey);
                              }

                              await NdkFlutter(ndk: ndk).saveAccountsState();

                              if (onLogout != null) onLogout!();
                            },
                            label: Text(AppLocalizations.of(context)!.logout),
                            icon: Icon(Icons.logout),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                  ],
                ),
                Positioned(
                  bottom: 0,
                  left: 32,
                  child: ClipOval(
                    child: Container(
                      color: Theme.of(context).colorScheme.surface,
                      padding: EdgeInsets.all(8),
                      child: CircleAvatar(
                        radius: 40,
                        child: ClipOval(
                          child: AspectRatio(aspectRatio: 1, child: picture),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (showName || showNip05) SizedBox(height: 16),
            if (showName)
              Row(
                children: [
                  Text(name, style: Theme.of(context).textTheme.displaySmall),
                  if (showNip05Indicator && nip05 != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.verified,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            if (showNip05 && nip05 != null)
              Text(
                nip05,
                style: TextStyle(color: Theme.of(context).disabledColor),
              ),
          ],
        );
      },
    );
  }

  String _formatPubkey(String pubkey) {
    return '${pubkey.substring(0, 6)}...${pubkey.substring(pubkey.length - 6)}';
  }

  String _formatNpub(String pubkey) {
    try {
      final npub = Nip19.npubFromHex(pubkey);
      return '${npub.substring(0, 6)}...${npub.substring(npub.length - 6)}';
    } catch (e) {
      return _formatPubkey(pubkey);
    }
  }
}
