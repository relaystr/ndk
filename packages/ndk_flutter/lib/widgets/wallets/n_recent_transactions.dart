import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';

/// Vertical list of recent transactions combined across wallets.
class NRecentTransactions extends StatelessWidget {
  final Ndk ndk;

  /// Optional localized empty-label when there are no transactions.
  final String? emptyLabel;

  const NRecentTransactions({
    super.key,
    required this.ndk,
    this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WalletTransaction>>(
      stream: ndk.wallets.combinedRecentTransactions,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(emptyLabel ?? 'No recent transactions'),
          );
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
                            const SnackBar(content: Text('Token copied')),
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

