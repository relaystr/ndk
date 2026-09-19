import 'package:flutter/material.dart';

/// Visual configuration for the Message of the Day popup.
///
/// Every property is optional; null values fall back to the current Theme or
/// built-in defaults, so an app developer can tune as little or as much as
/// they like.
class NMotdConfig {
  /// Dialog title. Falls back to "Message of the day".
  final String? title;

  /// Style for the dialog title.
  final TextStyle? titleStyle;

  /// Style for the message body.
  final TextStyle? messageStyle;

  /// Alignment of the message body.
  final TextAlign? messageAlign;

  /// Dialog background color.
  final Color? backgroundColor;

  /// Dialog shape (e.g. RoundedRectangleBorder).
  final ShapeBorder? shape;

  /// Padding inside the dialog.
  final EdgeInsetsGeometry? contentPadding;

  /// Maximum width of the dialog.
  final double? maxWidth;

  /// Maximum height of the dialog.
  final double? maxHeight;

  /// Whether tapping outside the dialog closes it.
  final bool barrierDismissible;

  /// Text of the close button. Falls back to localized "Close".
  final String? closeButtonText;

  /// Style of the close button label.
  final TextStyle? closeButtonStyle;

  /// Color of the close button.
  final Color? closeButtonColor;

  /// Text of the link button (shown when the event carries a `url` tag).
  /// Falls back to localized "Learn more".
  final String? linkButtonText;

  /// Style of the link button label.
  final TextStyle? linkButtonStyle;

  /// Color of the link button.
  final Color? linkButtonColor;

  const NMotdConfig({
    this.title,
    this.titleStyle,
    this.messageStyle,
    this.messageAlign,
    this.backgroundColor,
    this.shape,
    this.contentPadding,
    this.maxWidth,
    this.maxHeight,
    this.barrierDismissible = false,
    this.closeButtonText,
    this.closeButtonStyle,
    this.closeButtonColor,
    this.linkButtonText,
    this.linkButtonStyle,
    this.linkButtonColor,
  });
}