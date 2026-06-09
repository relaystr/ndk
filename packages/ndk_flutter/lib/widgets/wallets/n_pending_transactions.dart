import 'package:flutter/material.dart';
import 'package:ndk/entities.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

import '../../l10n/app_localizations.dart';

/// Horizontal list of pending wallet transactions for a specific wallet when
/// provided.
class NPendingTransactions extends StatefulWidget {
  final NdkFlutter ndkFlutter;
  final String? walletId;

  /// Optional localized title; defaults to English "Pending".
  final String? title;

  /// Height of the horizontal list.
  final double height;

  const NPendingTransactions({
    super.key,
    required this.ndkFlutter,
    this.walletId,
    this.title,
    this.height = 100,
  });

  @override
  State<NPendingTransactions> createState() => _NPendingTransactionsState();
}

class _NPendingTransactionsState extends State<NPendingTransactions> {
  final Map<String, CashuWalletTransaction> _updatedTransactions = {};
  final Map<String, bool> _isRetrieving = {};
  final Map<String, String?> _errorMessages = {};

  Future<void> _retrieveFunds(CashuWalletTransaction transaction) async {
    setState(() {
      _isRetrieving[transaction.id] = true;
      _errorMessages[transaction.id] = null;
      _updatedTransactions[transaction.id] = transaction;
    });

    try {
      final stream = widget.ndkFlutter.ndk.cashu.retrieveFunds(
        draftTransaction: transaction,
      );

      await for (final event in stream) {
        setState(() {
          _updatedTransactions[transaction.id] = event;
        });

        if (event.state == WalletTransactionState.completed) {
          setState(() {
            _isRetrieving[transaction.id] = false;
          });
          break;
        } else if (event.state == WalletTransactionState.failed) {
          setState(() {
            _isRetrieving[transaction.id] = false;
            _errorMessages[transaction.id] =
                event.completionMsg ?? 'Failed to retrieve funds';
          });
          break;
        }
      }
    } catch (e) {
      setState(() {
        _isRetrieving[transaction.id] = false;
        _errorMessages[transaction.id] = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stream = widget.walletId == null
        ? widget.ndkFlutter.ndk.wallets.combinedPendingTransactions
        : widget.ndkFlutter.ndk.wallets.getPendingTransactionsStream(
            widget.walletId!,
          );
    return StreamBuilder<List<WalletTransaction>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title ?? l10n.pendingTransactions,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '${l10n.error}: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
            ],
          );
        }

        final transactions = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title ?? l10n.pendingTransactions,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final originalTx = transactions[index];
                  final tx = _updatedTransactions[originalTx.id] ?? originalTx;
                  final isRetrieving = _isRetrieving[tx.id] == true;
                  final errorMessage = _errorMessages[tx.id];

                  return Card(
                    margin: const EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 200,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  tx.changeAmount > 0
                                      ? Icons.download
                                      : Icons.send,
                                  size: 16,
                                  color: tx.changeAmount > 0
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${tx.changeAmount.abs()} ${tx.unit}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tx.walletType.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tx.state.value,
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    tx.state == WalletTransactionState.pending
                                    ? Colors.orange
                                    : Colors.grey,
                              ),
                            ),
                            if (tx is CashuWalletTransaction &&
                                tx.state == WalletTransactionState.pending)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextButton(
                                        onPressed: isRetrieving
                                            ? null
                                            : () => _retrieveFunds(tx),
                                        child: isRetrieving
                                            ? const SizedBox(
                                                height: 16,
                                                width: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Text('Retrieve'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  errorMessage,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
