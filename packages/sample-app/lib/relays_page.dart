import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ndk/data_layer/repositories/nostr_transport/websocket_client_nostr_transport.dart';
import 'package:ndk/entities.dart';
import 'package:ndk_demo/l10n/app_localizations_context.dart';

import 'main.dart';

class RelaysPage extends StatefulWidget {
  const RelaysPage({super.key});

  @override
  State<RelaysPage> createState() => _RelaysPageState();
}

class _RelaysPageState extends State<RelaysPage>
    with AutomaticKeepAliveClientMixin {
  UserRelayList? relays;
  bool _isLoadingRelayList = true;
  StreamSubscription<dynamic>? _relayConnectivitySub;

  Widget _buildRelayCard(
    BuildContext context, {
    required String url,
    required ReadWriteMarker marker,
    required Color stateColor,
    required String stateLabel,
  }) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: stateColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        url,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.relayConnection(stateLabel),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: stateColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    stateLabel,
                    style: TextStyle(
                      color: stateColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (marker.isRead)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      l10n.relayRead,
                      style: TextStyle(color: colorScheme.onPrimaryContainer),
                    ),
                  ),
                if (marker.isWrite)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      l10n.relayWrite,
                      style: TextStyle(color: colorScheme.onSecondaryContainer),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadRelayList({bool forceRefresh = false}) async {
    final pubkey = ndk.accounts.getPublicKey();
    if (pubkey == null) {
      if (!mounted) return;
      setState(() {
        relays = null;
        _isLoadingRelayList = false;
      });
      return;
    }

    final list = await ndk.userRelayLists.getSingleUserRelayList(
      pubkey,
      forceRefresh: forceRefresh,
    );

    if (list != null) {
      for (final url in list.relays.keys) {
        await ndk.relays.connectRelay(
          dirtyUrl: url,
          connectionSource: ConnectionSource.unknown,
        );
      }
    }

    if (!mounted) return;
    setState(() {
      relays = list;
      _isLoadingRelayList = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadRelayList();
    _relayConnectivitySub = ndk.connectivity.relayConnectivityChanges.listen((
      data,
    ) {
      setState(() {
        print("Relay connectivity changed for $data");
      });
    });
  }

  @override
  void dispose() {
    _relayConnectivitySub?.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = context.l10n;
    if (_isLoadingRelayList) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (ndk.accounts.getPublicKey() == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(l10n.relaysLoginRequired),
        ),
      );
    }

    if (relays == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FilledButton.icon(
            onPressed: () async {
              setState(() {
                _isLoadingRelayList = true;
              });
              await _loadRelayList(forceRefresh: true);
            },
            icon: const Icon(Icons.cloud_download_outlined),
            label: Text(l10n.relaysFetchButton),
          ),
        ),
      );
    }

    final entries = relays!.relays.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: entries.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.relayListHeading,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.relayConfiguredCount(entries.length),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        final entry = entries[index - 1];
        final transport = ndk.relays
            .getRelayConnectivity(entry.key)
            ?.relayTransport as WebSocketClientNostrTransport?;
        final stateColor = transport != null
            ? transport.isConnecting()
                ? Colors.orange
                : transport.isOpen()
                    ? Colors.green
                    : Colors.red
            : Colors.grey;
        final stateLabel = transport != null
            ? transport.isConnecting()
                ? l10n.relayStateConnecting
                : transport.isOpen()
                    ? l10n.relayStateOnline
                    : l10n.relayStateOffline
            : l10n.relayStateUnknown;

        return _buildRelayCard(
          context,
          url: entry.key,
          marker: entry.value,
          stateColor: stateColor,
          stateLabel: stateLabel,
        );
      },
    );
  }
}
