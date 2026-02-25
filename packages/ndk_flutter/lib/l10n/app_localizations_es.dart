// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get createAccount => 'Crear tu cuenta';

  @override
  String get newHere => '¿Eres nuevo aquí?';

  @override
  String get nostrAddress => 'Dirección Nostr';

  @override
  String get publicKey => 'Clave pública';

  @override
  String get privateKey => 'Clave privada (inseguro)';

  @override
  String get browserExtension => 'Extensión del navegador';

  @override
  String get connect => 'Conectar';

  @override
  String get install => 'Instalar';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get nostrAddressHint => 'nombre@ejemplo.com';

  @override
  String get invalidAddress => 'Dirección inválida';

  @override
  String get unableToConnect => 'No se puede conectar';

  @override
  String get publicKeyHint => 'npub1...';

  @override
  String get privateKeyHint => 'nsec1...';

  @override
  String get newToNostr => '¿Nuevo en Nostr?';

  @override
  String get getStarted => 'Comenzar';

  @override
  String get bunker => 'Bunker';

  @override
  String get bunkerAuthentication => 'Autenticación Bunker';

  @override
  String tapToOpen(String url) {
    return 'Toca para abrir: $url';
  }

  @override
  String get showNostrConnectQrcode => 'Mostrar código QR de nostr connect';

  @override
  String get loginWithAmber => 'Iniciar sesión con Amber';

  @override
  String get nostrConnectUrl => 'URL de conexión Nostr';

  @override
  String get copy => 'Copiar';

  @override
  String get addAccount => 'Añadir cuenta';

  @override
  String get readOnly => 'Solo lectura';

  @override
  String get nsec => 'Nsec';

  @override
  String get extension => 'Extensión';

  @override
  String get userMetadata => 'Metadatos de usuario';

  @override
  String get shortTextNote => 'Nota corta';

  @override
  String get recommendRelay => 'Recomendar relay';

  @override
  String get follows => 'Seguidos';

  @override
  String get encryptedDirectMessages => 'Mensajes directos cifrados';

  @override
  String get eventDeletionRequest => 'Solicitud de eliminación';

  @override
  String get repost => 'Republicación';

  @override
  String get reaction => 'Reacción';

  @override
  String get badgeAward => 'Premio de insignia';

  @override
  String get chatMessage => 'Mensaje de chat';

  @override
  String get groupChatThreadedReply => 'Respuesta en hilo de grupo';

  @override
  String get thread => 'Hilo';

  @override
  String get groupThreadReply => 'Respuesta de hilo de grupo';

  @override
  String get seal => 'Sello';

  @override
  String get directMessage => 'Mensaje directo';

  @override
  String get fileMessage => 'Mensaje de archivo';

  @override
  String get genericRepost => 'Republicación genérica';

  @override
  String get reactionToWebsite => 'Reacción a sitio web';

  @override
  String get picture => 'Imagen';

  @override
  String get videoEvent => 'Evento de vídeo';

  @override
  String get shortFormPortraitVideoEvent => 'Vídeo vertical corto';

  @override
  String get internalReference => 'Referencia interna';

  @override
  String get externalReference => 'Referencia externa';

  @override
  String get hardcopyReference => 'Referencia impresa';

  @override
  String get promptReference => 'Referencia de prompt';

  @override
  String get channelCreation => 'Creación de canal';

  @override
  String get channelMetadata => 'Metadatos de canal';

  @override
  String get channelMessage => 'Mensaje de canal';

  @override
  String get channelHideMessage => 'Ocultar mensaje de canal';

  @override
  String get channelMuteUser => 'Silenciar usuario de canal';

  @override
  String get requestToVanish => 'Solicitud de desaparición';

  @override
  String get chessPgn => 'Ajedrez (PGN)';

  @override
  String get mlsKeyPackage => 'Paquete de claves MLS';

  @override
  String get mlsWelcome => 'Bienvenida MLS';

  @override
  String get mlsGroupEvent => 'Evento de grupo MLS';

  @override
  String get mergeRequests => 'Solicitudes de fusión';

  @override
  String get pollResponse => 'Respuesta de encuesta';

  @override
  String get marketplaceBid => 'Oferta de mercado';

  @override
  String get marketplaceBidConfirmation => 'Confirmación de oferta';

  @override
  String get openTimestamps => 'OpenTimestamps';

  @override
  String get giftWrap => 'Envoltorio de regalo';

  @override
  String get fileMetadata => 'Metadatos de archivo';

  @override
  String get poll => 'Encuesta';

  @override
  String get comment => 'Comentario';

  @override
  String get voiceMessage => 'Mensaje de voz';

  @override
  String get voiceMessageComment => 'Comentario de voz';

  @override
  String get liveChatMessage => 'Mensaje de chat en vivo';

  @override
  String get codeSnippet => 'Fragmento de código';

  @override
  String get gitPatch => 'Parche Git';

  @override
  String get gitPullRequest => 'Pull Request Git';

  @override
  String get gitStatusUpdate => 'Actualización de estado Git';

  @override
  String get gitIssue => 'Issue Git';

  @override
  String get gitIssueUpdate => 'Actualización de issue Git';

  @override
  String get status => 'Estado';

  @override
  String get statusUpdate => 'Actualización de estado';

  @override
  String get statusDelete => 'Eliminación de estado';

  @override
  String get statusReply => 'Respuesta de estado';

  @override
  String get problemTracker => 'Rastreador de problemas';

  @override
  String get reporting => 'Reporte';

  @override
  String get label => 'Etiqueta';

  @override
  String get relayReviews => 'Reseñas de relays';

  @override
  String get aiEmbeddings => 'Embeddings IA / Listas vectoriales';

  @override
  String get torrent => 'Torrent';

  @override
  String get torrentComment => 'Comentario de torrent';

  @override
  String get coinjoinPool => 'Pool Coinjoin';

  @override
  String get communityPostApproval => 'Aprobación de post comunitario';

  @override
  String get jobRequest => 'Solicitud de trabajo';

  @override
  String get jobResult => 'Resultado de trabajo';

  @override
  String get jobFeedback => 'Retroalimentación de trabajo';

  @override
  String get cashuWalletToken => 'Token de cartera Cashu';

  @override
  String get cashuWalletProofs => 'Pruebas de cartera Cashu';

  @override
  String get cashuWalletHistory => 'Historial de cartera Cashu';

  @override
  String get geocacheCreate => 'Crear geocaché';

  @override
  String get geocacheUpdate => 'Actualizar geocaché';

  @override
  String get groupControlEvent => 'Evento de control de grupo';

  @override
  String get zapGoal => 'Objetivo de Zap';

  @override
  String get nutzap => 'Nutzap';

  @override
  String get tidalLogin => 'Inicio de sesión Tidal';

  @override
  String get zapRequest => 'Solicitud de Zap';

  @override
  String get zap => 'Zap';

  @override
  String get highlights => 'Destacados';

  @override
  String get muteList => 'Lista de silenciados';

  @override
  String get pinList => 'Lista fijada';

  @override
  String get relayListMetadata => 'Metadatos de lista de relays';

  @override
  String get bookmarkList => 'Lista de marcadores';

  @override
  String get communitiesList => 'Lista de comunidades';

  @override
  String get publicChatsList => 'Lista de chats públicos';

  @override
  String get blockedRelaysList => 'Lista de relays bloqueados';

  @override
  String get searchRelaysList => 'Lista de relays de búsqueda';

  @override
  String get userGroups => 'Grupos de usuario';

  @override
  String get favoritesList => 'Lista de favoritos';

  @override
  String get privateEventsList => 'Lista de eventos privados';

  @override
  String get interestsList => 'Lista de intereses';

  @override
  String get mediaFollowsList => 'Lista de medios seguidos';

  @override
  String get peopleFollowsList => 'Lista de personas seguidas';

  @override
  String get userEmojiList => 'Lista de emojis de usuario';

  @override
  String get dmRelayList => 'Lista de relays de DM';

  @override
  String get keyPackageRelayList => 'Lista de relays KeyPackage';

  @override
  String get userServerList => 'Lista de servidores de usuario';

  @override
  String get fileStorageServerList => 'Lista de servidores de almacenamiento';

  @override
  String get relayMonitorAnnouncement => 'Anuncio de monitor de relay';

  @override
  String get roomPresence => 'Presencia en sala';

  @override
  String get proxyAnnouncement => 'Anuncio de proxy';

  @override
  String get transportMethodAnnouncement => 'Anuncio de método de transporte';

  @override
  String get walletInfo => 'Info de cartera';

  @override
  String get cashuWalletEvent => 'Evento de cartera Cashu';

  @override
  String get lightningPubRpc => 'RPC Lightning Pub';

  @override
  String get clientAuthentication => 'Autenticación de cliente';

  @override
  String get walletRequest => 'Solicitud de cartera';

  @override
  String get walletResponse => 'Respuesta de cartera';

  @override
  String get nostrConnectEvent => 'Nostr Connect';

  @override
  String get blobsStoredOnMediaservers => 'Blobs en servidores de medios';

  @override
  String get httpAuth => 'Autenticación HTTP';

  @override
  String get categorizedPeopleList => 'Lista de personas categorizada';

  @override
  String get categorizedBookmarkList => 'Lista de marcadores categorizada';

  @override
  String get categorizedRelayList => 'Lista de relays categorizada';

  @override
  String get bookmarkSets => 'Conjuntos de marcadores';

  @override
  String get curationSets => 'Conjuntos de curación';

  @override
  String get videoSets => 'Conjuntos de vídeos';

  @override
  String get kindMuteSets => 'Conjuntos de kinds silenciados';

  @override
  String get profileBadges => 'Insignias de perfil';

  @override
  String get badgeDefinition => 'Definición de insignia';

  @override
  String get interestSets => 'Conjuntos de intereses';

  @override
  String get createOrUpdateStall => 'Crear o actualizar puesto';

  @override
  String get createOrUpdateProduct => 'Crear o actualizar producto';

  @override
  String get marketplaceUiUx => 'Interfaz de mercado';

  @override
  String get productSoldAsAuction => 'Producto vendido en subasta';

  @override
  String get longFormContent => 'Contenido de formato largo';

  @override
  String get draftLongFormContent => 'Borrador de contenido largo';

  @override
  String get emojiSets => 'Conjuntos de emojis';

  @override
  String get curatedPublicationItem => 'Elemento de publicación curada';

  @override
  String get curatedPublicationDraft => 'Borrador de publicación curada';

  @override
  String get releaseArtifactSets => 'Conjuntos de artefactos de release';

  @override
  String get applicationSpecificData => 'Datos específicos de aplicación';

  @override
  String get relayDiscovery => 'Descubrimiento de relay';

  @override
  String get appCurationSets => 'Conjuntos de curación de apps';

  @override
  String get liveEvent => 'Evento en vivo';

  @override
  String get userStatus => 'Estado de usuario';

  @override
  String get slideSet => 'Conjunto de diapositivas';

  @override
  String get classifiedListing => 'Anuncio clasificado';

  @override
  String get draftClassifiedListing => 'Borrador de anuncio clasificado';

  @override
  String get repositoryAnnouncement => 'Anuncio de repositorio';

  @override
  String get repositoryStateAnnouncement => 'Anuncio de estado de repositorio';

  @override
  String get wikiArticle => 'Artículo wiki';

  @override
  String get redirects => 'Redirecciones';

  @override
  String get draftEvent => 'Borrador de evento';

  @override
  String get linkSet => 'Conjunto de enlaces';

  @override
  String get feed => 'Feed';

  @override
  String get dateBasedCalendarEvent => 'Evento de calendario por fecha';

  @override
  String get timeBasedCalendarEvent => 'Evento de calendario por hora';

  @override
  String get calendar => 'Calendario';

  @override
  String get calendarEventRsvp => 'RSVP de evento de calendario';

  @override
  String get handlerRecommendation => 'Recomendación de manejador';

  @override
  String get handlerInformation => 'Información de manejador';

  @override
  String get softwareApplication => 'Aplicación de software';

  @override
  String get videoView => 'Vista de vídeo';

  @override
  String get communityDefinition => 'Definición de comunidad';

  @override
  String get geocacheListing => 'Listado de geocaché';

  @override
  String get mintAnnouncement => 'Anuncio de mint';

  @override
  String get mintQuote => 'Cotización de mint';

  @override
  String get peerToPeerOrder => 'Orden peer-to-peer';

  @override
  String get groupMetadata => 'Metadatos de grupo';

  @override
  String get groupAdminMetadata => 'Metadatos de admin de grupo';

  @override
  String get groupMemberMetadata => 'Metadatos de miembro de grupo';

  @override
  String get groupAdminsList => 'Lista de admins de grupo';

  @override
  String get groupMembersList => 'Lista de miembros de grupo';

  @override
  String get groupRoles => 'Roles de grupo';

  @override
  String get groupPermissions => 'Permisos de grupo';

  @override
  String get groupChatMessage => 'Mensaje de chat de grupo';

  @override
  String get groupChatThread => 'Hilo de chat de grupo';

  @override
  String get groupPinned => 'Fijado de grupo';

  @override
  String get starterPacks => 'Packs de inicio';

  @override
  String get mediaStarterPacks => 'Packs de medios de inicio';

  @override
  String get webBookmarks => 'Marcadores web';

  @override
  String unknownEventKind(int kind) {
    return 'Tipo de evento $kind';
  }
}
