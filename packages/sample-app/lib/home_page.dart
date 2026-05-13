import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_demo/l10n/app_localizations_context.dart';
import 'package:ndk_demo/login_popup.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

import 'main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  StreamSubscription<Account?>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = ndk.accounts.authStateChanges.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final loggedPubkey = ndk.accounts.getPublicKey();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.appBarTitle),
            const SizedBox(width: 8),
            Text(
              'v$packageVersion',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          NLocaleSwitcher(
            currentLocale: localeNotifier.value,
            onLocaleChanged: (locale) => localeNotifier.value = locale,
          ),
          const SizedBox(width: 4),
          Builder(
            builder: (context) {
              final profileIcon = loggedPubkey == null
                  ? CircleAvatar(
                      radius: 14,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    )
                  : NPicture(ndkFlutter: ndkFlutter, circleAvatarRadius: 14);
              return IconButton(
                tooltip: l10n.profileTooltip,
                onPressed: () {
                  if (loggedPubkey != null) {
                    context.push('/profile');
                    return;
                  }
                  showNLoginPopup(
                    context: context,
                    ndkFlutter: ndkFlutter,
                    onLoggedIn: () {},
                  );
                },
                icon: profileIcon,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (loggedPubkey != null) ...[
            NUserProfile(
              key: ValueKey(loggedPubkey),
              ndkFlutter: ndkFlutter,
              onLogout: () => setState(() {}),
            ),
            const SizedBox(height: 16),
          ] else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.profileNoAccount,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => showNLoginPopup(
                        context: context,
                        ndkFlutter: ndkFlutter,
                        onLoggedIn: () {},
                      ),
                      icon: const Icon(Icons.login),
                      label: Text(l10n.logIn),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _NavCard(
            icon: Icons.manage_accounts,
            title: l10n.tabAccounts,
            onTap: () => context.push('/accounts'),
          ),
          const SizedBox(height: 8),
          _NavCard(
            icon: Icons.person,
            title: l10n.tabProfile,
            onTap: () => context.push('/profile'),
          ),
          const SizedBox(height: 8),
          _NavCard(
            icon: Icons.hub,
            title: l10n.tabRelays,
            onTap: () => context.push('/relays'),
          ),
          const SizedBox(height: 8),
          _NavCard(
            icon: Icons.cloud_upload,
            title: l10n.tabBlossom,
            onTap: () => context.push('/blossom'),
          ),
          const SizedBox(height: 8),
          _NavCard(
            icon: Icons.account_balance_wallet,
            title: l10n.tabWallets,
            onTap: () => context.push('/wallets'),
          ),
          const SizedBox(height: 8),
          _NavCard(
            icon: Icons.widgets,
            title: l10n.tabWidgets,
            onTap: () => context.push('/widgets'),
          ),
          const SizedBox(height: 8),
          _NavCard(
            icon: Icons.security,
            title: 'Quantum Secure',
            onTap: () => context.push('/quantum'),
          ),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _NavCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
