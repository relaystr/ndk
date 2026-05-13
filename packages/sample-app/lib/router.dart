import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ndk_demo/l10n/app_localizations_context.dart';

import 'accounts_page.dart';
import 'blossom_page.dart';
import 'home_page.dart';
import 'main.dart';
import 'profile_page.dart';
import 'quantum_secure_page.dart';
import 'relays_page.dart';
import 'wallets.dart';
import 'widgets_demo_page.dart';

final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/',
      redirect: (_, __) => '/home',
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/accounts',
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.tabAccounts)),
        body: const AccountsPage(),
      ),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.tabProfile)),
        body: ProfilePage(
          ndkFlutter: ndkFlutter,
          getLoggedPubkey: () => ndk.accounts.getPublicKey(),
        ),
      ),
    ),
    GoRoute(
      path: '/relays',
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.tabRelays)),
        body: const RelaysPage(),
      ),
    ),
    GoRoute(
      path: '/blossom',
      builder: (context, state) => BlossomMediaPage(ndk: ndk),
    ),
    GoRoute(
      path: '/wallets',
      builder: (context, state) => WalletsPage(
        initialUrl: state.extra as String?,
      ),
    ),
    GoRoute(
      path: '/widgets',
      builder: (context, state) => const WidgetsDemoPage(),
    ),
    GoRoute(
      path: '/quantum',
      builder: (context, state) => const QuantumSecurePage(),
    ),
  ],
);
