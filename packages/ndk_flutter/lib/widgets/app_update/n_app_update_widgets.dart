import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/l10n/app_localizations.dart';

import '../picture/n_picture.dart';
import 'n_app_update_controller.dart';
import 'n_release_engagement.dart';

class NAppUpdateBuilder extends StatelessWidget {
  final NAppUpdateController controller;
  final Widget Function(BuildContext, NAppUpdateState) builder;

  const NAppUpdateBuilder({
    super.key,
    required this.controller,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => builder(context, controller.state),
  );
}

class NAppUpdateBanner extends StatelessWidget {
  final NAppUpdateController controller;

  const NAppUpdateBanner({super.key, required this.controller});

  @override
  Widget build(BuildContext context) => NAppUpdateBuilder(
    controller: controller,
    builder: (context, state) {
      final l10n = AppLocalizations.of(context)!;
      final externalUpdate = controller.hasExternalUpdate;
      final availableVersion =
          state.update?.release.version ?? state.latestRelease?.version;
      if ((state.status != NAppUpdateStatus.available ||
              state.update == null) &&
          !externalUpdate) {
        return const SizedBox.shrink();
      }
      return MaterialBanner(
        content: Text(l10n.appUpdateVersionAvailable(availableVersion ?? '—')),
        leading: Icon(externalUpdate ? Icons.open_in_new : Icons.system_update),
        actions: [
          FilledButton(
            onPressed: externalUpdate
                ? controller.openExternalUpdate
                : () => NAppUpdateSheet.show(context, controller),
            child: Text(
              externalUpdate ? l10n.appUpdateDownload : l10n.appUpdateView,
            ),
          ),
        ],
      );
    },
  );
}

class NAppUpdateTile extends StatelessWidget {
  final NAppUpdateController controller;

  const NAppUpdateTile({super.key, required this.controller});

  @override
  Widget build(BuildContext context) => NAppUpdateBuilder(
    controller: controller,
    builder: (context, state) {
      final l10n = AppLocalizations.of(context)!;
      final update = state.update;
      final externalUpdate = controller.hasExternalUpdate;
      final subtitle = switch (state.status) {
        NAppUpdateStatus.checking => l10n.appUpdateChecking,
        NAppUpdateStatus.available => l10n.appUpdateVersionAvailable(
          update!.release.version,
        ),
        NAppUpdateStatus.failed => state.error ?? l10n.appUpdateCheckFailed,
        _ when externalUpdate => l10n.appUpdateVersionAvailable(
          state.latestRelease?.version ?? '—',
        ),
        _ when !controller.installationEnabled =>
          state.latestRelease == null
              ? l10n.appUpdateNoReleases
              : l10n.appUpdateReleaseVersion(state.latestRelease!.version),
        _ => l10n.appUpdateInstalled(state.installed?.version ?? '—'),
      };
      return ListTile(
        leading: const Icon(Icons.system_update),
        title: Text(l10n.appUpdatesTitle),
        subtitle: Text(subtitle),
        trailing: state.status == NAppUpdateStatus.checking
            ? const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.chevron_right),
        onTap: !controller.installationEnabled
            ? () => NAppUpdateDialog.show(context, controller)
            : update == null
            ? controller.checkNow
            : () => NAppUpdateSheet.show(context, controller),
      );
    },
  );
}

class NAppUpdateSheet extends StatelessWidget {
  final NAppUpdateController controller;

  const NAppUpdateSheet({super.key, required this.controller});

  static Future<void> show(
    BuildContext context,
    NAppUpdateController controller,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => NAppUpdateSheet(controller: controller),
  );

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: NAppUpdateBuilder(
        controller: controller,
        builder: (context, state) {
          final l10n = AppLocalizations.of(context)!;
          final update = state.update;
          if (update == null) return Text(l10n.appUpdateNone);
          final busy =
              state.status == NAppUpdateStatus.downloading ||
              state.status == NAppUpdateStatus.verifying;
          final installPending =
              state.status == NAppUpdateStatus.awaitingUserAction ||
              state.status == NAppUpdateStatus.installing;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.appUpdateTitle(
                          state.installed?.version ?? '—',
                          update.release.version,
                        ),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      if (update.release.releaseNotes.isNotEmpty)
                        Text(update.release.releaseNotes),
                      if (update.asset.size != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          l10n.appUpdateSizeMb(
                            (update.asset.size! / 1048576).toStringAsFixed(1),
                          ),
                        ),
                      ],
                      if (busy) ...[
                        const SizedBox(height: 16),
                        LinearProgressIndicator(value: state.progress),
                      ],
                      if (state.status ==
                          NAppUpdateStatus.permissionRequired) ...[
                        const SizedBox(height: 12),
                        Text(l10n.appUpdateAllowInstalls),
                      ],
                      if (installPending) ...[
                        const SizedBox(height: 12),
                        Text(l10n.appUpdateCompleteInstallation),
                      ],
                      if (state.status == NAppUpdateStatus.failed) ...[
                        const SizedBox(height: 12),
                        Text(state.error ?? l10n.appUpdateFailed),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: busy
                        ? controller.cancelDownload
                        : controller.dismiss,
                    child: Text(
                      busy ? l10n.appUpdateCancel : l10n.appUpdateLater,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: busy || installPending
                        ? null
                        : controller.downloadAndInstall,
                    child: Text(l10n.appUpdateAction),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    ),
  );
}

class NAppUpdateDialog extends StatefulWidget {
  final NAppUpdateController controller;

  const NAppUpdateDialog({super.key, required this.controller});

  static Future<void> show(
    BuildContext context,
    NAppUpdateController controller,
  ) => showDialog<void>(
    context: context,
    builder: (_) => NAppUpdateDialog(controller: controller),
  );

  @override
  State<NAppUpdateDialog> createState() => _NAppUpdateDialogState();
}

class _NAppUpdateDialogState extends State<NAppUpdateDialog> {
  bool _refreshing = true;

  NAppUpdateController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    if (!_refreshing && mounted) setState(() => _refreshing = true);
    await controller.checkNow();
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) => NAppUpdateBuilder(
    controller: controller,
    builder: (context, state) {
      final l10n = AppLocalizations.of(context)!;
      final update = state.update;
      final checking = _refreshing || state.status == NAppUpdateStatus.checking;
      if (checking) {
        return AlertDialog(
          title: Text(l10n.appUpdateChecking),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.appUpdateChecking),
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
          ),
          actions: [
            if (state.releases.isNotEmpty)
              TextButton.icon(
                onPressed: () =>
                    NReleaseHistoryScreen.show(context, controller),
                icon: const Icon(Icons.history),
                label: Text(l10n.appUpdateChangelog),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.appUpdateClose),
            ),
          ],
        );
      }
      if (update == null) {
        final failed = state.status == NAppUpdateStatus.failed;
        final externalUpdate = !failed && controller.hasExternalUpdate;
        final aheadOfPublished =
            state.status == NAppUpdateStatus.aheadOfPublished;
        final release =
            (externalUpdate ? state.latestRelease : state.currentRelease) ??
            state.latestRelease ??
            state.releases.firstOrNull;
        return AlertDialog(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  failed
                      ? l10n.appUpdateCheckFailed
                      : externalUpdate
                      ? l10n.appUpdateTitle(
                          controller.currentVersion ?? '—',
                          state.latestRelease?.version ?? '—',
                        )
                      : !controller.installationEnabled
                      ? l10n.appUpdateReleaseDetails
                      : aheadOfPublished
                      ? l10n.appUpdateAheadOfPublished
                      : l10n.appUpdateUpToDate,
                ),
              ),
              IconButton(
                onPressed: _refresh,
                tooltip: l10n.appUpdateCheckAgain,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                failed
                    ? state.error ?? l10n.appUpdateCheckFailedMessage
                    : externalUpdate
                    ? l10n.appUpdateVersionAvailable(
                        state.latestRelease?.version ?? '—',
                      )
                    : !controller.installationEnabled
                    ? release == null
                          ? l10n.appUpdateNoReleases
                          : l10n.appUpdateReleaseVersion(release.version)
                    : aheadOfPublished
                    ? l10n.appUpdateAheadOfPublishedMessage(
                        state.installed?.version ?? '—',
                        state.latestRelease?.version ?? '—',
                      )
                    : l10n.appUpdateLatest(state.installed?.version ?? '—'),
              ),
              if (release != null) ...[
                const SizedBox(height: 16),
                _ReleaseFacts(release: release, summary: true),
                const SizedBox(height: 12),
                _ReleaseSummaryActions(
                  controller: controller,
                  release: release,
                ),
              ],
            ],
          ),
          actions: [
            if (state.releases.isNotEmpty)
              TextButton.icon(
                onPressed: () =>
                    NReleaseHistoryScreen.show(context, controller),
                icon: const Icon(Icons.history),
                label: Text(l10n.appUpdateChangelog),
              ),
            if (externalUpdate) ...[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.appUpdateClose),
              ),
              FilledButton.icon(
                onPressed: controller.openExternalUpdate,
                icon: const Icon(Icons.open_in_new),
                label: Text(l10n.appUpdateDownload),
              ),
            ] else
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.appUpdateClose),
              ),
          ],
        );
      }
      final busy =
          state.status == NAppUpdateStatus.downloading ||
          state.status == NAppUpdateStatus.verifying;
      final installPending =
          state.status == NAppUpdateStatus.awaitingUserAction ||
          state.status == NAppUpdateStatus.installing;
      return AlertDialog(
        title: Text(
          l10n.appUpdateTitle(
            state.installed?.version ?? '—',
            update.release.version,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReleaseFacts(
                release: update.release,
                asset: update.asset,
                summary: true,
              ),
              const SizedBox(height: 16),
              if (update.release.releaseNotes.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.appUpdateWhatsNew,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      update.release.releaseNotes,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              _ReleaseSummaryActions(
                controller: controller,
                release: update.release,
                asset: update.asset,
              ),
              if (busy) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(value: state.progress),
              ],
              if (state.status == NAppUpdateStatus.permissionRequired) ...[
                const SizedBox(height: 12),
                Text(l10n.appUpdateAllowInstalls),
              ],
              if (state.status == NAppUpdateStatus.awaitingUserAction) ...[
                const SizedBox(height: 12),
                Text(l10n.appUpdateCompleteInstallation),
              ],
              if (state.status == NAppUpdateStatus.failed) ...[
                const SizedBox(height: 12),
                Text(state.error ?? l10n.appUpdateFailed),
              ],
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => NReleaseHistoryScreen.show(context, controller),
            icon: const Icon(Icons.history),
            label: Text(l10n.appUpdateChangelog),
          ),
          TextButton(
            onPressed: busy
                ? controller.cancelDownload
                : () {
                    controller.dismiss();
                    Navigator.of(context).pop();
                  },
            child: Text(busy ? l10n.appUpdateCancel : l10n.appUpdateLater),
          ),
          FilledButton(
            onPressed: busy || installPending
                ? null
                : controller.downloadAndInstall,
            child: Text(l10n.appUpdateAction),
          ),
        ],
      );
    },
  );
}

/// Displays all discovered releases as a changelog.
class NReleaseHistoryScreen extends StatelessWidget {
  final NAppUpdateController controller;

  const NReleaseHistoryScreen({super.key, required this.controller});

  static Future<void> show(
    BuildContext context,
    NAppUpdateController controller,
  ) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => NReleaseHistoryScreen(controller: controller),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(AppLocalizations.of(context)!.appUpdateReleaseHistory),
      actions: [
        IconButton(
          onPressed: controller.checkNow,
          tooltip: AppLocalizations.of(context)!.appUpdateCheckAgain,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: NAppUpdateBuilder(
      controller: controller,
      builder: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        final releases = state.releases;
        if (state.status == NAppUpdateStatus.checking && releases.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (releases.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history_toggle_off,
                    size: 40,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.status == NAppUpdateStatus.failed
                        ? state.error ?? l10n.appUpdateCheckFailedMessage
                        : l10n.appUpdateNoReleases,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: controller.checkNow,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.appUpdateCheckAgain),
                  ),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.checkNow,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: releases.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final release = releases[index];
              final isInstalled =
                  release.version ==
                  (state.installed?.version ?? controller.currentVersion);
              final isUpdate =
                  release.event.id == state.update?.release.event.id;
              final isLatest = index == 0;
              final asset = isUpdate ? state.update?.asset : null;
              final published = MaterialLocalizations.of(context)
                  .formatMediumDate(
                    DateTime.fromMillisecondsSinceEpoch(
                      release.event.createdAt * 1000,
                    ),
                  );
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                title: Text(
                  release.version,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isInstalled || isUpdate || isLatest) ...[
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (isInstalled)
                              _ReleaseBadge(
                                label: l10n.appUpdateInstalledBadge,
                              ),
                            if (!isInstalled && isUpdate)
                              _ReleaseBadge(
                                label: l10n.appUpdateAvailableBadge,
                                emphasized: true,
                              ),
                            if (!isInstalled && !isUpdate && isLatest)
                              _ReleaseBadge(label: l10n.appUpdateLatestBadge),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                      Text(l10n.appUpdatePublishedOn(published)),
                      if (release.releaseNotes.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(release.releaseNotes),
                      ],
                    ],
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => NReleaseDetailsSheet.show(
                  context,
                  controller,
                  release,
                  asset: asset,
                ),
              );
            },
          ),
        );
      },
    ),
  );
}

class _ReleaseBadge extends StatelessWidget {
  final String label;
  final bool emphasized;

  const _ReleaseBadge({required this.label, this.emphasized = false});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: emphasized
            ? colors.tertiaryContainer
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: emphasized
              ? colors.onTertiaryContainer
              : colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ReleaseFacts extends StatelessWidget {
  final SoftwareRelease release;
  final SoftwareAsset? asset;
  final bool summary;

  const _ReleaseFacts({
    required this.release,
    this.asset,
    this.summary = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final published = MaterialLocalizations.of(context).formatMediumDate(
      DateTime.fromMillisecondsSinceEpoch(release.event.createdAt * 1000),
    );
    final metadata = <String>[
      l10n.appUpdatePublishedOn(published),
      if (!summary) l10n.appUpdateChannel(release.channel),
    ];
    final facts = <String>[
      if (!summary && (asset?.platforms.isNotEmpty ?? false))
        l10n.appUpdateArchitecture(asset!.platforms.join(', ')),
      if (!summary && asset?.size != null)
        l10n.appUpdateSizeMb((asset!.size! / 1048576).toStringAsFixed(1)),
      if (!summary && asset?.versionCode != null)
        l10n.appUpdateVersionCode(asset!.versionCode!),
    ];
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: metadata
              .map(
                (fact) => Text(
                  fact,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
              .toList(growable: false),
        ),
        if (facts.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: facts
                .map(
                  (fact) => Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(fact),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}

class _ReleaseSummaryActions extends StatefulWidget {
  final NAppUpdateController controller;
  final SoftwareRelease release;
  final SoftwareAsset? asset;

  const _ReleaseSummaryActions({
    required this.controller,
    required this.release,
    this.asset,
  });

  @override
  State<_ReleaseSummaryActions> createState() => _ReleaseSummaryActionsState();
}

class _ReleaseSummaryActionsState extends State<_ReleaseSummaryActions> {
  late NReleaseEngagementController engagement;
  NReleaseEngagementController? detailsEngagement;
  bool detailsOpen = false;

  @override
  void initState() {
    super.initState();
    _createEngagement();
  }

  void _createEngagement() {
    engagement = NReleaseEngagementController(
      ndk: widget.controller.ndkFlutter.ndk,
      release: widget.release,
      relays: widget.controller.relays,
      zapTargetApp: widget.controller.zapTargetApp,
      queryTimeout: widget.controller.engagementQueryTimeout,
      metadataTimeout: widget.controller.engagementMetadataTimeout,
    );
    unawaited(engagement.load());
  }

  @override
  void didUpdateWidget(covariant _ReleaseSummaryActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.release.event.id == widget.release.event.id) return;
    if (!identical(engagement, detailsEngagement)) engagement.dispose();
    _createEngagement();
  }

  @override
  void dispose() {
    if (!identical(engagement, detailsEngagement)) engagement.dispose();
    super.dispose();
  }

  Future<void> _showDetails() async {
    if (detailsOpen) return;
    detailsOpen = true;
    final openedEngagement = engagement;
    detailsEngagement = openedEngagement;
    try {
      await NReleaseDetailsSheet.show(
        context,
        widget.controller,
        widget.release,
        asset: widget.asset,
        engagement: openedEngagement,
      );
    } finally {
      detailsOpen = false;
      detailsEngagement = null;
      if (!mounted || !identical(openedEngagement, engagement)) {
        openedEngagement.dispose();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: engagement,
      builder: (context, _) {
        final social = engagement.state;
        final awaitingResults = social.loading && !social.hasLoaded;
        final zapCount = awaitingResults ? '—' : '${social.zapCount}';
        final commentCount = awaitingResults
            ? '—'
            : '${social.comments.length}';
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Tooltip(
                message: l10n.appUpdateZapSummary(
                  social.zapCount,
                  social.zapAmountSats,
                ),
                child: ActionChip(
                  avatar: const Icon(Icons.bolt, size: 18),
                  label: Text(zapCount),
                  onPressed: _showDetails,
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: l10n.appUpdateCommentCount(social.comments.length),
                child: ActionChip(
                  avatar: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: Text(commentCount),
                  onPressed: _showDetails,
                ),
              ),
              const SizedBox(width: 8),
              ActionChip(
                avatar: const Icon(Icons.article_outlined, size: 18),
                label: Text(l10n.appUpdateReleaseDetails),
                onPressed: _showDetails,
              ),
            ],
          ),
        );
      },
    );
  }
}

class NReleaseDetailsSheet extends StatefulWidget {
  final NAppUpdateController controller;
  final SoftwareRelease release;
  final SoftwareAsset? asset;
  final NReleaseEngagementController? engagement;

  const NReleaseDetailsSheet({
    super.key,
    required this.controller,
    required this.release,
    this.asset,
    this.engagement,
  });

  static Future<void> show(
    BuildContext context,
    NAppUpdateController controller,
    SoftwareRelease release, {
    SoftwareAsset? asset,
    NReleaseEngagementController? engagement,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => NReleaseDetailsSheet(
      controller: controller,
      release: release,
      asset: asset,
      engagement: engagement,
    ),
  );

  @override
  State<NReleaseDetailsSheet> createState() => _NReleaseDetailsSheetState();
}

class _NReleaseDetailsSheetState extends State<NReleaseDetailsSheet> {
  late final NReleaseEngagementController engagement;
  late final Listenable detailsListenable;
  late final bool ownsEngagement;
  late SoftwareRelease selectedRelease;
  final commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedRelease = widget.release;
    ownsEngagement = widget.engagement == null;
    engagement =
        widget.engagement ??
        NReleaseEngagementController(
          ndk: widget.controller.ndkFlutter.ndk,
          release: widget.release,
          relays: widget.controller.relays,
          zapTargetApp: widget.controller.zapTargetApp,
          queryTimeout: widget.controller.engagementQueryTimeout,
          metadataTimeout: widget.controller.engagementMetadataTimeout,
        );
    detailsListenable = Listenable.merge([widget.controller, engagement]);
    if (ownsEngagement) unawaited(engagement.load());
  }

  @override
  void dispose() {
    if (ownsEngagement) engagement.dispose();
    commentController.dispose();
    super.dispose();
  }

  List<SoftwareRelease> get _releaseChoices {
    final byId = {
      for (final release in widget.controller.state.releases)
        release.event.id: release,
      widget.release.event.id: widget.release,
    };
    return byId.values.toList(growable: false)
      ..sort((a, b) => b.event.createdAt.compareTo(a.event.createdAt));
  }

  SoftwareAsset? get _selectedAsset {
    final update = widget.controller.state.update;
    if (update?.release.event.id == selectedRelease.event.id) {
      return update!.asset;
    }
    if (widget.release.event.id == selectedRelease.event.id &&
        widget.asset != null) {
      return widget.asset;
    }
    return widget.controller.assetForRelease(selectedRelease);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.9,
          child: ListenableBuilder(
            listenable: detailsListenable,
            builder: (context, _) {
              final social = engagement.state;
              final releases = _releaseChoices;
              final selectedIndex = releases.indexWhere(
                (release) => release.event.id == selectedRelease.event.id,
              );
              final installedVersion =
                  widget.controller.state.installed?.version ??
                  widget.controller.currentVersion;
              final asset = _selectedAsset;
              final publisher = social.publisher;
              final publisherName =
                  publisher?.displayName ??
                  publisher?.name ??
                  widget.controller.ndkFlutter.formatNpub(
                    selectedRelease.event.pubKey,
                  );
              return ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                children: [
                  DefaultTabController(
                    key: ValueKey(
                      releases.map((release) => release.event.id).join(':'),
                    ),
                    length: releases.length,
                    initialIndex: selectedIndex < 0 ? 0 : selectedIndex,
                    child: TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      onTap: (index) {
                        setState(() => selectedRelease = releases[index]);
                      },
                      tabs: [
                        for (final release in releases)
                          Tooltip(
                            message: release.version == installedVersion
                                ? l10n.appUpdateInstalledBadge
                                : release.event.id ==
                                      widget
                                          .controller
                                          .state
                                          .update
                                          ?.release
                                          .event
                                          .id
                                ? l10n.appUpdateAvailableBadge
                                : release.event.id == releases.first.event.id
                                ? l10n.appUpdateLatestBadge
                                : l10n.appUpdateReleaseVersion(release.version),
                            child: Tab(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(release.version),
                                  if (release.version == installedVersion ||
                                      release.event.id ==
                                          widget
                                              .controller
                                              .state
                                              .update
                                              ?.release
                                              .event
                                              .id) ...[
                                    const SizedBox(width: 6),
                                    Icon(
                                      release.version == installedVersion
                                          ? Icons.phone_android
                                          : Icons.system_update_alt_rounded,
                                      size: 16,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOutCubic,
                    layoutBuilder: (currentChild, previousChildren) => Stack(
                      alignment: Alignment.centerLeft,
                      children: [...previousChildren, ?currentChild],
                    ),
                    child: _ReleaseSpecificDetails(
                      key: ValueKey(selectedRelease.event.id),
                      controller: widget.controller,
                      release: selectedRelease,
                      asset: asset,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _SectionDivider(label: l10n.appUpdateAcrossAllReleases),
                  const SizedBox(height: 24),
                  Text(
                    l10n.appUpdatePublisher,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: NPicture(
                      ndkFlutter: widget.controller.ndkFlutter,
                      pubkey: selectedRelease.event.pubKey,
                      metadata: publisher,
                      circleAvatarRadius: 20,
                    ),
                    title: Text(publisherName),
                    subtitle: Text(
                      publisher?.cleanNip05 ??
                          widget.controller.ndkFlutter.formatNpub(
                            selectedRelease.event.pubKey,
                          ),
                    ),
                  ),
                  _TrustLine(
                    icon: Icons.verified_user_outlined,
                    text: l10n.appUpdatePublisherSignatureVerified,
                  ),
                  const SizedBox(height: 28),
                  if (social.loading) const LinearProgressIndicator(),
                  if (social.loading && social.hasLoaded)
                    const SizedBox(height: 14),
                  if (social.hasLoaded) ...[
                    if (social.zapContributors.isNotEmpty) ...[
                      _ZapSummary(
                        controller: widget.controller,
                        totalSats: social.zapAmountSats,
                        contributors: social.zapContributors,
                      ),
                      const SizedBox(height: 14),
                    ] else
                      _SocialMetric(
                        icon: Icons.bolt,
                        label: l10n.appUpdateZapSummary(
                          social.zapCount,
                          social.zapAmountSats,
                        ),
                      ),
                    Wrap(
                      spacing: 16,
                      runSpacing: 10,
                      children: [
                        _SocialMetric(
                          icon: Icons.favorite_border,
                          label: l10n.appUpdateReactionCount(
                            social.reactionCount,
                          ),
                        ),
                        _SocialMetric(
                          icon: Icons.chat_bubble_outline,
                          label: l10n.appUpdateCommentCount(
                            social.comments.length,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (social.error != null) ...[
                    const SizedBox(height: 8),
                    if (!social.errorFromPosting)
                      Text(l10n.appUpdateSocialLoadFailed),
                    Text(
                      social.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    if (!social.errorFromPosting)
                      TextButton.icon(
                        onPressed: engagement.load,
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.appUpdateCheckAgain),
                      ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    l10n.appUpdateComments,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (social.hasLoaded && social.comments.isEmpty)
                    Text(l10n.appUpdateNoComments),
                  for (final comment in social.comments)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: NPicture(
                        ndkFlutter: widget.controller.ndkFlutter,
                        pubkey: comment.event.pubKey,
                        metadata: comment.author,
                        circleAvatarRadius: 20,
                      ),
                      title: Text(comment.authorName),
                      subtitle: Text(comment.content),
                      trailing: Text(
                        MaterialLocalizations.of(context).formatCompactDate(
                          DateTime.fromMillisecondsSinceEpoch(
                            comment.event.createdAt * 1000,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (engagement.canComment) ...[
                    TextField(
                      controller: commentController,
                      minLines: 2,
                      maxLines: 5,
                      maxLength: 500,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: l10n.appUpdateCommentHint,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: social.posting
                            ? null
                            : () async {
                                final posted = await engagement.postComment(
                                  commentController.text,
                                );
                                if (!mounted) return;
                                if (posted) commentController.clear();
                              },
                        icon: social.posting
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(l10n.appUpdatePostComment),
                      ),
                    ),
                  ] else
                    Text(l10n.appUpdateSignInToComment),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ReleaseSpecificDetails extends StatelessWidget {
  final NAppUpdateController controller;
  final SoftwareRelease release;
  final SoftwareAsset? asset;

  const _ReleaseSpecificDetails({
    super.key,
    required this.controller,
    required this.release,
    required this.asset,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sourceHost = Uri.tryParse(asset?.url ?? '')?.host;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.appUpdateWhatsNew,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          release.releaseNotes.isEmpty
              ? l10n.appUpdateNoReleaseNotes
              : release.releaseNotes,
        ),
        const SizedBox(height: 12),
        _ReleaseFacts(release: release, asset: asset),
        if (asset?.certificateHashes.isNotEmpty ?? false)
          _TrustLine(
            icon: Icons.fingerprint,
            text: l10n.appUpdateCertificateDeclared,
          ),
        if (sourceHost != null && sourceHost.isNotEmpty)
          _TrustLine(
            icon: Icons.cloud_download_outlined,
            text: l10n.appUpdateSource(sourceHost),
          ),
        if (asset != null) ...[
          const SizedBox(height: 16),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(l10n.appUpdateTechnicalDetails),
            children: [
              SelectableText('SHA-256: ${asset!.sha256}'),
              const SizedBox(height: 8),
              SelectableText('versionCode: ${asset!.versionCode ?? '—'}'),
            ],
          ),
        ],
      ],
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final String label;

  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      const Expanded(child: Divider()),
    ],
  );
}

class _TrustLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TrustLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class _SocialMetric extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SocialMetric({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [Icon(icon, size: 18), const SizedBox(width: 6), Text(label)],
  );
}

class _ZapSummary extends StatelessWidget {
  final NAppUpdateController controller;
  final int totalSats;
  final List<NReleaseZapContributor> contributors;

  const _ZapSummary({
    required this.controller,
    required this.totalSats,
    required this.contributors,
  });

  String _compact(BuildContext context, int value) => NumberFormat.compact(
    locale: Localizations.localeOf(context).toLanguageTag(),
  ).format(value);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Icon(
              Icons.bolt_rounded,
              size: 32,
              color: theme.colorScheme.tertiary,
            ),
            const SizedBox(width: 4),
            Text.rich(
              TextSpan(
                style: theme.textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: _compact(context, totalSats),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: ' ${l10n.appUpdateSatsBy}'),
                ],
              ),
            ),
            const SizedBox(width: 12),
            for (final (index, contributor) in contributors.indexed) ...[
              if (index > 0) const SizedBox(width: 14),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NPicture(
                    ndkFlutter: controller.ndkFlutter,
                    pubkey: contributor.pubkey,
                    metadata: contributor.metadata,
                    circleAvatarRadius: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _compact(context, contributor.amountSats),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
