import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ja'),
    Locale('ru'),
    Locale('zh')
  ];

  /// Button text for creating a new account
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createAccount;

  /// Question asking if the user is new to the platform
  ///
  /// In en, this message translates to:
  /// **'Are you new here?'**
  String get newHere;

  /// Label for nostr address input field
  ///
  /// In en, this message translates to:
  /// **'Nostr Address'**
  String get nostrAddress;

  /// Label for public key input field
  ///
  /// In en, this message translates to:
  /// **'Public Key'**
  String get publicKey;

  /// Label for private key input field
  ///
  /// In en, this message translates to:
  /// **'Private Key (insecure)'**
  String get privateKey;

  /// Label for browser extension login section
  ///
  /// In en, this message translates to:
  /// **'Browser extension'**
  String get browserExtension;

  /// Button text to connect with browser extension
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// Button text to install browser extension
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get install;

  /// Button text to logout from the application
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Placeholder text for nostr address input field
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get nostrAddressHint;

  /// Error message for invalid nostr address
  ///
  /// In en, this message translates to:
  /// **'Invalid Address'**
  String get invalidAddress;

  /// Error message when unable to connect to nostr address
  ///
  /// In en, this message translates to:
  /// **'Unable to connect'**
  String get unableToConnect;

  /// Placeholder text for public key input field
  ///
  /// In en, this message translates to:
  /// **'npub1...'**
  String get publicKeyHint;

  /// Placeholder text for private key input field
  ///
  /// In en, this message translates to:
  /// **'nsec1...'**
  String get privateKeyHint;

  /// Question asking if the user is new to Nostr
  ///
  /// In en, this message translates to:
  /// **'New to Nostr?'**
  String get newToNostr;

  /// Button text to get started with Nostr
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// Label for bunker login section
  ///
  /// In en, this message translates to:
  /// **'Bunker'**
  String get bunker;

  /// Title for bunker authentication toast
  ///
  /// In en, this message translates to:
  /// **'Bunker Authentication'**
  String get bunkerAuthentication;

  /// Description for bunker authentication toast
  ///
  /// In en, this message translates to:
  /// **'Tap to open: {url}'**
  String tapToOpen(String url);

  /// Button text to show nostr connect QR code
  ///
  /// In en, this message translates to:
  /// **'Show nostr connect qrcode'**
  String get showNostrConnectQrcode;

  /// Button text to login with Amber
  ///
  /// In en, this message translates to:
  /// **'Login with amber'**
  String get loginWithAmber;

  /// Title for nostr connect URL dialog
  ///
  /// In en, this message translates to:
  /// **'Nostr connect URL'**
  String get nostrConnectUrl;

  /// Button text to copy to clipboard
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// Button text to add a new account
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get addAccount;

  /// Label for read-only account type
  ///
  /// In en, this message translates to:
  /// **'Read-only'**
  String get readOnly;

  /// Label for nsec (private key) account type
  ///
  /// In en, this message translates to:
  /// **'Nsec'**
  String get nsec;

  /// Label for browser extension account type
  ///
  /// In en, this message translates to:
  /// **'Extension'**
  String get extension;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es', 'fr', 'ja', 'ru', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'fr': return AppLocalizationsFr();
    case 'ja': return AppLocalizationsJa();
    case 'ru': return AppLocalizationsRu();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
