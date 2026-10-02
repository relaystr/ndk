import 'package:flutter/material.dart';
import 'package:ndk_flutter/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import 'motd_data.dart';
import 'n_motd_config.dart';
import 'n_motd_controller.dart';

/// Renders nothing by itself; it watches the given [NMotdController] and shows
/// the Message of the Day popup as soon as the controller reports a message
/// that should be displayed.
///
/// Place it anywhere in the widget tree (e.g. on the home screen). The app
/// developer supplies the current app version via [appVersion]; when both the
/// event `version` tag and [appVersion] are present, the popup is hidden only
/// when the app version is older than the event minimum version.
class NMotdPopup extends StatefulWidget {
  /// Controller holding the Message of the Day state.
  final NMotdController controller;

  /// Current app version, used to compare against the event `version` tag.
  final String? appVersion;

  /// Visual customization for the popup.
  final NMotdConfig config;

  const NMotdPopup({
    super.key,
    required this.controller,
    this.appVersion,
    this.config = const NMotdConfig(),
  });

  @override
  State<NMotdPopup> createState() => _NMotdPopupState();
}

class _NMotdPopupState extends State<NMotdPopup> {
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleChange);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  @override
  void didUpdateWidget(NMotdPopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleChange);
      widget.controller.addListener(_handleChange);
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() {
    if (!mounted) return;
    _maybeShow();
  }

  Future<void> _maybeShow() async {
    if (!mounted || _dialogOpen) return;
    if (!widget.controller.shouldShow(appVersion: widget.appVersion)) return;
    final motd = widget.controller.current;
    if (motd == null) return;

    _dialogOpen = true;
    final link = MotdData.resolveLinkUrl(
      motd.url,
      allowedSchemes: widget.config.allowedLinkSchemes,
    );
    await showDialog<void>(
      context: context,
      barrierDismissible: widget.config.barrierDismissible,
      builder: (dialogContext) => _NMotdDialog(
        motd: motd,
        link: link,
        config: widget.config,
        onClose: () => Navigator.of(dialogContext).pop(),
        onOpenLink: link == null ? null : () => _openLink(dialogContext, link),
      ),
    );
    // Mark as seen no matter how the popup was closed.
    await widget.controller.dismiss();
    _dialogOpen = false;
  }

  /// Launches the already-validated [link]; never throws out of the callback.
  Future<void> _openLink(BuildContext context, Uri link) async {
    var launched = false;
    try {
      launched = await launchUrl(link, mode: LaunchMode.externalApplication);
    } catch (_) {
      // No handler registered or platform failure: keep the popup open.
    }
    if (launched && context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _NMotdDialog extends StatelessWidget {
  final MotdData motd;

  /// Pre-validated link target; null means no link button is shown.
  final Uri? link;
  final NMotdConfig config;
  final VoidCallback onClose;
  final VoidCallback? onOpenLink;

  const _NMotdDialog({
    required this.motd,
    required this.link,
    required this.config,
    required this.onClose,
    required this.onOpenLink,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final config = this.config;

    Widget dialog = AlertDialog(
      backgroundColor: config.backgroundColor,
      shape: config.shape,
      contentPadding: config.contentPadding,
      title: _buildTitle(l10n, config, motd),
      content: SingleChildScrollView(
        child: Text(
          motd.message,
          style: config.messageStyle,
          textAlign: config.messageAlign,
        ),
      ),
      actions: [
        if (link != null && onOpenLink != null)
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: config.linkButtonColor,
            ),
            onPressed: onOpenLink,
            child: Text(
              config.linkButtonText ?? l10n?.motdOpenLinkButton ?? 'Learn more',
              style: config.linkButtonStyle,
            ),
          ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: config.closeButtonColor),
          onPressed: onClose,
          child: Text(
            config.closeButtonText ?? l10n?.close ?? 'Close',
            style: config.closeButtonStyle,
          ),
        ),
      ],
    );

    if (config.maxWidth != null || config.maxHeight != null) {
      dialog = ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: config.maxWidth ?? double.infinity,
          maxHeight: config.maxHeight ?? double.infinity,
        ),
        child: dialog,
      );
    }
    return dialog;
  }

  /// Resolves the popup title: an event-provided `title` tag wins, otherwise
  /// the widget-level [NMotdConfig.title] is used, falling back to the
  /// localized default "Message of the Day".
  Widget? _buildTitle(
    AppLocalizations? l10n,
    NMotdConfig config,
    MotdData motd,
  ) {
    final eventTitle = motd.title?.trim();
    final hasEventTitle = eventTitle != null && eventTitle.isNotEmpty;
    if (!hasEventTitle && config.title == null && l10n == null) return null;
    return Text(
      hasEventTitle ? eventTitle : (config.title ?? l10n!.motdTitle),
      style: config.titleStyle,
    );
  }
}
