import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

/// State of the pending requests widget
enum NPendingRequestsState { hidden, collapsed, expanded }

/// A widget that displays pending signer requests (for Amber, bunker, extension).
///
/// This widget shows a floating panel at the bottom of the screen when there are
/// pending requests waiting for user approval on external signers.
///
/// Example usage:
/// ```dart
/// Stack(
///   children: [
///     YourMainContent(),
///     NPendingRequests(ndkFlutter: ndkFlutter),
///   ],
/// )
/// ```
class NPendingRequests extends StatefulWidget {
  final NdkFlutter ndkFlutter;

  /// Horizontal margin from screen edges
  final double horizontalMargin;

  /// Bottom margin from screen edge
  final double bottomMargin;

  /// Animation duration
  final Duration animationDuration;

  /// Custom builder for the collapsed content
  final Widget Function(BuildContext context, int count, String signerName)?
  collapsedBuilder;

  /// Custom builder for the expanded content
  final Widget Function(
    BuildContext context,
    List<PendingSignerRequest> requests,
    String signerName,
    void Function(String requestId) onCancel,
  )?
  expandedBuilder;

  const NPendingRequests({
    super.key,
    required this.ndkFlutter,
    this.horizontalMargin = 16,
    this.bottomMargin = 16,
    this.animationDuration = const Duration(milliseconds: 200),
    this.collapsedBuilder,
    this.expandedBuilder,
  });

  @override
  State<NPendingRequests> createState() => _NPendingRequestsState();
}

class _NPendingRequestsState extends State<NPendingRequests> {
  List<PendingSignerRequest> _pendingRequests = [];
  NPendingRequestsState _state = NPendingRequestsState.hidden;

  StreamSubscription<List<PendingSignerRequest>>? _requestsSubscription;
  StreamSubscription<Account?>? _authSubscription;

  Ndk get _ndk => widget.ndkFlutter.ndk;

  @override
  void initState() {
    super.initState();
    _setupListener();
    _authSubscription = _ndk.accounts.authStateChanges.listen((_) {
      _setupListener();
    });
  }

  void _setupListener() {
    _requestsSubscription?.cancel();
    _requestsSubscription = null;

    final account = _ndk.accounts.getLoggedAccount();
    if (account == null) {
      setState(() {
        _pendingRequests = [];
        _state = NPendingRequestsState.hidden;
      });
      return;
    }

    final signer = account.signer;
    _requestsSubscription = signer.pendingRequestsStream.listen((requests) {
      setState(() {
        _pendingRequests = requests;
        _updateState();
      });
    });
  }

  void _updateState() {
    if (_pendingRequests.isEmpty) {
      _state = NPendingRequestsState.hidden;
    } else if (_state == NPendingRequestsState.hidden) {
      _state = NPendingRequestsState.collapsed;
    }
  }

  String get _signerName {
    final account = _ndk.accounts.getLoggedAccount();
    if (account == null) return 'signer';

    final signer = account.signer;
    final signerType = signer.runtimeType.toString();

    if (signerType.contains('Amber')) return 'Amber';
    if (signerType.contains('Nip46')) return 'bunker';
    if (signerType.contains('Nip07')) return 'extension';

    return 'signer';
  }

  void _toggle() {
    setState(() {
      if (_state == NPendingRequestsState.collapsed) {
        _state = NPendingRequestsState.expanded;
      } else if (_state == NPendingRequestsState.expanded) {
        _state = NPendingRequestsState.collapsed;
      }
    });
  }

  void _cancelRequest(String requestId) {
    final account = _ndk.accounts.getLoggedAccount();
    if (account == null) return;

    account.signer.cancelRequest(requestId);
  }

  @override
  void dispose() {
    _requestsSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVisible = _state != NPendingRequestsState.hidden;

    return AnimatedPositioned(
      duration: widget.animationDuration,
      curve: Curves.easeInOut,
      bottom: isVisible ? widget.bottomMargin : -100,
      left: widget.horizontalMargin,
      right: widget.horizontalMargin,
      child: AnimatedOpacity(
        duration: widget.animationDuration,
        curve: Curves.easeInOut,
        opacity: isVisible ? 1.0 : 0.0,
        child: Center(child: _buildContent(context)),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final isExpanded = _state == NPendingRequestsState.expanded;
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: widget.animationDuration,
      curve: Curves.easeInOut,
      constraints: BoxConstraints(
        maxWidth: isExpanded ? 400 : 350,
        maxHeight: isExpanded ? 300 : 48,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: isExpanded
            ? _buildExpandedContent(context)
            : _buildCollapsedContent(context),
      ),
    );
  }

  Widget _buildCollapsedContent(BuildContext context) {
    if (widget.collapsedBuilder != null) {
      return InkWell(
        onTap: _toggle,
        child: widget.collapsedBuilder!(
          context,
          _pendingRequests.length,
          _signerName,
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final count = _pendingRequests.length;

    return InkWell(
      onTap: _toggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              label: Text(count.toString()),
              backgroundColor: colorScheme.primary,
              textColor: colorScheme.onPrimary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '${count == 1 ? 'request' : 'requests'} waiting on $_signerName',
                style: TextStyle(color: colorScheme.onSurface, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.expand_less,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    if (widget.expandedBuilder != null) {
      return widget.expandedBuilder!(
        context,
        _pendingRequests,
        _signerName,
        _cancelRequest,
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: _toggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Badge(
                      label: Text(_pendingRequests.length.toString()),
                      backgroundColor: colorScheme.primary,
                      textColor: colorScheme.onPrimary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pending $_signerName requests',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.expand_more,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: colorScheme.outlineVariant),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _pendingRequests.length,
                itemBuilder: (context, index) {
                  final request = _pendingRequests[index];
                  return SizedBox(
                    width: constraints.maxWidth,
                    child: _buildRequestItem(context, request),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRequestItem(BuildContext context, PendingSignerRequest request) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.pending_outlined, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _formatMethod(request.method),
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 13,
                      ),
                    ),
                    if (request.method == SignerMethod.signEvent &&
                        request.event != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: ShapeDecoration(
                          color: colorScheme.secondaryContainer,
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          NostrKinds.getDescription(context, request.event!.kind),
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                    if (_getNipProtocol(request.method) != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: ShapeDecoration(
                          color: colorScheme.primaryContainer,
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          _getNipProtocol(request.method)!,
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  _formatTime(request.createdAt),
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _cancelRequest(request.id),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.error,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _formatMethod(SignerMethod method) {
    switch (method) {
      case SignerMethod.signEvent:
        return 'Sign event';
      case SignerMethod.getPublicKey:
        return 'Get public key';
      case SignerMethod.nip04Encrypt:
      case SignerMethod.nip44Encrypt:
        return 'Encrypt';
      case SignerMethod.nip04Decrypt:
      case SignerMethod.nip44Decrypt:
        return 'Decrypt';
      case SignerMethod.ping:
        return 'Ping';
      case SignerMethod.connect:
        return 'Connect';
    }
  }

  String? _getNipProtocol(SignerMethod method) {
    switch (method) {
      case SignerMethod.nip04Encrypt:
      case SignerMethod.nip04Decrypt:
        return 'NIP-04';
      case SignerMethod.nip44Encrypt:
      case SignerMethod.nip44Decrypt:
        return 'NIP-44';
      default:
        return null;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${diff.inHours}h ago';
    }
  }
}
