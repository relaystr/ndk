import 'package:flutter/material.dart';
import 'package:ndk_demo/l10n/app_localizations_context.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

import 'login_popup.dart';
import 'main.dart';
import 'pending_requests_page.dart';

class AccountsPage extends StatefulWidget {
  final VoidCallback? onAccountChanged;

  const AccountsPage({super.key, this.onAccountChanged});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  Future<void> _openLoginPopup() async {
    final l10n = context.l10n;
    await showNLoginPopup(
      context: context,
      ndkFlutter: ndkFlutter,
      title: ndk.accounts.getPublicKey() == null
          ? l10n.loginDialogDefaultTitle
          : l10n.loginDialogAddAccountTitle,
      onLoggedIn: () {
        if (!mounted) return;
        setState(() {});
        widget.onAccountChanged?.call();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isLoggedIn = ndk.accounts.getPublicKey() != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.accountsHeading,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.accountsDescription,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
          const SizedBox(height: 16),
          if (isLoggedIn)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: NSwitchAccount(
                  ndkFlutter: ndkFlutter,
                  onAccountSwitch: (pubkey) {
                    setState(() {});
                    widget.onAccountChanged?.call();
                  },
                  onAccountRemove: (pubkey) {
                    setState(() {});
                    widget.onAccountChanged?.call();
                  },
                ),
              ),
            ),
          if (isLoggedIn) const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: _openLoginPopup,
                icon: const Icon(Icons.person_add),
                label: Text(
                  isLoggedIn ? l10n.addAnotherAccount : l10n.logIn,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const PendingRequestsPage(embedded: true),
        ],
      ),
    );
  }
}
