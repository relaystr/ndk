// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get createAccount => 'Créer votre compte';

  @override
  String get newHere => 'Êtes-vous nouveau ici?';

  @override
  String get nostrAddress => 'Adresse Nostr';

  @override
  String get publicKey => 'Clé publique';

  @override
  String get privateKey => 'Clé privée (non sécurisé)';

  @override
  String get browserExtension => 'Extension de navigateur';

  @override
  String get connect => 'Se connecter';

  @override
  String get install => 'Installer';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get nostrAddressHint => 'nom@exemple.com';

  @override
  String get invalidAddress => 'Adresse invalide';

  @override
  String get unableToConnect => 'Impossible de se connecter';

  @override
  String get publicKeyHint => 'npub1...';

  @override
  String get privateKeyHint => 'nsec1...';

  @override
  String get newToNostr => 'Nouveau sur Nostr?';

  @override
  String get getStarted => 'Commencer';

  @override
  String get bunker => 'Bunker';

  @override
  String get bunkerAuthentication => 'Authentification Bunker';

  @override
  String tapToOpen(String url) {
    return 'Appuyez pour ouvrir: $url';
  }

  @override
  String get showNostrConnectQrcode => 'Afficher le code QR nostr connect';

  @override
  String get loginWithAmber => 'Se connecter avec Amber';

  @override
  String get nostrConnectUrl => 'URL de connexion Nostr';

  @override
  String get copy => 'Copier';

  @override
  String get addAccount => 'Ajouter un compte';

  @override
  String get readOnly => 'Lecture seule';

  @override
  String get nsec => 'Nsec';

  @override
  String get extension => 'Extension';

  @override
  String get userMetadata => 'Métadonnées utilisateur';

  @override
  String get shortTextNote => 'Note courte';

  @override
  String get recommendRelay => 'Recommander un relais';

  @override
  String get follows => 'Abonnements';

  @override
  String get encryptedDirectMessages => 'Messages directs chiffrés';

  @override
  String get eventDeletionRequest => 'Demande de suppression';

  @override
  String get repost => 'Republication';

  @override
  String get reaction => 'Réaction';

  @override
  String get badgeAward => 'Attribution de badge';

  @override
  String get chatMessage => 'Message de chat';

  @override
  String get groupChatThreadedReply => 'Réponse en fil de groupe';

  @override
  String get thread => 'Fil de discussion';

  @override
  String get groupThreadReply => 'Réponse de fil de groupe';

  @override
  String get seal => 'Sceau';

  @override
  String get directMessage => 'Message direct';

  @override
  String get fileMessage => 'Message fichier';

  @override
  String get genericRepost => 'Republication générique';

  @override
  String get reactionToWebsite => 'Réaction à un site web';

  @override
  String get picture => 'Image';

  @override
  String get videoEvent => 'Événement vidéo';

  @override
  String get shortFormPortraitVideoEvent => 'Vidéo portrait courte';

  @override
  String get internalReference => 'Référence interne';

  @override
  String get externalReference => 'Référence externe';

  @override
  String get hardcopyReference => 'Référence papier';

  @override
  String get promptReference => 'Référence de prompt';

  @override
  String get channelCreation => 'Création de canal';

  @override
  String get channelMetadata => 'Métadonnées de canal';

  @override
  String get channelMessage => 'Message de canal';

  @override
  String get channelHideMessage => 'Masquer message de canal';

  @override
  String get channelMuteUser => 'Rendre muet utilisateur';

  @override
  String get requestToVanish => 'Demande de disparition';

  @override
  String get chessPgn => 'Échecs (PGN)';

  @override
  String get mlsKeyPackage => 'Package de clés MLS';

  @override
  String get mlsWelcome => 'Bienvenue MLS';

  @override
  String get mlsGroupEvent => 'Événement de groupe MLS';

  @override
  String get mergeRequests => 'Demandes de fusion';

  @override
  String get pollResponse => 'Réponse au sondage';

  @override
  String get marketplaceBid => 'Offre de marché';

  @override
  String get marketplaceBidConfirmation => 'Confirmation d\'offre';

  @override
  String get openTimestamps => 'OpenTimestamps';

  @override
  String get giftWrap => 'Emballage cadeau';

  @override
  String get fileMetadata => 'Métadonnées de fichier';

  @override
  String get poll => 'Sondage';

  @override
  String get comment => 'Commentaire';

  @override
  String get voiceMessage => 'Message vocal';

  @override
  String get voiceMessageComment => 'Commentaire vocal';

  @override
  String get liveChatMessage => 'Message de chat en direct';

  @override
  String get codeSnippet => 'Extrait de code';

  @override
  String get gitPatch => 'Patch Git';

  @override
  String get gitPullRequest => 'Pull Request Git';

  @override
  String get gitStatusUpdate => 'Mise à jour de statut Git';

  @override
  String get gitIssue => 'Issue Git';

  @override
  String get gitIssueUpdate => 'Mise à jour d\'issue Git';

  @override
  String get status => 'Statut';

  @override
  String get statusUpdate => 'Mise à jour de statut';

  @override
  String get statusDelete => 'Suppression de statut';

  @override
  String get statusReply => 'Réponse de statut';

  @override
  String get problemTracker => 'Suivi de problèmes';

  @override
  String get reporting => 'Signalement';

  @override
  String get label => 'Étiquette';

  @override
  String get relayReviews => 'Avis sur les relais';

  @override
  String get aiEmbeddings => 'Embeddings IA / Listes vectorielles';

  @override
  String get torrent => 'Torrent';

  @override
  String get torrentComment => 'Commentaire torrent';

  @override
  String get coinjoinPool => 'Pool Coinjoin';

  @override
  String get communityPostApproval => 'Approbation de post communautaire';

  @override
  String get jobRequest => 'Demande de travail';

  @override
  String get jobResult => 'Résultat de travail';

  @override
  String get jobFeedback => 'Retour sur travail';

  @override
  String get cashuWalletToken => 'Token portefeuille Cashu';

  @override
  String get cashuWalletProofs => 'Preuves portefeuille Cashu';

  @override
  String get cashuWalletHistory => 'Historique portefeuille Cashu';

  @override
  String get geocacheCreate => 'Création de géocache';

  @override
  String get geocacheUpdate => 'Mise à jour de géocache';

  @override
  String get groupControlEvent => 'Événement de contrôle de groupe';

  @override
  String get zapGoal => 'Objectif de Zap';

  @override
  String get nutzap => 'Nutzap';

  @override
  String get tidalLogin => 'Connexion Tidal';

  @override
  String get zapRequest => 'Demande de Zap';

  @override
  String get zap => 'Zap';

  @override
  String get highlights => 'Surlignages';

  @override
  String get muteList => 'Liste de sourdine';

  @override
  String get pinList => 'Liste épinglée';

  @override
  String get relayListMetadata => 'Métadonnées liste de relais';

  @override
  String get bookmarkList => 'Liste de favoris';

  @override
  String get communitiesList => 'Liste des communautés';

  @override
  String get publicChatsList => 'Liste des chats publics';

  @override
  String get blockedRelaysList => 'Liste des relais bloqués';

  @override
  String get searchRelaysList => 'Liste des relais de recherche';

  @override
  String get userGroups => 'Groupes utilisateur';

  @override
  String get favoritesList => 'Liste des favoris';

  @override
  String get privateEventsList => 'Liste des événements privés';

  @override
  String get interestsList => 'Liste des intérêts';

  @override
  String get mediaFollowsList => 'Liste des médias suivis';

  @override
  String get peopleFollowsList => 'Liste des personnes suivies';

  @override
  String get userEmojiList => 'Liste d\'émojis utilisateur';

  @override
  String get dmRelayList => 'Liste de relais DM';

  @override
  String get keyPackageRelayList => 'Liste de relais KeyPackage';

  @override
  String get userServerList => 'Liste de serveurs utilisateur';

  @override
  String get fileStorageServerList => 'Liste de serveurs de stockage';

  @override
  String get relayMonitorAnnouncement => 'Annonce de moniteur de relais';

  @override
  String get roomPresence => 'Présence dans la salle';

  @override
  String get proxyAnnouncement => 'Annonce de proxy';

  @override
  String get transportMethodAnnouncement => 'Annonce de méthode de transport';

  @override
  String get walletInfo => 'Info portefeuille';

  @override
  String get cashuWalletEvent => 'Événement portefeuille Cashu';

  @override
  String get lightningPubRpc => 'RPC Lightning Pub';

  @override
  String get clientAuthentication => 'Authentification client';

  @override
  String get walletRequest => 'Demande de portefeuille';

  @override
  String get walletResponse => 'Réponse de portefeuille';

  @override
  String get nostrConnectEvent => 'Nostr Connect';

  @override
  String get blobsStoredOnMediaservers => 'Blobs stockés sur serveurs média';

  @override
  String get httpAuth => 'Authentification HTTP';

  @override
  String get categorizedPeopleList => 'Liste de personnes catégorisée';

  @override
  String get categorizedBookmarkList => 'Liste de favoris catégorisée';

  @override
  String get categorizedRelayList => 'Liste de relais catégorisée';

  @override
  String get bookmarkSets => 'Ensembles de favoris';

  @override
  String get curationSets => 'Ensembles de curation';

  @override
  String get videoSets => 'Ensembles de vidéos';

  @override
  String get kindMuteSets => 'Ensembles de kinds en sourdine';

  @override
  String get profileBadges => 'Badges de profil';

  @override
  String get badgeDefinition => 'Définition de badge';

  @override
  String get interestSets => 'Ensembles d\'intérêts';

  @override
  String get createOrUpdateStall => 'Créer ou mettre à jour un stand';

  @override
  String get createOrUpdateProduct => 'Créer ou mettre à jour un produit';

  @override
  String get marketplaceUiUx => 'Interface marché';

  @override
  String get productSoldAsAuction => 'Produit vendu aux enchères';

  @override
  String get longFormContent => 'Contenu long format';

  @override
  String get draftLongFormContent => 'Brouillon contenu long';

  @override
  String get emojiSets => 'Ensembles d\'émojis';

  @override
  String get curatedPublicationItem => 'Élément de publication organisée';

  @override
  String get curatedPublicationDraft => 'Brouillon de publication organisée';

  @override
  String get releaseArtifactSets => 'Ensembles d\'artefacts de release';

  @override
  String get applicationSpecificData => 'Données spécifiques à l\'application';

  @override
  String get relayDiscovery => 'Découverte de relais';

  @override
  String get appCurationSets => 'Ensembles de curation d\'apps';

  @override
  String get liveEvent => 'Événement en direct';

  @override
  String get userStatus => 'Statut utilisateur';

  @override
  String get slideSet => 'Ensemble de diapositives';

  @override
  String get classifiedListing => 'Petite annonce';

  @override
  String get draftClassifiedListing => 'Brouillon de petite annonce';

  @override
  String get repositoryAnnouncement => 'Annonce de dépôt';

  @override
  String get repositoryStateAnnouncement => 'Annonce d\'état de dépôt';

  @override
  String get wikiArticle => 'Article wiki';

  @override
  String get redirects => 'Redirections';

  @override
  String get draftEvent => 'Brouillon d\'événement';

  @override
  String get linkSet => 'Ensemble de liens';

  @override
  String get feed => 'Flux';

  @override
  String get dateBasedCalendarEvent => 'Événement calendrier par date';

  @override
  String get timeBasedCalendarEvent => 'Événement calendrier par heure';

  @override
  String get calendar => 'Calendrier';

  @override
  String get calendarEventRsvp => 'RSVP événement calendrier';

  @override
  String get handlerRecommendation => 'Recommandation de gestionnaire';

  @override
  String get handlerInformation => 'Information de gestionnaire';

  @override
  String get softwareApplication => 'Application logicielle';

  @override
  String get videoView => 'Vue vidéo';

  @override
  String get communityDefinition => 'Définition de communauté';

  @override
  String get geocacheListing => 'Liste de géocache';

  @override
  String get mintAnnouncement => 'Annonce de mint';

  @override
  String get mintQuote => 'Devis de mint';

  @override
  String get peerToPeerOrder => 'Commande pair-à-pair';

  @override
  String get groupMetadata => 'Métadonnées de groupe';

  @override
  String get groupAdminMetadata => 'Métadonnées admin de groupe';

  @override
  String get groupMemberMetadata => 'Métadonnées membre de groupe';

  @override
  String get groupAdminsList => 'Liste des admins de groupe';

  @override
  String get groupMembersList => 'Liste des membres de groupe';

  @override
  String get groupRoles => 'Rôles de groupe';

  @override
  String get groupPermissions => 'Permissions de groupe';

  @override
  String get groupChatMessage => 'Message de chat de groupe';

  @override
  String get groupChatThread => 'Fil de chat de groupe';

  @override
  String get groupPinned => 'Épinglé du groupe';

  @override
  String get starterPacks => 'Packs de démarrage';

  @override
  String get mediaStarterPacks => 'Packs médias de démarrage';

  @override
  String get webBookmarks => 'Favoris web';

  @override
  String unknownEventKind(int kind) {
    return 'Type d\'événement $kind';
  }
}
