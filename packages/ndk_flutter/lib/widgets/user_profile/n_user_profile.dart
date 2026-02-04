import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/l10n/app_localizations.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

class NUserProfile extends StatelessWidget {
  final Ndk ndk;
  final String? pubkey;
  final Metadata? metadata;
  final bool showLogoutButton;
  final bool showName;
  final bool showNip05Indicator;
  final bool showNip05;
  final VoidCallback? onLogout;

  String? get profilePubkey =>
      metadata?.pubKey ?? pubkey ?? ndk.accounts.getPublicKey();

  const NUserProfile({
    super.key,
    required this.ndk,
    this.pubkey,
    this.metadata,
    this.showLogoutButton = true,
    this.showName = true,
    this.showNip05Indicator = true,
    this.showNip05 = true,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    if (profilePubkey == null) return Container();

    // If metadata is provided, use it directly
    if (metadata != null) {
      return _buildProfile(context, metadata);
    }

    // Otherwise, load metadata
    return FutureBuilder(
      future: ndk.metadata.loadMetadata(profilePubkey!),
      builder: (context, snapshot) {
        return _buildProfile(context, snapshot.data);
      },
    );
  }

  Widget _buildProfile(BuildContext context, Metadata? metadata) {
    String name = _formatNpub(profilePubkey!);
    String? nip05;

    // Check if this is the logged account
    final isLoggedAccount = profilePubkey == ndk.accounts.getPublicKey();

    if (metadata != null) {
      name = metadata.getName();

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
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: NBanner(
                        ndk: ndk,
                        pubkey: profilePubkey,
                        metadata: metadata,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Visibility(
                  visible: showLogoutButton && isLoggedAccount,
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
                  child: NPicture(
                    ndk: ndk,
                    metadata: metadata,
                    pubkey: profilePubkey,
                    circleAvatarRadius: 40,
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
          Text(nip05, style: TextStyle(color: Theme.of(context).disabledColor)),
      ],
    );
  }

  String _formatPubkey(String pubkey) {
    return '${pubkey.substring(0, 6)}...${pubkey.substring(pubkey.length - 6)}';
  }

  String _formatNpub(String pubkey) {
    try {
      final npub = Nip19.encodePubKey(pubkey);
      return '${npub.substring(0, 6)}...${npub.substring(npub.length - 6)}';
    } catch (e) {
      return _formatPubkey(pubkey);
    }
  }
}
