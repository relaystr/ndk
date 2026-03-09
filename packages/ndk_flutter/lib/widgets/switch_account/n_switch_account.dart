import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/ndk_flutter.dart';
import 'package:ndk_flutter/l10n/app_localizations.dart';
import 'package:nip07_event_signer/nip07_event_signer.dart';

class NSwitchAccount extends StatefulWidget {
  final NdkFlutter ndkFlutter;
  final void Function(String pubkey)? onAccountSwitch;
  final void Function(String pubkey)? onAccountRemove;
  final void Function()? onAddAccount;
  final void Function(String pubkey)? beforeAccountSwitch;
  final void Function(String pubkey)? beforeAccountRemove;

  Ndk get ndk => ndkFlutter.ndk;

  const NSwitchAccount({
    super.key,
    required this.ndkFlutter,
    this.onAccountSwitch,
    this.onAccountRemove,
    this.onAddAccount,
    this.beforeAccountSwitch,
    this.beforeAccountRemove,
  });

  @override
  State<NSwitchAccount> createState() => _NSwitchAccountState();
}

class _NSwitchAccountState extends State<NSwitchAccount> {
  Ndk get ndk => widget.ndk;

  Widget _getAccountTypeChip(BuildContext context, Account account) {
    String label;
    Color backgroundColor;
    final l10n = AppLocalizations.of(context)!;

    switch (account.type) {
      case AccountType.publicKey:
        label = l10n.readOnly;
        backgroundColor = Colors.blue;
        break;
      case AccountType.privateKey:
        label = l10n.nsec;
        backgroundColor = Colors.red;
        break;
      case AccountType.externalSigner:
        if (account.signer is Nip07EventSigner) {
          label = l10n.extension;
          backgroundColor = Colors.orange;
        } else {
          label = l10n.bunker;
          backgroundColor = Colors.green;
        }
        break;
    }

    return Chip(
      label: Text(label),
      backgroundColor: backgroundColor.withValues(alpha: 0.2),
      side: BorderSide(color: backgroundColor),
      shape: StadiumBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ndk.accounts.accounts.values.toList();
    final loggedPubkey = ndk.accounts.getPublicKey();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...accounts.map((account) {
          final pubkey = account.pubkey;
          final isLoggedAccount = loggedPubkey == pubkey;

          Widget? subtitle;
          void Function()? onTap;
          if (!isLoggedAccount) {
            subtitle = Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  widget.beforeAccountRemove?.call(pubkey);
                  ndk.accounts.removeAccount(pubkey: pubkey);
                  widget.ndkFlutter.saveAccountsState();
                  setState(() {});
                  widget.onAccountRemove?.call(pubkey);
                },
                child: Text(AppLocalizations.of(context)!.logout),
              ),
            );

            onTap = () {
              widget.beforeAccountSwitch?.call(pubkey);
              ndk.accounts.switchAccount(pubkey: pubkey);
              widget.ndkFlutter.saveAccountsState();
              setState(() {});
              widget.onAccountSwitch?.call(pubkey);
            };
          }

          return ListTile(
            leading: NPicture(ndkFlutter: widget.ndkFlutter, pubkey: pubkey),
            title: NName(ndkFlutter: widget.ndkFlutter, pubkey: pubkey),
            subtitle: subtitle,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _getAccountTypeChip(context, account),
                SizedBox(width: 8),
                Opacity(
                  opacity: isLoggedAccount ? 1 : 0,
                  child: Icon(
                    Icons.radio_button_checked,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            onTap: onTap,
          );
        }),
        if (widget.onAddAccount != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: TextButton.icon(
              onPressed: widget.onAddAccount,
              label: Text(AppLocalizations.of(context)!.addAccount),
              icon: Icon(Icons.add_circle_outline),
            ),
          ),
      ],
    );
  }
}
