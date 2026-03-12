import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ndk/entities.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

import '../../l10n/app_localizations.dart';

/// Vertical list of recent transactions combined across wallets.
class NRecentTransactions extends StatelessWidget {
  final NdkFlutter ndkFlutter;

  /// Optional localized empty-label when there are no transactions.
  final String? emptyLabel;

  const NRecentTransactions({
    super.key,
    required this.ndkFlutter,
    this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<List<WalletTransaction>>(
      stream: ndkFlutter.ndk.wallets.combinedRecentTransactions,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('${l10n.error}: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text(emptyLabel ?? l10n.noRecentTransactions));
        } else {
          final transactions = snapshot.data!;
          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              return ListTile(
                leading: Icon(
                  tx.changeAmount > 0 ? Icons.download : Icons.send,
                  color: tx.changeAmount > 0 ? Colors.green : Colors.orange,
                ),
                title: Text(
                  '${tx.changeAmount.abs()} ${tx.unit}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${tx.walletType.name} • ${tx.state.value}'),
                trailing: tx is CashuWalletTransaction && tx.token != null
                    ? IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: tx.token!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.tokenCopied)),
                          );
                        },
                      )
                    : null,
              );
            },
          );
        }
      },
    );
  }
}
