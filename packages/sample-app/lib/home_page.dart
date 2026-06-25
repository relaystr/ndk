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
  VoidCallback? _dmListener;

  @override
  void initState() {
    super.initState();
    _authSub = ndk.accounts.authStateChanges.listen((_) {
      if (mounted) setState(() {});
    });
    _dmListener = () {
      if (mounted) {
        setState(() {});
      }
    };
    dmLiveState.addListener(_dmListener!);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    if (_dmListener != null) {
      dmLiveState.removeListener(_dmListener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final loggedPubkey = ndk.accounts.getPublicKey();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${l10n.appBarTitle} · v$packageVersion',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
              final unreadDmCount =
                  loggedPubkey == null ? 0 : dmLiveState.unreadCount;
              return IconButton(
                tooltip: l10n.profileTooltip,
                onPressed: () {
                  final unreadTargetPubKey = dmLiveState.latestUnreadPeerPubKey;
                  final unreadPeerCount = dmLiveState.unreadPeerCount;
                  if (loggedPubkey != null && unreadDmCount > 0) {
                    if (unreadPeerCount == 1 && unreadTargetPubKey != null) {
                      dmLiveState.clearUnreadForPeer(unreadTargetPubKey);
                      context.push('/dm/conversation/$unreadTargetPubKey');
                      return;
                    }
                    context.push('/dm');
                    return;
                  }
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
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    profileIcon,
                    if (unreadDmCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 1,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadDmCount > 99 ? '99+' : '$unreadDmCount',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onError,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ),
                  ],
                ),
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
            icon: Icons.people_alt_outlined,
            title: 'Follows',
            onTap: () => context.push('/follows'),
          ),
          const SizedBox(height: 8),
          _NavCard(
            icon: Icons.forum,
            title: 'DM',
            trailing: loggedPubkey != null && dmLiveState.unreadCount > 0
                ? _UnreadBadge(count: dmLiveState.unreadCount)
                : null,
            onTap: () {
              final unreadTargetPubKey = dmLiveState.latestUnreadPeerPubKey;
              final unreadPeerCount = dmLiveState.unreadPeerCount;
              if (loggedPubkey != null && dmLiveState.unreadCount > 0) {
                if (unreadPeerCount == 1 && unreadTargetPubKey != null) {
                  dmLiveState.clearUnreadForPeer(unreadTargetPubKey);
                  context.push('/dm/conversation/$unreadTargetPubKey');
                  return;
                }
              }
              context.push('/dm');
            },
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
  final Widget? trailing;

  const _NavCard({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onError,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
