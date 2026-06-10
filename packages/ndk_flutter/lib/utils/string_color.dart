import 'package:flutter/material.dart';

/// Deterministic, UI-optimized color derivation from any string.
///
/// Implements the "String Color" specification: a visually consistent color is
/// derived from a string, mapped to a hue and rendered through HSV with
/// perceptually balanced value (brightness) parameters. Designed to read well
/// as text, backgrounds, borders, and indicator dots across dark, light,
/// sepia, ivory, and grey themes.
///
/// Two derivation paths are supported and selected automatically:
/// - **Hexadecimal** input (e.g. a Nostr pubkey) is parsed directly as a
///   BigInt.
/// - Any other string is hashed via a polynomial of its character codes.
///
/// See the spec (NIP-54 wiki article "String Color",
/// kind 30818 / d-tag `string-color`).
class StringColor {
  StringColor._();

  /// Neutral fallback for empty or invalid inputs (`rgb(128, 128, 128)`).
  static const Color neutralGrey = Color(0xFF808080);

  /// Derives a color from an arbitrary [input] string.
  ///
  /// When [input] is a hexadecimal string (e.g. a Nostr pubkey) it is parsed
  /// directly as a BigInt; otherwise it is normalized (`trim()` +
  /// `toUpperCase()`) and hashed via a polynomial of its character codes
  /// (weighted by powers of 256). Empty input returns [neutralGrey].
  ///
  /// Pass [textBrightness] to apply the text-readability adjustment when
  /// rendering the color as text (author names, mentions, etc.). Leave it null
  /// for non-text uses such as backgrounds, borders, or avatars.
  static Color fromString(String input, {Brightness? textBrightness}) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return _adjust(neutralGrey, textBrightness);
    }

    // Hex strings (e.g. pubkeys) get a dedicated path: parse directly as a
    // BigInt and use a higher value for the warm band.
    if (_hexPattern.hasMatch(trimmed)) {
      final number = BigInt.parse(trimmed, radix: 16);
      final hue = number % _threeSixty;
      return _adjust(_hsvToColor(hue, warmValue: 0.75), textBrightness);
    }

    final normalized = trimmed.toUpperCase();
    var number = BigInt.zero;
    var weight = BigInt.one;
    for (final codeUnit in normalized.codeUnits) {
      number += BigInt.from(codeUnit) * weight;
      weight *= _base;
    }

    final hue = number % _threeSixty;
    return _adjust(_hsvToColor(hue, warmValue: 0.70), textBrightness);
  }

  static final RegExp _hexPattern = RegExp(r'^[0-9a-fA-F]+$');
  static final BigInt _base = BigInt.from(256);
  static final BigInt _threeSixty = BigInt.from(360);

  /// Converts a [hue] in [0, 360) to a [Color] using fixed saturation (0.70)
  /// and a hue-dependent value. [warmValue] is used for the warm
  /// yellow/green/cyan band (32-204); blues (216-273) get 0.96 and everything
  /// else 0.90.
  static Color _hsvToColor(BigInt hue, {required double warmValue}) {
    final h = hue.toDouble();

    const s = 0.70;
    final double v;
    if (h >= 32 && h <= 204) {
      v = warmValue;
    } else if (h >= 216 && h <= 273) {
      v = 0.96;
    } else {
      v = 0.90;
    }

    final hSector = h / 60.0;
    final c = v * s;
    final x = c * (1 - (hSector % 2 - 1).abs());
    final m = v - c;

    double r;
    double g;
    double b;
    if (hSector < 1) {
      r = c;
      g = x;
      b = 0;
    } else if (hSector < 2) {
      r = x;
      g = c;
      b = 0;
    } else if (hSector < 3) {
      r = 0;
      g = c;
      b = x;
    } else if (hSector < 4) {
      r = 0;
      g = x;
      b = c;
    } else if (hSector < 5) {
      r = x;
      g = 0;
      b = c;
    } else {
      r = c;
      g = 0;
      b = x;
    }

    return Color.fromARGB(
      255,
      ((r + m) * 255).round(),
      ((g + m) * 255).round(),
      ((b + m) * 255).round(),
    );
  }

  /// Applies the text-readability brightness correction:
  /// dark mode brightens by 8%, light mode darkens by 5%. Channels are clamped
  /// to [0, 255]. A null [brightness] returns the color unchanged.
  static Color _adjust(Color color, Brightness? brightness) {
    if (brightness == null) {
      return color;
    }

    final factor = brightness == Brightness.dark ? 1.08 : 0.95;
    int scale(int channel) => (channel * factor).round().clamp(0, 255);

    return Color.fromARGB(
      255,
      scale((color.r * 255).round()),
      scale((color.g * 255).round()),
      scale((color.b * 255).round()),
    );
  }
}
