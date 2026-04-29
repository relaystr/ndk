// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'sample_app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class SampleAppLocalizationsFr extends SampleAppLocalizations {
  SampleAppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Démo Nostr Developer Kit';

  @override
  String get appBarTitle => 'Démo NDK';

  @override
  String get tabAccounts => 'Comptes';

  @override
  String get tabProfile => 'Profil';

  @override
  String get tabRelays => 'Relais';

  @override
  String get tabBlossom => 'Blossom';

  @override
  String get tabWallets => 'Portefeuilles';

  @override
  String get tabWidgets => 'Widgets';

  @override
  String get profileTooltip => 'Profil';

  @override
  String get loginDialogDefaultTitle => 'Se connecter';

  @override
  String get loginDialogAddAccountTitle => 'Ajouter un compte';

  @override
  String get closeTooltip => 'Fermer';

  @override
  String get accountsHeading => 'Comptes';

  @override
  String get accountsDescription =>
      'Gérez vos comptes connectés et ajoutez-en de nouveaux.';

  @override
  String get addAnotherAccount => 'Ajouter un autre compte';

  @override
  String get logIn => 'Se connecter';

  @override
  String get profileNoAccount => 'Aucun compte connecté.';

  @override
  String get profileAbout => 'À propos';

  @override
  String profileMetadataError(Object error) {
    return 'Erreur lors du chargement des métadonnées : $error';
  }

  @override
  String get relaysLoginRequired =>
      'Connectez-vous pour voir votre liste de relais.';

  @override
  String get relaysFetchButton => 'Récupérer la liste des relais';

  @override
  String get relayListHeading => 'Liste des relais';

  @override
  String relayConfiguredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count relais configurés',
      one: '$count relais configuré',
    );
    return '$_temp0';
  }

  @override
  String relayConnection(Object state) {
    return 'Connexion : $state';
  }

  @override
  String get relayRead => 'Lecture';

  @override
  String get relayWrite => 'Écriture';

  @override
  String get relayStateConnecting => 'Connexion';

  @override
  String get relayStateOnline => 'En ligne';

  @override
  String get relayStateOffline => 'Hors ligne';

  @override
  String get relayStateUnknown => 'Inconnu';

  @override
  String get widgetsPageTitle => 'Démo des widgets NDK Flutter';

  @override
  String get widgetsLoginHint =>
      'Connectez-vous depuis l’onglet Comptes pour voir des widgets personnalisés.';

  @override
  String get widgetsCurrentUser => 'Utilisateur actuel : ';

  @override
  String get widgetsSizeDefault => 'Par défaut';

  @override
  String get widgetsSizeLarger => 'Plus grand';

  @override
  String get widgetsSizeLarge => 'Grand';

  @override
  String get widgetsShowLoginWidget => 'Afficher le widget NLogin';

  @override
  String get widgetsLoginWidgetTitle => 'Widget NLogin';

  @override
  String widgetsRequiresLogin(Object widgetName) {
    return '$widgetName\\n(connexion requise)';
  }

  @override
  String get widgetsSectionNNameDescription =>
      'Affiche le nom de l’utilisateur depuis les métadonnées, avec repli sur un npub formaté.';

  @override
  String get widgetsSectionNPictureDescription =>
      'Affiche la photo de profil de l’utilisateur, avec repli sur les initiales.';

  @override
  String get widgetsSectionNBannerDescription =>
      'Affiche l’image de bannière de l’utilisateur, avec repli sur un conteneur coloré.';

  @override
  String get widgetsSectionNUserProfileDescription =>
      'Profil utilisateur complet avec bannière, photo, nom et NIP-05.';

  @override
  String get widgetsSectionNSwitchAccountDescription =>
      'Widget de gestion des comptes avec changement de compte et déconnexion.';

  @override
  String get widgetsSectionNLoginDescription =>
      'Widget de connexion avec plusieurs méthodes d’authentification (NIP-05, npub, nsec, bunker, etc.).';

  @override
  String get widgetsSectionGetColorDescription =>
      'Méthode statique qui génère des couleurs déterministes à partir de pubkeys.';

  @override
  String get blossomPageTitle => 'Opérations médias et fichiers Blossom';

  @override
  String get blossomImageDemoTitle => 'Démo image (getBlob)';

  @override
  String get blossomVideoDemoTitle => 'Démo vidéo (checkBlob)';

  @override
  String get blossomNoImageYet => 'Aucune image téléchargée pour le moment';

  @override
  String get blossomDownloadImage => 'Télécharger l’image';

  @override
  String get blossomClearImage => 'Effacer l’image';

  @override
  String blossomMimeType(Object value) {
    return 'Type MIME : $value';
  }

  @override
  String blossomFileSizeBytes(Object value) {
    return 'Taille : $value octets';
  }

  @override
  String get blossomNoVideoYet => 'Aucune vidéo chargée pour le moment';

  @override
  String get blossomLoadVideo => 'Charger la vidéo';

  @override
  String get blossomClearVideo => 'Effacer la vidéo';

  @override
  String blossomVideoUrl(Object value) {
    return 'URL de la vidéo : $value';
  }

  @override
  String get blossomUploadTitle => 'Téléverser un fichier depuis le disque';

  @override
  String get blossomUploadDescription =>
      'Démontre uploadFromFile() avec une progression en flux.';

  @override
  String blossomUploadingProgress(Object progress) {
    return 'Téléversement : $progress%';
  }

  @override
  String get blossomUploadSuccess => 'Téléversement réussi';

  @override
  String blossomSha256(Object value) {
    return 'SHA256 : $value';
  }

  @override
  String blossomUrl(Object value) {
    return 'URL : $value';
  }

  @override
  String get blossomNoUploadedFileYet =>
      'Aucun fichier téléversé pour le moment';

  @override
  String get blossomPickAndUploadFile => 'Choisir et téléverser un fichier';

  @override
  String get clear => 'Effacer';

  @override
  String get blossomDownloadTitle => 'Télécharger un fichier sur le disque';

  @override
  String get blossomDownloadDescription =>
      'Démontre downloadToFile() et enregistre directement sur le disque.';

  @override
  String get blossomNoDownloadedFileYet =>
      'Aucun fichier téléchargé pour le moment';

  @override
  String get blossomDownloadUploadedFile => 'Télécharger le fichier téléversé';

  @override
  String blossomSavedTo(Object value) {
    return 'Enregistré dans : $value';
  }

  @override
  String get blossomUploadFirstToEnableDownload =>
      'Téléversez d’abord un fichier pour activer le téléchargement.';

  @override
  String get blossomNoUploadedFileToDownload =>
      'Aucun fichier n’a encore été téléversé pour le téléchargement.';

  @override
  String get blossomDownloadedToBrowser => 'Téléchargé dans le navigateur';

  @override
  String get downloadSuccess => 'Téléchargement réussi';

  @override
  String errorLabel(Object error) {
    return 'Erreur : $error';
  }

  @override
  String get pendingRequestsLoginRequired =>
      'Veuillez vous connecter pour voir les demandes en attente.';

  @override
  String get pendingNoRequests => 'Aucune demande en attente';

  @override
  String get pendingUseButtons =>
      'Utilisez les boutons ci-dessus pour déclencher des demandes.';

  @override
  String get pendingRequestCancelled => 'Demande annulée';

  @override
  String get pendingRequestCancelFailed =>
      'Échec de l’annulation de la demande';

  @override
  String get pendingHeading => 'Demandes du signataire en attente';

  @override
  String get pendingDescription =>
      'Demandes en attente d’approbation par votre signataire.';

  @override
  String get pendingTriggerRequests => 'Déclencher des demandes';

  @override
  String get signEvent => 'Signer l’événement';

  @override
  String get encrypt => 'Chiffrer';

  @override
  String get decrypt => 'Déchiffrer';

  @override
  String pendingSignedResult(Object value) {
    return 'Signé. ID : $value';
  }

  @override
  String pendingSignFailed(Object error) {
    return 'Échec de la signature : $error';
  }

  @override
  String get pendingEncryptFirst =>
      'Chiffrez d’abord pour obtenir le texte chiffré.';

  @override
  String pendingEncryptedResult(Object value) {
    return 'Chiffré : $value';
  }

  @override
  String pendingEncryptFailed(Object error) {
    return 'Échec du chiffrement : $error';
  }

  @override
  String pendingDecryptedResult(Object value) {
    return 'Déchiffré : $value';
  }

  @override
  String pendingDecryptFailed(Object error) {
    return 'Échec du déchiffrement : $error';
  }

  @override
  String get pendingMethodSignEvent => 'Signer l’événement';

  @override
  String get pendingMethodGetPublicKey => 'Obtenir la clé publique';

  @override
  String get pendingMethodNip04Encrypt => 'Chiffrer NIP-04';

  @override
  String get pendingMethodNip04Decrypt => 'Déchiffrer NIP-04';

  @override
  String get pendingMethodNip44Encrypt => 'Chiffrer NIP-44';

  @override
  String get pendingMethodNip44Decrypt => 'Déchiffrer NIP-44';

  @override
  String get pendingMethodPing => 'Ping';

  @override
  String get pendingMethodConnect => 'Connecter';

  @override
  String pendingSecondsAgo(int count) {
    return 'il y a ${count}s';
  }

  @override
  String pendingMinutesAgo(int count) {
    return 'il y a ${count}m';
  }

  @override
  String pendingHoursAgo(int count) {
    return 'il y a ${count}h';
  }

  @override
  String pendingEventKind(Object value) {
    return 'Type d’événement : $value';
  }

  @override
  String pendingContent(Object value) {
    return 'Contenu : $value';
  }

  @override
  String pendingCounterparty(Object value) {
    return 'Contrepartie : $value...';
  }

  @override
  String pendingPlaintext(Object value) {
    return 'Texte en clair : $value';
  }

  @override
  String pendingCiphertext(Object value) {
    return 'Texte chiffré : $value...';
  }

  @override
  String pendingId(Object value) {
    return 'ID : $value';
  }

  @override
  String get cancel => 'Annuler';
}
