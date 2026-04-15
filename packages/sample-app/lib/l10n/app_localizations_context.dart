import 'package:flutter/widgets.dart';
import 'package:ndk_demo/l10n/generated/sample_app_localizations.dart';

extension SampleAppLocalizationsContext on BuildContext {
  SampleAppLocalizations get l10n => SampleAppLocalizations.of(this)!;
}
