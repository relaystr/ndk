import 'package:flutter/material.dart';
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
    await showNLoginPopup(
      context: context,
      ndkFlutter: ndkFlutter,
      title: ndk.accounts.getPublicKey() == null ? 'Log in' : 'Add account',
      onLoggedIn: () {
        if (!mounted) return;
        setState(() {});
        widget.onAccountChanged?.call();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ndk.accounts.getPublicKey() != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accounts',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your logged accounts and add new ones.',
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
                label: Text(isLoggedIn ? 'Add Another Account' : 'Log In'),
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
