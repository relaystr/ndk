import 'package:flutter/material.dart';
import 'package:ndk_flutter/l10n/app_localizations.dart';

import 'n_app_update_controller.dart';
import 'n_app_update_widgets.dart';

/// Displays installed app version and marks an actionable update.
class NAppVersion extends StatefulWidget {
  final NAppUpdateController controller;
  final String? fallbackVersion;
  final TextStyle? style;
  final bool showPrefix;
  final bool watchReleases;

  const NAppVersion({
    super.key,
    required this.controller,
    this.fallbackVersion,
    this.style,
    this.showPrefix = true,
    this.watchReleases = true,
  });

  @override
  State<NAppVersion> createState() => _NAppVersionState();
}

class _NAppVersionState extends State<NAppVersion> {
  String? _scheduledReleaseId;

  @override
  void initState() {
    super.initState();
    if (widget.watchReleases) {
      widget.controller.acquireReleaseWatch();
    } else {
      widget.controller.start();
    }
  }

  @override
  void didUpdateWidget(covariant NAppVersion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller &&
        oldWidget.watchReleases == widget.watchReleases) {
      return;
    }
    if (oldWidget.watchReleases) {
      oldWidget.controller.releaseReleaseWatch();
    }
    if (widget.watchReleases) {
      widget.controller.acquireReleaseWatch();
    } else {
      widget.controller.start();
    }
  }

  void _scheduleReleaseDetails(NAppUpdateState state) {
    final release = state.justUpdatedRelease;
    if (release == null || _scheduledReleaseId == release.event.id) return;
    _scheduledReleaseId = release.event.id;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await NReleaseDetailsSheet.show(context, widget.controller, release);
      if (!mounted) return;
      await widget.controller.acknowledgeInstalledRelease();
    });
  }

  @override
  void dispose() {
    if (widget.watchReleases) {
      widget.controller.releaseReleaseWatch();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final l10n = AppLocalizations.of(context)!;
      final state = widget.controller.state;
      _scheduleReleaseDetails(state);
      final version =
          state.installed?.version ??
          widget.controller.currentVersion ??
          widget.fallbackVersion ??
          '—';
      final installUpdateAvailable =
          state.update != null &&
          (state.status == NAppUpdateStatus.available ||
              state.status == NAppUpdateStatus.cancelled);
      final externalUpdateAvailable = widget.controller.hasExternalUpdate;
      final updateAvailable = installUpdateAvailable || externalUpdateAvailable;
      final availableVersion =
          state.update?.release.version ?? state.latestRelease?.version ?? '—';
      final label = '${widget.showPrefix ? 'v' : ''}$version';
      final versionRow = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            style: (widget.style ?? Theme.of(context).textTheme.bodyMedium)
                ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          if (updateAvailable) ...[
            const SizedBox(width: 4),
            Icon(
              externalUpdateAvailable
                  ? Icons.open_in_new
                  : Icons.system_update_alt_rounded,
              size: 14,
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ],
        ],
      );

      return Semantics(
        label: updateAvailable
            ? l10n.appUpdateInstalledAndAvailable(version, availableVersion)
            : l10n.appUpdateInstalledVersion(version),
        button: true,
        child: Tooltip(
          message: updateAvailable
              ? l10n.appUpdateVersionAvailable(availableVersion)
              : l10n.appUpdateViewStatus,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => NAppUpdateDialog.show(context, widget.controller),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                child: versionRow,
              ),
            ),
          ),
        ),
      );
    },
  );
}
