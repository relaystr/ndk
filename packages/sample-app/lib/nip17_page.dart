import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ndk/entities.dart';
import 'package:ndk_flutter/widgets/widgets.dart';

import 'main.dart';

class DmInboxPage extends StatefulWidget {
  const DmInboxPage({super.key});

  @override
  State<DmInboxPage> createState() => _DmInboxPageState();
}

class _DmInboxPageState extends State<DmInboxPage> {
  List<Nip17Conversation> _conversations = const [];
  Map<String, Metadata> _peerMetadatas = const {};
  bool _loading = false;
  String? _error;
  VoidCallback? _dmListener;
  int _lastDmEventVersion = -1;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _lastDmEventVersion = dmLiveState.eventVersion;
    _dmListener = () {
      if (!mounted) return;
      if (_lastDmEventVersion == dmLiveState.eventVersion) {
        setState(() {});
        return;
      }
      _lastDmEventVersion = dmLiveState.eventVersion;
      _loadInbox(forceRefresh: false);
    };
    dmLiveState.addListener(_dmListener!);
    if (ndk.accounts.getPublicKey() != null) {
      _loadInbox(forceRefresh: false);
    }
  }

  @override
  void dispose() {
    if (_dmListener != null) {
      dmLiveState.removeListener(_dmListener!);
    }
    super.dispose();
  }

  Future<void> _loadInbox({required bool forceRefresh}) async {
    final loadGeneration = ++_loadGeneration;
    final myPubKey = ndk.accounts.getPublicKey();
    if (myPubKey == null) {
      setState(() {
        _error =
            'Log in first. This demo needs a signer and your own kind:10050 DM relay list.';
      });
      return;
    }

    setState(() {
      _loading = _conversations.isEmpty || forceRefresh;
      _error = null;
    });

    if (!forceRefresh) {
      try {
        final cachedConversations = await ndk.nip17.loadConversationsSnapshot();
        if (!mounted || loadGeneration != _loadGeneration) return;
        if (cachedConversations.isNotEmpty || _conversations.isEmpty) {
          setState(() {
            _conversations = cachedConversations;
            _loading = false;
          });
          unawaited(
            _loadPeerMetadatas(
              cachedConversations,
              loadGeneration: loadGeneration,
            ),
          );
        }
      } catch (_) {
        // Ignore cache snapshot failures and continue with network refresh.
      }
    }

    try {
      final conversations = await ndk.nip17.loadConversations(
        forceRefresh: forceRefresh,
      );
      if (!mounted || loadGeneration != _loadGeneration) return;
      setState(() {
        _conversations = conversations;
        _loading = false;
      });
      unawaited(
        _loadPeerMetadatas(
          conversations,
          loadGeneration: loadGeneration,
        ),
      );
    } catch (e) {
      if (!mounted || loadGeneration != _loadGeneration) return;
      setState(() {
        _error = 'Inbox load failed: $e';
      });
    } finally {
      if (mounted && loadGeneration == _loadGeneration) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadPeerMetadatas(
    List<Nip17Conversation> conversations, {
    required int loadGeneration,
  }) async {
    final peerPubKeys = conversations
        .map((conversation) => conversation.peerPubKey)
        .toSet()
        .toList();

    if (peerPubKeys.isEmpty) {
      if (!mounted || loadGeneration != _loadGeneration) {
        return;
      }
      setState(() {});
      return;
    }

    try {
      final metadatas = await ndk.metadata.loadMetadatas(
        peerPubKeys,
        null,
        onLoad: (metadata) {
          if (!mounted || loadGeneration != _loadGeneration) {
            return;
          }
          _applyLoadedMetadata(metadata);
        },
      );

      if (!mounted || loadGeneration != _loadGeneration) {
        return;
      }

      for (final metadata in metadatas) {
        _applyLoadedMetadata(metadata);
      }
    } finally {
      // no-op
    }
  }

  void _applyLoadedMetadata(Metadata metadata) {
    final current = _peerMetadatas[metadata.pubKey];
    if (current?.updatedAt == metadata.updatedAt &&
        current?.displayName == metadata.displayName &&
        current?.name == metadata.name &&
        current?.picture == metadata.picture) {
      return;
    }

    setState(() {
      _peerMetadatas = {
        ..._peerMetadatas,
        metadata.pubKey: metadata,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final myPubKey = ndk.accounts.getPublicKey();

    return Scaffold(
      appBar: AppBar(
        title: const Text('DM'),
        actions: [
          IconButton(
            tooltip: 'Refresh inbox',
            onPressed: myPubKey == null || _loading
                ? null
                : () => _loadInbox(forceRefresh: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(context, myPubKey),
      floatingActionButton: myPubKey == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/dm/compose'),
              icon: const Icon(Icons.edit),
              label: const Text('Compose'),
            ),
    );
  }

  Widget _buildBody(BuildContext context, String? myPubKey) {
    if (myPubKey == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Log in first to inspect your direct messages.'),
        ),
      );
    }

    if (_loading && _conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error ?? 'No conversations discovered yet.'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(_error!),
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _conversations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final conversation = _conversations[index];
              final unreadCount =
                  dmLiveState.unreadCountForPeer(conversation.peerPubKey);
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  leading: SizedBox(
                    width: 52,
                    height: 52,
                    child: NPicture(
                      ndkFlutter: ndkFlutter,
                      pubkey: conversation.peerPubKey,
                      metadata: _peerMetadatas[conversation.peerPubKey],
                      circleAvatarRadius: 26,
                    ),
                  ),
                  title: Text(_displayNameFor(conversation.peerPubKey)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _shorten(conversation.peerPubKey),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        conversation.latestMessage.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  trailing: unreadCount > 0
                      ? _ConversationUnreadBadge(count: unreadCount)
                      : const Icon(Icons.chevron_right),
                  onTap: () {
                    dmLiveState.clearUnreadForPeer(conversation.peerPubKey);
                    context.push('/dm/conversation/${conversation.peerPubKey}');
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _displayNameFor(String peerPubKey) {
    final metadata = _peerMetadatas[peerPubKey];
    final displayName = metadata?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    final name = metadata?.name?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return _shorten(peerPubKey);
  }
}

class DmConversationPage extends StatefulWidget {
  final String peerPubKey;

  const DmConversationPage({
    super.key,
    required this.peerPubKey,
  });

  @override
  State<DmConversationPage> createState() => _DmConversationPageState();
}

class _DmConversationPageState extends State<DmConversationPage> {
  List<Nip17Message> _messages = const [];
  Metadata? _peerMetadata;
  final _messageController = TextEditingController();
  bool _loading = false;
  bool _sending = false;
  String? _error;
  VoidCallback? _dmListener;
  int _lastDmEventVersion = -1;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    dmLiveState.clearUnreadForPeer(widget.peerPubKey);
    _lastDmEventVersion = dmLiveState.eventVersion;
    _dmListener = () {
      if (!mounted) return;
      dmLiveState.clearUnreadForPeer(widget.peerPubKey);
      if (_lastDmEventVersion == dmLiveState.eventVersion) {
        return;
      }
      _lastDmEventVersion = dmLiveState.eventVersion;
      _loadConversation(forceRefresh: false);
    };
    dmLiveState.addListener(_dmListener!);
    if (ndk.accounts.getPublicKey() != null) {
      _loadConversation(forceRefresh: false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    if (_dmListener != null) {
      dmLiveState.removeListener(_dmListener!);
    }
    super.dispose();
  }

  Future<void> _sendInlineMessage() async {
    final myPubKey = ndk.accounts.getPublicKey();
    final content = _messageController.text.trim();
    if (myPubKey == null || content.isEmpty || _sending) {
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await ndk.nip17.sendMessage(
        recipientPubKey: widget.peerPubKey,
        content: content,
      );
      _messageController.clear();
      if (!mounted) {
        return;
      }
      await _loadConversation(forceRefresh: false);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Send failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  Future<void> _loadConversation({required bool forceRefresh}) async {
    final loadGeneration = ++_loadGeneration;
    final myPubKey = ndk.accounts.getPublicKey();
    if (myPubKey == null) {
      setState(() {
        _error =
            'Log in first. This demo needs a signer and your own kind:10050 DM relay list.';
      });
      return;
    }

    setState(() {
      _loading = _messages.isEmpty || forceRefresh;
      _error = null;
    });

    if (!forceRefresh) {
      try {
        final cachedMessages = await ndk.nip17.loadConversationSnapshot(
          peerPubKey: widget.peerPubKey,
        );
        if (!mounted || loadGeneration != _loadGeneration) return;
        if (cachedMessages.isNotEmpty || _messages.isEmpty) {
          setState(() {
            _messages = cachedMessages;
            _loading = false;
          });
        }
      } catch (_) {
        // Ignore cache snapshot failures and continue with network refresh.
      }
    }

    unawaited(
      _loadPeerMetadata(
        forceRefresh: forceRefresh,
        loadGeneration: loadGeneration,
      ),
    );

    try {
      final messages = await ndk.nip17.loadConversation(
        peerPubKey: widget.peerPubKey,
        forceRefresh: forceRefresh,
      );
      if (!mounted || loadGeneration != _loadGeneration) return;
      setState(() {
        _messages = messages;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || loadGeneration != _loadGeneration) return;
      setState(() {
        _error = 'Conversation load failed: $e';
      });
    } finally {
      if (mounted && loadGeneration == _loadGeneration) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadPeerMetadata({
    required bool forceRefresh,
    required int loadGeneration,
  }) async {
    try {
      final metadata = await ndk.metadata.loadMetadata(
        widget.peerPubKey,
        forceRefresh: forceRefresh,
      );
      if (!mounted || loadGeneration != _loadGeneration) {
        return;
      }
      setState(() {
        _peerMetadata = metadata;
      });
    } catch (_) {
      // Ignore metadata failures; the conversation remains usable without it.
    }
  }

  @override
  Widget build(BuildContext context) {
    final myPubKey = ndk.accounts.getPublicKey();
    final title = _displayNameFor(widget.peerPubKey);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Refresh thread',
            onPressed: myPubKey == null || _loading
                ? null
                : () => _loadConversation(forceRefresh: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(context, myPubKey),
    );
  }

  Widget _buildBody(BuildContext context, String? myPubKey) {
    if (myPubKey == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Log in first to inspect this conversation.'),
        ),
      );
    }

    if (_loading && _messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(_error!),
          ),
        Expanded(
          child: _messages.isEmpty
              ? const Center(
                  child: Text('No conversation loaded yet.'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return Align(
                      alignment: message.isOutgoing
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Card(
                          color: message.isOutgoing
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: IntrinsicWidth(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(message.content),
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      _formatMessageTime(message.createdAt),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant
                                                .withValues(alpha: 0.65),
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        _buildComposer(context, myPubKey),
      ],
    );
  }

  Widget _buildComposer(BuildContext context, String? myPubKey) {
    final canSend = myPubKey != null && !_sending;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: myPubKey != null && !_sending,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendInlineMessage(),
              decoration: InputDecoration(
                hintText:
                    myPubKey == null ? 'Log in to send a message' : 'Message',
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Send',
            onPressed: canSend ? _sendInlineMessage : null,
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  String _displayNameFor(String peerPubKey) {
    final displayName = _peerMetadata?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    final name = _peerMetadata?.name?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return _shorten(peerPubKey);
  }

  String _formatMessageTime(int createdAt) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(
      createdAt * 1000,
      isUtc: true,
    ).toLocal();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class DmComposePage extends StatefulWidget {
  final String? initialRecipientPubKey;

  const DmComposePage({
    super.key,
    this.initialRecipientPubKey,
  });

  @override
  State<DmComposePage> createState() => _DmComposePageState();
}

class _DmComposePageState extends State<DmComposePage> {
  late final TextEditingController _recipientController;
  final _messageController = TextEditingController();
  bool _sending = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _recipientController = TextEditingController(
      text: widget.initialRecipientPubKey?.trim() ?? '',
    );
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final recipient = _recipientController.text.trim();
    final content = _messageController.text.trim();
    if (recipient.isEmpty || content.isEmpty) {
      setState(() {
        _status = 'Enter both recipient pubkey and message.';
      });
      return;
    }

    setState(() {
      _sending = true;
      _status = 'Sending direct message...';
    });

    try {
      await ndk.nip17.sendMessage(
        recipientPubKey: recipient,
        content: content,
      );
      if (!mounted) return;
      context.go('/dm/conversation/$recipient');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Send failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final myPubKey = ndk.accounts.getPublicKey();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compose DM'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              myPubKey == null
                  ? 'Log in first. This demo needs a signer and your own kind:10050 DM relay list.'
                  : 'Logged in as ${_shorten(myPubKey)}. Compose a NIP-17 direct message to a peer pubkey.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _recipientController,
              decoration: const InputDecoration(
                labelText: 'Recipient pubkey',
                border: OutlineInputBorder(),
              ),
              minLines: 1,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              minLines: 5,
              maxLines: 10,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: myPubKey == null || _sending ? null : _sendMessage,
                  icon: const Icon(Icons.send),
                  label: Text(_sending ? 'Sending...' : 'Send'),
                ),
                OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
            if (_status != null) ...[
              const SizedBox(height: 12),
              Text(_status!),
            ],
          ],
        ),
      ),
    );
  }
}

String _shorten(String value) {
  if (value.length <= 16) {
    return value;
  }
  return '${value.substring(0, 8)}...${value.substring(value.length - 8)}';
}

class _ConversationUnreadBadge extends StatelessWidget {
  final int count;

  const _ConversationUnreadBadge({
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
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
        ),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right),
      ],
    );
  }
}
