import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_pl.dart';
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
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
    Locale('pl'),
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

  /// Nostr event kind 0
  ///
  /// In en, this message translates to:
  /// **'User Metadata'**
  String get userMetadata;

  /// Nostr event kind 1
  ///
  /// In en, this message translates to:
  /// **'Short Text Note'**
  String get shortTextNote;

  /// Nostr event kind 2
  ///
  /// In en, this message translates to:
  /// **'Recommend Relay'**
  String get recommendRelay;

  /// Nostr event kind 3
  ///
  /// In en, this message translates to:
  /// **'Follows'**
  String get follows;

  /// Nostr event kind 4
  ///
  /// In en, this message translates to:
  /// **'Encrypted Direct Messages'**
  String get encryptedDirectMessages;

  /// Nostr event kind 5
  ///
  /// In en, this message translates to:
  /// **'Event Deletion Request'**
  String get eventDeletionRequest;

  /// Nostr event kind 6
  ///
  /// In en, this message translates to:
  /// **'Repost'**
  String get repost;

  /// Nostr event kind 7
  ///
  /// In en, this message translates to:
  /// **'Reaction'**
  String get reaction;

  /// Nostr event kind 8
  ///
  /// In en, this message translates to:
  /// **'Badge Award'**
  String get badgeAward;

  /// Nostr event kind 9
  ///
  /// In en, this message translates to:
  /// **'Chat Message'**
  String get chatMessage;

  /// Nostr event kind 10
  ///
  /// In en, this message translates to:
  /// **'Group Chat Threaded Reply'**
  String get groupChatThreadedReply;

  /// Nostr event kind 11
  ///
  /// In en, this message translates to:
  /// **'Thread'**
  String get thread;

  /// Nostr event kind 12
  ///
  /// In en, this message translates to:
  /// **'Group Thread Reply'**
  String get groupThreadReply;

  /// Nostr event kind 13
  ///
  /// In en, this message translates to:
  /// **'Seal'**
  String get seal;

  /// Nostr event kind 14
  ///
  /// In en, this message translates to:
  /// **'Direct Message'**
  String get directMessage;

  /// Nostr event kind 15
  ///
  /// In en, this message translates to:
  /// **'File Message'**
  String get fileMessage;

  /// Nostr event kind 16
  ///
  /// In en, this message translates to:
  /// **'Generic Repost'**
  String get genericRepost;

  /// Nostr event kind 17
  ///
  /// In en, this message translates to:
  /// **'Reaction to a website'**
  String get reactionToWebsite;

  /// Nostr event kind 20
  ///
  /// In en, this message translates to:
  /// **'Picture'**
  String get picture;

  /// Nostr event kind 21
  ///
  /// In en, this message translates to:
  /// **'Video Event'**
  String get videoEvent;

  /// Nostr event kind 22
  ///
  /// In en, this message translates to:
  /// **'Short-form Portrait Video Event'**
  String get shortFormPortraitVideoEvent;

  /// Nostr event kind 30
  ///
  /// In en, this message translates to:
  /// **'Internal reference'**
  String get internalReference;

  /// Nostr event kind 31
  ///
  /// In en, this message translates to:
  /// **'External reference'**
  String get externalReference;

  /// Nostr event kind 32
  ///
  /// In en, this message translates to:
  /// **'Hardcopy reference'**
  String get hardcopyReference;

  /// Nostr event kind 33
  ///
  /// In en, this message translates to:
  /// **'Prompt reference'**
  String get promptReference;

  /// Nostr event kind 40
  ///
  /// In en, this message translates to:
  /// **'Channel Creation'**
  String get channelCreation;

  /// Nostr event kind 41
  ///
  /// In en, this message translates to:
  /// **'Channel Metadata'**
  String get channelMetadata;

  /// Nostr event kind 42
  ///
  /// In en, this message translates to:
  /// **'Channel Message'**
  String get channelMessage;

  /// Nostr event kind 43
  ///
  /// In en, this message translates to:
  /// **'Channel Hide Message'**
  String get channelHideMessage;

  /// Nostr event kind 44
  ///
  /// In en, this message translates to:
  /// **'Channel Mute User'**
  String get channelMuteUser;

  /// Nostr event kind 62
  ///
  /// In en, this message translates to:
  /// **'Request to Vanish'**
  String get requestToVanish;

  /// Nostr event kind 64
  ///
  /// In en, this message translates to:
  /// **'Chess (PGN)'**
  String get chessPgn;

  /// Nostr event kind 443
  ///
  /// In en, this message translates to:
  /// **'MLS KeyPackage'**
  String get mlsKeyPackage;

  /// Nostr event kind 444
  ///
  /// In en, this message translates to:
  /// **'MLS Welcome'**
  String get mlsWelcome;

  /// Nostr event kind 445
  ///
  /// In en, this message translates to:
  /// **'MLS Group Event'**
  String get mlsGroupEvent;

  /// Nostr event kind 818
  ///
  /// In en, this message translates to:
  /// **'Merge Requests'**
  String get mergeRequests;

  /// Nostr event kind 1018
  ///
  /// In en, this message translates to:
  /// **'Poll Response'**
  String get pollResponse;

  /// Nostr event kind 1021
  ///
  /// In en, this message translates to:
  /// **'Marketplace Bid'**
  String get marketplaceBid;

  /// Nostr event kind 1022
  ///
  /// In en, this message translates to:
  /// **'Marketplace Bid Confirmation'**
  String get marketplaceBidConfirmation;

  /// Nostr event kind 1040
  ///
  /// In en, this message translates to:
  /// **'OpenTimestamps'**
  String get openTimestamps;

  /// Nostr event kind 1059
  ///
  /// In en, this message translates to:
  /// **'Gift Wrap'**
  String get giftWrap;

  /// Nostr event kind 1063
  ///
  /// In en, this message translates to:
  /// **'File Metadata'**
  String get fileMetadata;

  /// Nostr event kind 1068
  ///
  /// In en, this message translates to:
  /// **'Poll'**
  String get poll;

  /// Nostr event kind 1111
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// Nostr event kind 1222
  ///
  /// In en, this message translates to:
  /// **'Voice Message'**
  String get voiceMessage;

  /// Nostr event kind 1244
  ///
  /// In en, this message translates to:
  /// **'Voice Message Comment'**
  String get voiceMessageComment;

  /// Nostr event kind 1311
  ///
  /// In en, this message translates to:
  /// **'Live Chat Message'**
  String get liveChatMessage;

  /// Nostr event kind 1337
  ///
  /// In en, this message translates to:
  /// **'Code Snippet'**
  String get codeSnippet;

  /// Nostr event kind 1617
  ///
  /// In en, this message translates to:
  /// **'Git Patch'**
  String get gitPatch;

  /// Nostr event kind 1618
  ///
  /// In en, this message translates to:
  /// **'Git Pull Request'**
  String get gitPullRequest;

  /// Nostr event kind 1619
  ///
  /// In en, this message translates to:
  /// **'Git Status Update'**
  String get gitStatusUpdate;

  /// Nostr event kind 1621
  ///
  /// In en, this message translates to:
  /// **'Git Issue'**
  String get gitIssue;

  /// Nostr event kind 1622
  ///
  /// In en, this message translates to:
  /// **'Git Issue Update'**
  String get gitIssueUpdate;

  /// Nostr event kind 1630
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// Nostr event kind 1631
  ///
  /// In en, this message translates to:
  /// **'Status Update'**
  String get statusUpdate;

  /// Nostr event kind 1632
  ///
  /// In en, this message translates to:
  /// **'Status Delete'**
  String get statusDelete;

  /// Nostr event kind 1633
  ///
  /// In en, this message translates to:
  /// **'Status Reply'**
  String get statusReply;

  /// Nostr event kind 1971
  ///
  /// In en, this message translates to:
  /// **'Problem Tracker'**
  String get problemTracker;

  /// Nostr event kind 1984
  ///
  /// In en, this message translates to:
  /// **'Reporting'**
  String get reporting;

  /// Nostr event kind 1985
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get label;

  /// Nostr event kind 1986
  ///
  /// In en, this message translates to:
  /// **'Relay reviews'**
  String get relayReviews;

  /// Nostr event kind 1987
  ///
  /// In en, this message translates to:
  /// **'AI Embeddings / Vector lists'**
  String get aiEmbeddings;

  /// Nostr event kind 2003
  ///
  /// In en, this message translates to:
  /// **'Torrent'**
  String get torrent;

  /// Nostr event kind 2004
  ///
  /// In en, this message translates to:
  /// **'Torrent Comment'**
  String get torrentComment;

  /// Nostr event kind 2022
  ///
  /// In en, this message translates to:
  /// **'Coinjoin Pool'**
  String get coinjoinPool;

  /// Nostr event kind 4550
  ///
  /// In en, this message translates to:
  /// **'Community Post Approval'**
  String get communityPostApproval;

  /// Nostr event kinds 5000-5999
  ///
  /// In en, this message translates to:
  /// **'Job Request'**
  String get jobRequest;

  /// Nostr event kinds 6000-6999
  ///
  /// In en, this message translates to:
  /// **'Job Result'**
  String get jobResult;

  /// Nostr event kind 7000
  ///
  /// In en, this message translates to:
  /// **'Job Feedback'**
  String get jobFeedback;

  /// Nostr event kind 7374
  ///
  /// In en, this message translates to:
  /// **'Cashu Wallet Token'**
  String get cashuWalletToken;

  /// Nostr event kind 7375
  ///
  /// In en, this message translates to:
  /// **'Cashu Wallet Proofs'**
  String get cashuWalletProofs;

  /// Nostr event kind 7376
  ///
  /// In en, this message translates to:
  /// **'Cashu Wallet History'**
  String get cashuWalletHistory;

  /// Nostr event kind 7516
  ///
  /// In en, this message translates to:
  /// **'Geocache Create'**
  String get geocacheCreate;

  /// Nostr event kind 7517
  ///
  /// In en, this message translates to:
  /// **'Geocache Update'**
  String get geocacheUpdate;

  /// Nostr event kinds 9000-9030
  ///
  /// In en, this message translates to:
  /// **'Group Control Event'**
  String get groupControlEvent;

  /// Nostr event kind 9041
  ///
  /// In en, this message translates to:
  /// **'Zap Goal'**
  String get zapGoal;

  /// Nostr event kind 9321
  ///
  /// In en, this message translates to:
  /// **'Nutzap'**
  String get nutzap;

  /// Nostr event kind 9467
  ///
  /// In en, this message translates to:
  /// **'Tidal login'**
  String get tidalLogin;

  /// Nostr event kind 9734
  ///
  /// In en, this message translates to:
  /// **'Zap Request'**
  String get zapRequest;

  /// Nostr event kind 9735
  ///
  /// In en, this message translates to:
  /// **'Zap'**
  String get zap;

  /// Nostr event kind 9802
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get highlights;

  /// Nostr event kind 10000
  ///
  /// In en, this message translates to:
  /// **'Mute List'**
  String get muteList;

  /// Nostr event kind 10001
  ///
  /// In en, this message translates to:
  /// **'Pin List'**
  String get pinList;

  /// Nostr event kind 10002
  ///
  /// In en, this message translates to:
  /// **'Relay List Metadata'**
  String get relayListMetadata;

  /// Nostr event kind 10003
  ///
  /// In en, this message translates to:
  /// **'Bookmark List'**
  String get bookmarkList;

  /// Nostr event kind 10004
  ///
  /// In en, this message translates to:
  /// **'Communities List'**
  String get communitiesList;

  /// Nostr event kind 10005
  ///
  /// In en, this message translates to:
  /// **'Public Chats List'**
  String get publicChatsList;

  /// Nostr event kind 10006
  ///
  /// In en, this message translates to:
  /// **'Blocked Relays List'**
  String get blockedRelaysList;

  /// Nostr event kind 10007
  ///
  /// In en, this message translates to:
  /// **'Search Relays List'**
  String get searchRelaysList;

  /// Nostr event kind 10009
  ///
  /// In en, this message translates to:
  /// **'User Groups'**
  String get userGroups;

  /// Nostr event kind 10012
  ///
  /// In en, this message translates to:
  /// **'Favorites List'**
  String get favoritesList;

  /// Nostr event kind 10013
  ///
  /// In en, this message translates to:
  /// **'Private Events List'**
  String get privateEventsList;

  /// Nostr event kind 10015
  ///
  /// In en, this message translates to:
  /// **'Interests List'**
  String get interestsList;

  /// Nostr event kind 10019
  ///
  /// In en, this message translates to:
  /// **'Media Follows List'**
  String get mediaFollowsList;

  /// Nostr event kind 10020
  ///
  /// In en, this message translates to:
  /// **'People Follows List'**
  String get peopleFollowsList;

  /// Nostr event kind 10030
  ///
  /// In en, this message translates to:
  /// **'User Emoji List'**
  String get userEmojiList;

  /// Nostr event kind 10050
  ///
  /// In en, this message translates to:
  /// **'DM Relay List'**
  String get dmRelayList;

  /// Nostr event kind 10051
  ///
  /// In en, this message translates to:
  /// **'KeyPackage Relay List'**
  String get keyPackageRelayList;

  /// Nostr event kind 10063
  ///
  /// In en, this message translates to:
  /// **'User Server List'**
  String get userServerList;

  /// Nostr event kind 10096
  ///
  /// In en, this message translates to:
  /// **'File Storage Server List'**
  String get fileStorageServerList;

  /// Nostr event kind 10166
  ///
  /// In en, this message translates to:
  /// **'Relay Monitor Announcement'**
  String get relayMonitorAnnouncement;

  /// Nostr event kind 10312
  ///
  /// In en, this message translates to:
  /// **'Room Presence'**
  String get roomPresence;

  /// Nostr event kind 10377
  ///
  /// In en, this message translates to:
  /// **'Proxy Announcement'**
  String get proxyAnnouncement;

  /// Nostr event kind 11111
  ///
  /// In en, this message translates to:
  /// **'Transport Method Announcement'**
  String get transportMethodAnnouncement;

  /// Nostr event kind 13194
  ///
  /// In en, this message translates to:
  /// **'Wallet Info'**
  String get walletInfo;

  /// Nostr event kind 17375
  ///
  /// In en, this message translates to:
  /// **'Cashu Wallet Event'**
  String get cashuWalletEvent;

  /// Nostr event kind 21000
  ///
  /// In en, this message translates to:
  /// **'Lightning Pub RPC'**
  String get lightningPubRpc;

  /// Nostr event kind 22242
  ///
  /// In en, this message translates to:
  /// **'Client Authentication'**
  String get clientAuthentication;

  /// Nostr event kind 23194
  ///
  /// In en, this message translates to:
  /// **'Wallet Request'**
  String get walletRequest;

  /// Nostr event kind 23195
  ///
  /// In en, this message translates to:
  /// **'Wallet Response'**
  String get walletResponse;

  /// Nostr event kind 24133
  ///
  /// In en, this message translates to:
  /// **'Nostr Connect'**
  String get nostrConnectEvent;

  /// Nostr event kind 24242
  ///
  /// In en, this message translates to:
  /// **'Blobs stored on mediaservers'**
  String get blobsStoredOnMediaservers;

  /// Nostr event kind 27235
  ///
  /// In en, this message translates to:
  /// **'HTTP Auth'**
  String get httpAuth;

  /// Nostr event kind 30000
  ///
  /// In en, this message translates to:
  /// **'Categorized People List'**
  String get categorizedPeopleList;

  /// Nostr event kind 30001
  ///
  /// In en, this message translates to:
  /// **'Categorized Bookmark List'**
  String get categorizedBookmarkList;

  /// Nostr event kind 30002
  ///
  /// In en, this message translates to:
  /// **'Categorized Relay List'**
  String get categorizedRelayList;

  /// Nostr event kind 30003
  ///
  /// In en, this message translates to:
  /// **'Bookmark Sets'**
  String get bookmarkSets;

  /// Nostr event kind 30004
  ///
  /// In en, this message translates to:
  /// **'Curation Sets'**
  String get curationSets;

  /// Nostr event kind 30005
  ///
  /// In en, this message translates to:
  /// **'Video Sets'**
  String get videoSets;

  /// Nostr event kind 30007
  ///
  /// In en, this message translates to:
  /// **'Kind Mute Sets'**
  String get kindMuteSets;

  /// Nostr event kind 30008
  ///
  /// In en, this message translates to:
  /// **'Profile Badges'**
  String get profileBadges;

  /// Nostr event kind 30009
  ///
  /// In en, this message translates to:
  /// **'Badge Definition'**
  String get badgeDefinition;

  /// Nostr event kind 30015
  ///
  /// In en, this message translates to:
  /// **'Interest Sets'**
  String get interestSets;

  /// Nostr event kind 30017
  ///
  /// In en, this message translates to:
  /// **'Create or Update Stall'**
  String get createOrUpdateStall;

  /// Nostr event kind 30018
  ///
  /// In en, this message translates to:
  /// **'Create or Update Product'**
  String get createOrUpdateProduct;

  /// Nostr event kind 30019
  ///
  /// In en, this message translates to:
  /// **'Marketplace UI/UX'**
  String get marketplaceUiUx;

  /// Nostr event kind 30020
  ///
  /// In en, this message translates to:
  /// **'Product Sold as Auction'**
  String get productSoldAsAuction;

  /// Nostr event kind 30023
  ///
  /// In en, this message translates to:
  /// **'Long-form Content'**
  String get longFormContent;

  /// Nostr event kind 30024
  ///
  /// In en, this message translates to:
  /// **'Draft Long-form Content'**
  String get draftLongFormContent;

  /// Nostr event kind 30030
  ///
  /// In en, this message translates to:
  /// **'Emoji Sets'**
  String get emojiSets;

  /// Nostr event kind 30040
  ///
  /// In en, this message translates to:
  /// **'Curated Publication Item'**
  String get curatedPublicationItem;

  /// Nostr event kind 30041
  ///
  /// In en, this message translates to:
  /// **'Curated Publication Draft'**
  String get curatedPublicationDraft;

  /// Nostr event kind 30063
  ///
  /// In en, this message translates to:
  /// **'Release Artifact Sets'**
  String get releaseArtifactSets;

  /// Nostr event kind 30078
  ///
  /// In en, this message translates to:
  /// **'Application-specific Data'**
  String get applicationSpecificData;

  /// Nostr event kind 30166
  ///
  /// In en, this message translates to:
  /// **'Relay Discovery'**
  String get relayDiscovery;

  /// Nostr event kind 30267
  ///
  /// In en, this message translates to:
  /// **'App Curation Sets'**
  String get appCurationSets;

  /// Nostr event kind 30311
  ///
  /// In en, this message translates to:
  /// **'Live Event'**
  String get liveEvent;

  /// Nostr event kind 30315
  ///
  /// In en, this message translates to:
  /// **'User Status'**
  String get userStatus;

  /// Nostr event kind 30388
  ///
  /// In en, this message translates to:
  /// **'Slide Set'**
  String get slideSet;

  /// Nostr event kind 30402
  ///
  /// In en, this message translates to:
  /// **'Classified Listing'**
  String get classifiedListing;

  /// Nostr event kind 30403
  ///
  /// In en, this message translates to:
  /// **'Draft Classified Listing'**
  String get draftClassifiedListing;

  /// Nostr event kind 30617
  ///
  /// In en, this message translates to:
  /// **'Repository Announcement'**
  String get repositoryAnnouncement;

  /// Nostr event kind 30618
  ///
  /// In en, this message translates to:
  /// **'Repository State Announcement'**
  String get repositoryStateAnnouncement;

  /// Nostr event kind 30818
  ///
  /// In en, this message translates to:
  /// **'Wiki Article'**
  String get wikiArticle;

  /// Nostr event kind 30819
  ///
  /// In en, this message translates to:
  /// **'Redirects'**
  String get redirects;

  /// Nostr event kind 31234
  ///
  /// In en, this message translates to:
  /// **'Draft Event'**
  String get draftEvent;

  /// Nostr event kind 31388
  ///
  /// In en, this message translates to:
  /// **'Link Set'**
  String get linkSet;

  /// Nostr event kind 31890
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get feed;

  /// Nostr event kind 31922
  ///
  /// In en, this message translates to:
  /// **'Date-Based Calendar Event'**
  String get dateBasedCalendarEvent;

  /// Nostr event kind 31923
  ///
  /// In en, this message translates to:
  /// **'Time-Based Calendar Event'**
  String get timeBasedCalendarEvent;

  /// Nostr event kind 31924
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// Nostr event kind 31925
  ///
  /// In en, this message translates to:
  /// **'Calendar Event RSVP'**
  String get calendarEventRsvp;

  /// Nostr event kind 31989
  ///
  /// In en, this message translates to:
  /// **'Handler Recommendation'**
  String get handlerRecommendation;

  /// Nostr event kind 31990
  ///
  /// In en, this message translates to:
  /// **'Handler Information'**
  String get handlerInformation;

  /// Nostr event kind 32267
  ///
  /// In en, this message translates to:
  /// **'Software Application'**
  String get softwareApplication;

  /// Nostr event kind 34237
  ///
  /// In en, this message translates to:
  /// **'Video View'**
  String get videoView;

  /// Nostr event kind 34550
  ///
  /// In en, this message translates to:
  /// **'Community Definition'**
  String get communityDefinition;

  /// Nostr event kind 37516
  ///
  /// In en, this message translates to:
  /// **'Geocache Listing'**
  String get geocacheListing;

  /// Nostr event kind 38172
  ///
  /// In en, this message translates to:
  /// **'Mint Announcement'**
  String get mintAnnouncement;

  /// Nostr event kind 38173
  ///
  /// In en, this message translates to:
  /// **'Mint Quote'**
  String get mintQuote;

  /// Nostr event kind 38383
  ///
  /// In en, this message translates to:
  /// **'Peer-to-peer Order'**
  String get peerToPeerOrder;

  /// Nostr event kind 39000
  ///
  /// In en, this message translates to:
  /// **'Group Metadata'**
  String get groupMetadata;

  /// Nostr event kind 39001
  ///
  /// In en, this message translates to:
  /// **'Group Admin Metadata'**
  String get groupAdminMetadata;

  /// Nostr event kind 39002
  ///
  /// In en, this message translates to:
  /// **'Group Member Metadata'**
  String get groupMemberMetadata;

  /// Nostr event kind 39003
  ///
  /// In en, this message translates to:
  /// **'Group Admins List'**
  String get groupAdminsList;

  /// Nostr event kind 39004
  ///
  /// In en, this message translates to:
  /// **'Group Members List'**
  String get groupMembersList;

  /// Nostr event kind 39005
  ///
  /// In en, this message translates to:
  /// **'Group Roles'**
  String get groupRoles;

  /// Nostr event kind 39006
  ///
  /// In en, this message translates to:
  /// **'Group Permissions'**
  String get groupPermissions;

  /// Nostr event kind 39007
  ///
  /// In en, this message translates to:
  /// **'Group Chat Message'**
  String get groupChatMessage;

  /// Nostr event kind 39008
  ///
  /// In en, this message translates to:
  /// **'Group Chat Thread'**
  String get groupChatThread;

  /// Nostr event kind 39009
  ///
  /// In en, this message translates to:
  /// **'Group Pinned'**
  String get groupPinned;

  /// Nostr event kind 39089
  ///
  /// In en, this message translates to:
  /// **'Starter Packs'**
  String get starterPacks;

  /// Nostr event kind 39092
  ///
  /// In en, this message translates to:
  /// **'Media Starter Packs'**
  String get mediaStarterPacks;

  /// Nostr event kind 39701
  ///
  /// In en, this message translates to:
  /// **'Web Bookmarks'**
  String get webBookmarks;

  /// Fallback for unknown event kinds
  ///
  /// In en, this message translates to:
  /// **'Event Kind {kind}'**
  String unknownEventKind(int kind);

  /// Title for wallets section
  ///
  /// In en, this message translates to:
  /// **'Wallets'**
  String get walletsTitle;

  /// Title for recent activity section
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivityTitle;

  /// Label for add Cashu wallet button
  ///
  /// In en, this message translates to:
  /// **'Add Cashu Wallet'**
  String get addCashuWallet;

  /// Label for add NWC wallet button
  ///
  /// In en, this message translates to:
  /// **'Add NWC Wallet'**
  String get addNwcWallet;

  /// Label for add LNURL wallet button
  ///
  /// In en, this message translates to:
  /// **'Add LNURL Wallet'**
  String get addLnurlWallet;

  /// Tooltip for add Cashu wallet button
  ///
  /// In en, this message translates to:
  /// **'Add Cashu Wallet'**
  String get addCashuTooltip;

  /// Tooltip for add NWC wallet button
  ///
  /// In en, this message translates to:
  /// **'Add NWC Wallet'**
  String get addNwcTooltip;

  /// Tooltip for add LNURL wallet button
  ///
  /// In en, this message translates to:
  /// **'Add LNURL Wallet'**
  String get addLnurlTooltip;

  /// Title for add Cashu wallet dialog
  ///
  /// In en, this message translates to:
  /// **'Add Cashu Wallet'**
  String get addCashuWalletTitle;

  /// Prompt for mint URL input
  ///
  /// In en, this message translates to:
  /// **'Enter the mint URL to add a Cashu wallet.'**
  String get enterMintUrl;

  /// Label for mint URL input
  ///
  /// In en, this message translates to:
  /// **'Mint URL'**
  String get mintUrl;

  /// Hint for mint URL input
  ///
  /// In en, this message translates to:
  /// **'https://mint.example.com'**
  String get mintUrlHint;

  /// Error message for empty mint URL
  ///
  /// In en, this message translates to:
  /// **'Please enter a mint URL'**
  String get pleaseEnterMintUrl;

  /// Success message when Cashu wallet is added
  ///
  /// In en, this message translates to:
  /// **'Cashu wallet added successfully!'**
  String get cashuWalletAdded;

  /// Error message when adding Cashu wallet fails
  ///
  /// In en, this message translates to:
  /// **'Failed to add mint. Please check the URL and try again.'**
  String get failedToAddMint;

  /// Title for add NWC wallet dialog
  ///
  /// In en, this message translates to:
  /// **'Add NWC Wallet'**
  String get addNwcWalletTitle;

  /// Tab label for faucet option
  ///
  /// In en, this message translates to:
  /// **'Faucet'**
  String get faucet;

  /// Tab label for manual option
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manual;

  /// Description for NWC faucet
  ///
  /// In en, this message translates to:
  /// **'Create a test wallet with sats from the NWC faucet.'**
  String get nwcFaucetDescription;

  /// Label for starting balance input
  ///
  /// In en, this message translates to:
  /// **'Starting Balance'**
  String get startingBalance;

  /// Hint for starting balance input
  ///
  /// In en, this message translates to:
  /// **'10000'**
  String get startingBalanceHint;

  /// Label for NWC connection URI input
  ///
  /// In en, this message translates to:
  /// **'NWC Connection URI'**
  String get nwcConnectionUri;

  /// Hint for NWC connection URI input
  ///
  /// In en, this message translates to:
  /// **'nostr+walletconnect://...'**
  String get nwcConnectionUriHint;

  /// Success message when NWC wallet is added
  ///
  /// In en, this message translates to:
  /// **'NWC wallet added successfully!'**
  String get nwcWalletAdded;

  /// Success message when NWC faucet wallet is added
  ///
  /// In en, this message translates to:
  /// **'NWC faucet wallet added with {balance} sats!'**
  String nwcFaucetWalletAdded(int balance);

  /// Error message for invalid faucet response
  ///
  /// In en, this message translates to:
  /// **'Invalid response from faucet'**
  String get invalidFaucetResponse;

  /// Error message when creating NWC wallet fails
  ///
  /// In en, this message translates to:
  /// **'Error creating wallet'**
  String get errorCreatingWallet;

  /// Title for add LNURL wallet dialog
  ///
  /// In en, this message translates to:
  /// **'Add LNURL Wallet'**
  String get addLnurlWalletTitle;

  /// Prompt for LNURL identifier input
  ///
  /// In en, this message translates to:
  /// **'Enter your LNURL identifier (user@domain.com).'**
  String get enterLnurlIdentifier;

  /// Hint for LNURL identifier input
  ///
  /// In en, this message translates to:
  /// **'user@example.com'**
  String get lnurlIdentifierHint;

  /// Error message for invalid LNURL identifier
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid identifier (user@domain.com)'**
  String get pleaseEnterValidIdentifier;

  /// Success message when LNURL wallet is added
  ///
  /// In en, this message translates to:
  /// **'LNURL wallet added successfully!'**
  String get lnurlWalletAdded;

  /// Button label for cancel action
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Button label for add action
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Label for send action
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// Label for receive action
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get receive;

  /// Title for send options sheet
  ///
  /// In en, this message translates to:
  /// **'Send Options'**
  String get sendOptionsTitle;

  /// Option for sending by token
  ///
  /// In en, this message translates to:
  /// **'Send by Token'**
  String get sendByToken;

  /// Description for send by token option
  ///
  /// In en, this message translates to:
  /// **'Create a Cashu token to send'**
  String get sendByTokenDescription;

  /// Option for sending by Lightning
  ///
  /// In en, this message translates to:
  /// **'Send by Lightning'**
  String get sendByLightning;

  /// Description for send by Lightning option
  ///
  /// In en, this message translates to:
  /// **'Pay a Lightning invoice'**
  String get sendByLightningDescription;

  /// Title for pay invoice dialog
  ///
  /// In en, this message translates to:
  /// **'Pay Invoice'**
  String get payInvoiceTitle;

  /// Label for invoice input
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoice;

  /// Hint for invoice input
  ///
  /// In en, this message translates to:
  /// **'lnbc...'**
  String get invoiceHint;

  /// Error message for empty invoice
  ///
  /// In en, this message translates to:
  /// **'Please enter an invoice'**
  String get pleaseEnterInvoice;

  /// Success message when invoice is paid
  ///
  /// In en, this message translates to:
  /// **'Invoice paid!'**
  String get invoicePaid;

  /// Error message when payment fails
  ///
  /// In en, this message translates to:
  /// **'Payment failed: {message}'**
  String paymentFailed(String message);

  /// Title for receive options sheet
  ///
  /// In en, this message translates to:
  /// **'Receive Options'**
  String get receiveOptionsTitle;

  /// Option for receiving by token
  ///
  /// In en, this message translates to:
  /// **'Receive by Token'**
  String get receiveByToken;

  /// Description for receive by token option
  ///
  /// In en, this message translates to:
  /// **'Receive a Cashu token'**
  String get receiveByTokenDescription;

  /// Option for receiving by Lightning
  ///
  /// In en, this message translates to:
  /// **'Receive by Lightning'**
  String get receiveByLightning;

  /// Description for receive by Lightning option
  ///
  /// In en, this message translates to:
  /// **'Create a Lightning invoice'**
  String get receiveByLightningDescription;

  /// Title for receive by token dialog
  ///
  /// In en, this message translates to:
  /// **'Receive by Token'**
  String get receiveByTokenTitle;

  /// Label for token input
  ///
  /// In en, this message translates to:
  /// **'Token'**
  String get token;

  /// Hint for token input
  ///
  /// In en, this message translates to:
  /// **'Paste token here...'**
  String get tokenHint;

  /// Error message for empty token
  ///
  /// In en, this message translates to:
  /// **'Please enter a token'**
  String get pleaseEnterToken;

  /// Success message when token is received
  ///
  /// In en, this message translates to:
  /// **'Token received!'**
  String get tokenReceived;

  /// Title for create invoice dialog
  ///
  /// In en, this message translates to:
  /// **'Create Invoice'**
  String get createInvoiceTitle;

  /// Label for amount input
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// Hint for amount input
  ///
  /// In en, this message translates to:
  /// **'100'**
  String get amountHint;

  /// Error message for invalid amount
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get pleaseEnterValidAmount;

  /// Success message when token is copied to clipboard
  ///
  /// In en, this message translates to:
  /// **'Token copied to clipboard!'**
  String get tokenCopiedToClipboard;

  /// Success message when invoice is created and copied
  ///
  /// In en, this message translates to:
  /// **'Invoice created and copied!'**
  String get invoiceCreatedAndCopied;

  /// Title for invoice tracking dialog
  ///
  /// In en, this message translates to:
  /// **'Lightning Invoice'**
  String get invoiceTrackingTitle;

  /// Message shown when invoice is created
  ///
  /// In en, this message translates to:
  /// **'Invoice created and copied!'**
  String get invoiceCreatedMessage;

  /// Label for close button
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Label for copy again button
  ///
  /// In en, this message translates to:
  /// **'Copy Again'**
  String get copyAgain;

  /// Message shown when copied
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get copied;

  /// Message shown when payment is received
  ///
  /// In en, this message translates to:
  /// **'Payment received!'**
  String get paymentReceived;

  /// Status message while waiting for payment
  ///
  /// In en, this message translates to:
  /// **'Waiting for payment...'**
  String get waitingForPayment;

  /// Status message when payment is complete
  ///
  /// In en, this message translates to:
  /// **'Paid!'**
  String get paid;

  /// Label for create token button
  ///
  /// In en, this message translates to:
  /// **'Create Token'**
  String get createToken;

  /// Label for pay button
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// Label for create button
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Title for pending transactions section
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingTransactions;

  /// Title for recent transactions section
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// Message shown when there are no recent transactions
  ///
  /// In en, this message translates to:
  /// **'No recent transactions'**
  String get noRecentTransactions;

  /// Message shown when there are no wallets
  ///
  /// In en, this message translates to:
  /// **'No wallets yet'**
  String get noWalletsYet;

  /// Message shown when no wallets are available
  ///
  /// In en, this message translates to:
  /// **'No wallets available'**
  String get noWalletsAvailable;

  /// Hint to add a wallet
  ///
  /// In en, this message translates to:
  /// **'Tap + to add one'**
  String get tapToAddWallet;

  /// Label for delete action
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Error message for general errors
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String error(String message);

  /// Label for unknown wallet type
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownWalletType;

  /// Label for Cashu wallet type
  ///
  /// In en, this message translates to:
  /// **'Cashu'**
  String get cashuWallet;

  /// Label for NWC wallet type
  ///
  /// In en, this message translates to:
  /// **'NWC'**
  String get nwcWallet;

  /// Label for LNURL wallet type
  ///
  /// In en, this message translates to:
  /// **'LNURL'**
  String get lnurlWallet;

  /// Subtitle for NWC wallet
  ///
  /// In en, this message translates to:
  /// **'NWC Wallet'**
  String get nwcWalletSubtitle;

  /// Label for balance display
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// Label for sats
  ///
  /// In en, this message translates to:
  /// **'sats'**
  String get sats;

  /// Label shown when a wallet is selected
  ///
  /// In en, this message translates to:
  /// **'SELECTED'**
  String get selected;

  /// Label for receive-only wallet
  ///
  /// In en, this message translates to:
  /// **'Receive-only wallet'**
  String get receiveOnlyWallet;

  /// Label showing receive range for LNURL wallet
  ///
  /// In en, this message translates to:
  /// **'Receive: {min} - {max} sats'**
  String receiveRange(int min, int max);

  /// Message shown when limits are unavailable
  ///
  /// In en, this message translates to:
  /// **'Limits unavailable'**
  String get limitsUnavailable;

  /// Message shown when token is copied
  ///
  /// In en, this message translates to:
  /// **'Token copied'**
  String get tokenCopied;

  /// Title for delete wallet confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Wallet?'**
  String get deleteWalletConfirmation;

  /// Message for delete wallet confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this wallet? This action cannot be undone.'**
  String get deleteWalletConfirmationMessage;

  /// Title for add wallet dialog
  ///
  /// In en, this message translates to:
  /// **'Add Wallet'**
  String get addWalletTitle;

  /// Prompt to choose wallet type
  ///
  /// In en, this message translates to:
  /// **'Choose wallet type'**
  String get chooseWalletType;

  /// Label for Cashu wallet option
  ///
  /// In en, this message translates to:
  /// **'Cashu'**
  String get cashuOption;

  /// Label for NWC wallet option
  ///
  /// In en, this message translates to:
  /// **'NWC'**
  String get nwcOption;

  /// Label for LNURL wallet option
  ///
  /// In en, this message translates to:
  /// **'LNURL'**
  String get lnurlOption;

  /// Title for NWC connection dialog
  ///
  /// In en, this message translates to:
  /// **'Connect NWC'**
  String get connectNwcTitle;

  /// Prompt to choose NWC connection method
  ///
  /// In en, this message translates to:
  /// **'Choose connection method'**
  String get chooseNwcMethod;

  /// Label for Alby Go option
  ///
  /// In en, this message translates to:
  /// **'Alby Go'**
  String get albyGoOption;

  /// Label for manual connection option
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manualOption;

  /// Label for faucet option
  ///
  /// In en, this message translates to:
  /// **'Faucet'**
  String get faucetOption;

  /// Error message for invalid NWC QR code
  ///
  /// In en, this message translates to:
  /// **'Invalid NWC QR code'**
  String get invalidNwcQrCode;

  /// Title for scanning NWC QR code
  ///
  /// In en, this message translates to:
  /// **'Scan NWC QR Code'**
  String get scanNwcQrCodeTitle;

  /// Message shown when camera is not available
  ///
  /// In en, this message translates to:
  /// **'Camera not available'**
  String get cameraNotAvailable;

  /// Instructions for scanning NWC QR code
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code from your NWC wallet app'**
  String get scanNwcInstructions;

  /// Error message for invalid NWC URI
  ///
  /// In en, this message translates to:
  /// **'Invalid NWC URI'**
  String get invalidNwcUri;

  /// Label for paste action
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// Label indicating a value comes from user's profile
  ///
  /// In en, this message translates to:
  /// **'From your profile'**
  String get fromYourProfile;

  /// Label for manual entry option
  ///
  /// In en, this message translates to:
  /// **'Or enter manually:'**
  String get orEnterManually;

  /// Label for rename wallet option
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameWallet;

  /// Label for pick color option
  ///
  /// In en, this message translates to:
  /// **'Pick Color'**
  String get pickColor;

  /// Label for delete wallet option
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteWallet;

  /// Label for wallet name input
  ///
  /// In en, this message translates to:
  /// **'Wallet Name'**
  String get walletName;

  /// Hint for wallet name input
  ///
  /// In en, this message translates to:
  /// **'Enter wallet name'**
  String get walletNameHint;

  /// Label for save action
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Message shown when wallet is renamed
  ///
  /// In en, this message translates to:
  /// **'Wallet renamed'**
  String get walletRenamed;

  /// Budget information showing used and total amount
  ///
  /// In en, this message translates to:
  /// **'Budget: {used} / {total}'**
  String budgetUsedOf(int used, int total);

  /// Budget renewal information showing days until renewal
  ///
  /// In en, this message translates to:
  /// **'Renews in {days} days'**
  String budgetRenewsIn(int days);

  /// Daily budget renewal period
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get budgetDaily;

  /// Weekly budget renewal period
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get budgetWeekly;

  /// Monthly budget renewal period
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get budgetMonthly;

  /// Yearly budget renewal period
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get budgetYearly;

  /// Never renews budget
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get budgetNever;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en', 'es', 'fr', 'it', 'ja', 'pl', 'ru', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'fr': return AppLocalizationsFr();
    case 'it': return AppLocalizationsIt();
    case 'ja': return AppLocalizationsJa();
    case 'pl': return AppLocalizationsPl();
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
