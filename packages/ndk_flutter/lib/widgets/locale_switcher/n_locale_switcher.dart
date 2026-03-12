import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Widget that allows switching between available locales.
///
/// Displays a dropdown or dialog to select from the supported locales
/// defined in [AppLocalizations.supportedLocales].
///
/// Example usage:
/// ```dart
/// NLocaleSwitcher(
///   currentLocale: Localizations.localeOf(context),
///   onLocaleChanged: (locale) {
///     // Update app locale through your state management
///     setState(() => _currentLocale = locale);
///   },
/// )
/// ```
class NLocaleSwitcher extends StatelessWidget {
  /// The currently selected locale
  final Locale currentLocale;

  /// Callback when user selects a different locale
  final ValueChanged<Locale> onLocaleChanged;

  /// Optional icon to display (defaults to language icon)
  final IconData? icon;

  /// Optional tooltip text
  final String? tooltip;

  /// Whether to show the locale name alongside the flag/code
  final bool showLocaleName;

  /// Optional custom mapping of locale codes to display names
  /// If not provided, defaults to locale.languageCode.toUpperCase()
  final Map<String, String>? localeDisplayNames;

  const NLocaleSwitcher({
    super.key,
    required this.currentLocale,
    required this.onLocaleChanged,
    this.icon,
    this.tooltip,
    this.showLocaleName = true,
    this.localeDisplayNames,
  });

  /// Returns a map of locale codes to their display names
  Map<String, String> get _defaultDisplayNames => {
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'ja': '日本語',
    'pl': 'Polski',
    'ru': 'Русский',
    'zh': '中文',
  };

  Map<String, String> get _displayNames =>
      localeDisplayNames ?? _defaultDisplayNames;

  /// Returns flag emoji for the locale
  String _getFlagEmoji(String languageCode) {
    switch (languageCode) {
      case 'en':
        return '🇬🇧';
      case 'es':
        return '🇪🇸';
      case 'fr':
        return '🇫🇷';
      case 'it':
        return 'it';
      case 'ja':
        return '🇯🇵';
      case 'pl':
        return'🇵🇱';
      case 'ru':
        return '🇷🇺';
      case 'zh':
        return '🇨🇳';
      default:
        return '🌐';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Add left padding in debug mode to avoid the debug ribbon
    final double leftPadding = kDebugMode ? 48.0 : 0.0;

    return Padding(
      padding: EdgeInsets.only(left: leftPadding),
      child: IconButton(
        icon: Icon(icon ?? Icons.language),
        tooltip: tooltip ?? 'Change Language',
        onPressed: () => _showLocaleDialog(context),
      ),
    );
  }

  void _showLocaleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: AppLocalizations.supportedLocales.length,
              itemBuilder: (context, index) {
                final locale = AppLocalizations.supportedLocales[index];
                final isSelected =
                    locale.languageCode == currentLocale.languageCode;
                final displayName =
                    _displayNames[locale.languageCode] ??
                    locale.languageCode.toUpperCase();
                final flag = _getFlagEmoji(locale.languageCode);

                return ListTile(
                  leading: Text(flag, style: const TextStyle(fontSize: 24)),
                  title: Text(displayName),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  selected: isSelected,
                  onTap: () {
                    Navigator.of(context).pop();
                    if (!isSelected) {
                      onLocaleChanged(locale);
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

/// Alternative dropdown version of the locale switcher
class NLocaleSwitcherDropdown extends StatelessWidget {
  /// The currently selected locale
  final Locale currentLocale;

  /// Callback when user selects a different locale
  final ValueChanged<Locale> onLocaleChanged;

  /// Optional hint text for the dropdown
  final String? hint;

  /// Optional custom mapping of locale codes to display names
  final Map<String, String>? localeDisplayNames;

  const NLocaleSwitcherDropdown({
    super.key,
    required this.currentLocale,
    required this.onLocaleChanged,
    this.hint,
    this.localeDisplayNames,
  });

  /// Returns a map of locale codes to their display names
  Map<String, String> get _defaultDisplayNames => {
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'ja': '日本語',
    'ru': 'Русский',
    'zh': '中文',
  };

  Map<String, String> get _displayNames =>
      localeDisplayNames ?? _defaultDisplayNames;

  /// Returns flag emoji for the locale
  String _getFlagEmoji(String languageCode) {
    switch (languageCode) {
      case 'en':
        return '🇬🇧';
      case 'es':
        return '🇪🇸';
      case 'fr':
        return '🇫🇷';
      case 'ja':
        return '🇯🇵';
      case 'ru':
        return '🇷🇺';
      case 'zh':
        return '🇨🇳';
      default:
        return '🌐';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<Locale>(
      value: currentLocale,
      hint: hint != null ? Text(hint!) : null,
      isExpanded: true,
      underline: const SizedBox(),
      icon: const Icon(Icons.arrow_drop_down),
      items: AppLocalizations.supportedLocales.map((Locale locale) {
        final displayName =
            _displayNames[locale.languageCode] ??
            locale.languageCode.toUpperCase();
        final flag = _getFlagEmoji(locale.languageCode);

        return DropdownMenuItem<Locale>(
          value: locale,
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(displayName),
            ],
          ),
        );
      }).toList(),
      onChanged: (Locale? locale) {
        if (locale != null) {
          onLocaleChanged(locale);
        }
      },
    );
  }
}
