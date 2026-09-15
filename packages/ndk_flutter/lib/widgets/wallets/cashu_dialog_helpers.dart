import 'package:flutter/material.dart';

/// Strips exception prefixes and noisy JSON bodies from error messages so they
/// read cleanly in the UI.
String cleanCashuErrorMessage(String raw) {
  var message = raw.trim();
  for (final prefix in const [
    'Exception: ',
    'StateError: ',
    'Bad state: ',
    'HttpException: ',
    'SocketException: ',
    'TimeoutException: ',
  ]) {
    if (message.startsWith(prefix)) {
      message = message.substring(prefix.length).trim();
      break;
    }
  }
  // mint API errors often embed a JSON body; prefer the `detail` field
  final detailMatch = RegExp(
    r'"detail"\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)"',
  ).firstMatch(message);
  if (detailMatch != null) return detailMatch.group(1)!;
  return message;
}

/// Red error card used by the cashu recovery/restore dialogs to surface a
/// failure with a prominent title and a cleaned message.
class CashuErrorPanel extends StatelessWidget {
  final String title;
  final String message;

  const CashuErrorPanel({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.red.shade900.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Single row of a progress timeline: leading icon (done / active / pending),
/// a title and an optional subtitle.
class CashuStageLine extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool done;
  final bool active;

  const CashuStageLine({
    super.key,
    required this.title,
    this.subtitle,
    this.done = false,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Widget leading;
    if (done) {
      leading = const Icon(Icons.check_circle, color: Colors.green, size: 20);
    } else if (active) {
      leading = const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else {
      leading = Icon(Icons.circle, size: 12, color: colorScheme.outlineVariant);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 20, child: Center(child: leading)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: done
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
