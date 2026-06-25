import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ndk/entities.dart';
import 'package:ndk_flutter/widgets/widgets.dart';

import 'main.dart';

class FollowsPage extends StatefulWidget {
  const FollowsPage({super.key});

  @override
  State<FollowsPage> createState() => _FollowsPageState();
}

class _FollowsPageState extends State<FollowsPage> {
  final _searchController = TextEditingController();
  bool _loading = true;
  bool _metadataLoading = false;
  String? _error;
  List<_FollowProfile> _profiles = const [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadFollows();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadFollows({bool forceRefresh = false}) async {
    final myPubKey = ndk.accounts.getPublicKey();
    if (myPubKey == null) {
      setState(() {
        _loading = false;
        _metadataLoading = false;
        _error = 'Log in first to load your contact list.';
        _profiles = const [];
      });
      return;
    }

    setState(() {
      _loading = true;
      _metadataLoading = false;
      _error = null;
    });

    try {
      final contactList = await ndk.follows.getContactList(
        myPubKey,
        forceRefresh: forceRefresh,
      );
      final contacts =
          contactList?.contacts.toSet().toList() ?? const <String>[];

      if (contacts.isEmpty) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _metadataLoading = false;
          _profiles = const [];
        });
        return;
      }

      final profiles = contacts
          .map(
            (pubKey) => _FollowProfile(
              pubKey: pubKey,
              metadata: null,
            ),
          )
          .toList()
        ..sort((a, b) => a.sortKey.compareTo(b.sortKey));

      if (!mounted) return;
      setState(() {
        _loading = false;
        _metadataLoading = true;
        _profiles = profiles;
      });

      final metadatas = await ndk.metadata.loadMetadatas(
        contacts,
        null,
        onLoad: _applyLoadedMetadata,
      );
      for (final metadata in metadatas) {
        _applyLoadedMetadata(metadata);
      }

      if (!mounted) return;
      setState(() {
        _metadataLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _metadataLoading = false;
        _error = 'Failed to load follows: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final myPubKey = ndk.accounts.getPublicKey();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Follows'),
        actions: [
          if (_metadataLoading)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : () => _loadFollows(forceRefresh: true),
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
          child: Text('Log in first to inspect your follows and send DMs.'),
        ),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!),
        ),
      );
    }

    if (_profiles.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No follows found in your contact list.'),
        ),
      );
    }

    final filteredProfiles = _filteredProfiles;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search follows',
              hintText: 'Search by display name or name',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: _searchController.clear,
                      icon: const Icon(Icons.close),
                    ),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: filteredProfiles.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No follows match the current search.'),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredProfiles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final profile = filteredProfiles[index];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: SizedBox(
                          width: 48,
                          height: 48,
                          child: NPicture(
                            ndkFlutter: ndkFlutter,
                            metadata: profile.metadata,
                            pubkey: profile.metadata == null
                                ? profile.pubKey
                                : null,
                            circleAvatarRadius: 24,
                          ),
                        ),
                        title: Text(profile.primaryLabel),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (profile.secondaryLabel != null)
                              Text(profile.secondaryLabel!),
                            Text(
                              _shorten(profile.pubKey),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          tooltip: 'Send DM',
                          onPressed: () => context.push(
                            '/dm/conversation/${profile.pubKey}',
                          ),
                          icon: const Icon(Icons.forum_outlined),
                        ),
                        onTap: () => context.push(
                          '/profile',
                          extra: profile.pubKey,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  List<_FollowProfile> get _filteredProfiles {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _profiles;
    }
    return _profiles
        .where((profile) => profile.searchText.contains(query))
        .toList();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _applyLoadedMetadata(Metadata metadata) {
    if (!mounted) return;
    final index =
        _profiles.indexWhere((profile) => profile.pubKey == metadata.pubKey);
    if (index == -1) {
      return;
    }

    final current = _profiles[index];
    if (current.metadata?.updatedAt == metadata.updatedAt &&
        current.metadata?.displayName == metadata.displayName &&
        current.metadata?.name == metadata.name &&
        current.metadata?.picture == metadata.picture) {
      return;
    }

    final updatedProfiles = List<_FollowProfile>.from(_profiles);
    updatedProfiles[index] = current.copyWith(metadata: metadata);
    updatedProfiles.sort((a, b) => a.sortKey.compareTo(b.sortKey));

    setState(() {
      _profiles = updatedProfiles;
    });
  }

  String _shorten(String value) {
    if (value.length <= 16) {
      return value;
    }
    return '${value.substring(0, 8)}...${value.substring(value.length - 8)}';
  }
}

class _FollowProfile {
  final String pubKey;
  final Metadata? metadata;

  const _FollowProfile({
    required this.pubKey,
    required this.metadata,
  });

  _FollowProfile copyWith({
    Metadata? metadata,
  }) {
    return _FollowProfile(
      pubKey: pubKey,
      metadata: metadata ?? this.metadata,
    );
  }

  String get primaryLabel {
    final displayName = metadata?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final name = metadata?.name?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }

    return pubKey;
  }

  String? get secondaryLabel {
    final displayName = metadata?.displayName?.trim();
    final name = metadata?.name?.trim();

    if (displayName != null &&
        displayName.isNotEmpty &&
        name != null &&
        name.isNotEmpty &&
        displayName != name) {
      return name;
    }

    return null;
  }

  String get sortKey => primaryLabel.toLowerCase();

  String get searchText => [
        metadata?.displayName?.trim().toLowerCase(),
        metadata?.name?.trim().toLowerCase(),
        pubKey.toLowerCase(),
      ].whereType<String>().where((value) => value.isNotEmpty).join(' ');
}
