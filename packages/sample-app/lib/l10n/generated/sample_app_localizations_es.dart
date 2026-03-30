// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'sample_app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class SampleAppLocalizationsEs extends SampleAppLocalizations {
  SampleAppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Demo de Nostr Developer Kit';

  @override
  String get appBarTitle => 'Demo de NDK';

  @override
  String get tabAccounts => 'Cuentas';

  @override
  String get tabProfile => 'Perfil';

  @override
  String get tabRelays => 'Relés';

  @override
  String get tabBlossom => 'Blossom';

  @override
  String get tabWallets => 'Billeteras';

  @override
  String get tabWidgets => 'Widgets';

  @override
  String get profileTooltip => 'Perfil';

  @override
  String get loginDialogDefaultTitle => 'Iniciar sesión';

  @override
  String get loginDialogAddAccountTitle => 'Agregar cuenta';

  @override
  String get closeTooltip => 'Cerrar';

  @override
  String get accountsHeading => 'Cuentas';

  @override
  String get accountsDescription =>
      'Administra tus cuentas conectadas y agrega nuevas.';

  @override
  String get addAnotherAccount => 'Agregar otra cuenta';

  @override
  String get logIn => 'Iniciar sesión';

  @override
  String get profileNoAccount => 'No hay ninguna cuenta conectada.';

  @override
  String get profileAbout => 'Acerca de';

  @override
  String profileMetadataError(Object error) {
    return 'Error al obtener los metadatos: $error';
  }

  @override
  String get relaysLoginRequired => 'Inicia sesión para ver tu lista de relés.';

  @override
  String get relaysFetchButton => 'Obtener lista de relés';

  @override
  String get relayListHeading => 'Lista de relés';

  @override
  String relayConfiguredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count relés configurados',
      one: '$count relé configurado',
    );
    return '$_temp0';
  }

  @override
  String relayConnection(Object state) {
    return 'Conexión: $state';
  }

  @override
  String get relayRead => 'Lectura';

  @override
  String get relayWrite => 'Escritura';

  @override
  String get relayStateConnecting => 'Conectando';

  @override
  String get relayStateOnline => 'En línea';

  @override
  String get relayStateOffline => 'Sin conexión';

  @override
  String get relayStateUnknown => 'Desconocido';

  @override
  String get widgetsPageTitle => 'Demo de widgets de NDK Flutter';

  @override
  String get widgetsLoginHint =>
      'Inicia sesión desde la pestaña Cuentas para ver widgets personalizados.';

  @override
  String get widgetsCurrentUser => 'Usuario actual: ';

  @override
  String get widgetsSizeDefault => 'Predeterminado';

  @override
  String get widgetsSizeLarger => 'Más grande';

  @override
  String get widgetsSizeLarge => 'Grande';

  @override
  String get widgetsShowLoginWidget => 'Mostrar widget NLogin';

  @override
  String get widgetsLoginWidgetTitle => 'Widget NLogin';

  @override
  String widgetsRequiresLogin(Object widgetName) {
    return '$widgetName\\n(requiere inicio de sesión)';
  }

  @override
  String get widgetsSectionNNameDescription =>
      'Muestra el nombre del usuario desde los metadatos y usa un npub formateado como alternativa.';

  @override
  String get widgetsSectionNPictureDescription =>
      'Muestra la foto de perfil del usuario y usa iniciales como alternativa.';

  @override
  String get widgetsSectionNBannerDescription =>
      'Muestra la imagen de banner del usuario y usa un contenedor con color como alternativa.';

  @override
  String get widgetsSectionNUserProfileDescription =>
      'Perfil completo con banner, foto, nombre y NIP-05.';

  @override
  String get widgetsSectionNSwitchAccountDescription =>
      'Widget de administración de cuentas con cambio y cierre de sesión.';

  @override
  String get widgetsSectionNLoginDescription =>
      'Widget de inicio de sesión con varios métodos de autenticación (NIP-05, npub, nsec, bunker, etc.).';

  @override
  String get widgetsSectionGetColorDescription =>
      'Método estático que genera colores deterministas a partir de pubkeys.';

  @override
  String get blossomPageTitle => 'Operaciones de medios y archivos de Blossom';

  @override
  String get blossomImageDemoTitle => 'Demo de imagen (getBlob)';

  @override
  String get blossomVideoDemoTitle => 'Demo de video (checkBlob)';

  @override
  String get blossomNoImageYet => 'Todavía no se ha descargado ninguna imagen';

  @override
  String get blossomDownloadImage => 'Descargar imagen';

  @override
  String get blossomClearImage => 'Borrar imagen';

  @override
  String blossomMimeType(Object value) {
    return 'Tipo MIME: $value';
  }

  @override
  String blossomFileSizeBytes(Object value) {
    return 'Tamaño: $value bytes';
  }

  @override
  String get blossomNoVideoYet => 'Todavía no se ha cargado ningún video';

  @override
  String get blossomLoadVideo => 'Cargar video';

  @override
  String get blossomClearVideo => 'Borrar video';

  @override
  String blossomVideoUrl(Object value) {
    return 'URL del video: $value';
  }

  @override
  String get blossomUploadTitle => 'Subir archivo desde disco';

  @override
  String get blossomUploadDescription =>
      'Demuestra uploadFromFile() con progreso en tiempo real.';

  @override
  String blossomUploadingProgress(Object progress) {
    return 'Subiendo: $progress%';
  }

  @override
  String get blossomUploadSuccess => 'Carga correcta';

  @override
  String blossomSha256(Object value) {
    return 'SHA256: $value';
  }

  @override
  String blossomUrl(Object value) {
    return 'URL: $value';
  }

  @override
  String get blossomNoUploadedFileYet =>
      'Todavía no se ha subido ningún archivo';

  @override
  String get blossomPickAndUploadFile => 'Elegir y subir archivo';

  @override
  String get clear => 'Borrar';

  @override
  String get blossomDownloadTitle => 'Descargar archivo al disco';

  @override
  String get blossomDownloadDescription =>
      'Demuestra downloadToFile() y guarda directamente en el disco.';

  @override
  String get blossomNoDownloadedFileYet =>
      'Todavía no se ha descargado ningún archivo';

  @override
  String get blossomDownloadUploadedFile => 'Descargar archivo subido';

  @override
  String blossomSavedTo(Object value) {
    return 'Guardado en: $value';
  }

  @override
  String get blossomUploadFirstToEnableDownload =>
      'Sube primero un archivo para habilitar la descarga.';

  @override
  String get blossomNoUploadedFileToDownload =>
      'Todavía no hay ningún archivo subido para descargar.';

  @override
  String get blossomDownloadedToBrowser => 'Descargado al navegador';

  @override
  String get downloadSuccess => 'Descarga correcta';

  @override
  String errorLabel(Object error) {
    return 'Error: $error';
  }

  @override
  String get pendingRequestsLoginRequired =>
      'Inicia sesión para ver las solicitudes pendientes.';

  @override
  String get pendingNoRequests => 'No hay solicitudes pendientes';

  @override
  String get pendingUseButtons =>
      'Usa los botones de arriba para activar solicitudes.';

  @override
  String get pendingRequestCancelled => 'Solicitud cancelada';

  @override
  String get pendingRequestCancelFailed => 'No se pudo cancelar la solicitud';

  @override
  String get pendingHeading => 'Solicitudes pendientes del firmante';

  @override
  String get pendingDescription =>
      'Solicitudes en espera de aprobación por tu firmante.';

  @override
  String get pendingTriggerRequests => 'Activar solicitudes';

  @override
  String get signEvent => 'Firmar evento';

  @override
  String get encrypt => 'Cifrar';

  @override
  String get decrypt => 'Descifrar';

  @override
  String pendingSignedResult(Object value) {
    return 'Firmado. ID: $value';
  }

  @override
  String pendingSignFailed(Object error) {
    return 'Error al firmar: $error';
  }

  @override
  String get pendingEncryptFirst =>
      'Cifra primero para obtener el texto cifrado.';

  @override
  String pendingEncryptedResult(Object value) {
    return 'Cifrado: $value';
  }

  @override
  String pendingEncryptFailed(Object error) {
    return 'Error al cifrar: $error';
  }

  @override
  String pendingDecryptedResult(Object value) {
    return 'Descifrado: $value';
  }

  @override
  String pendingDecryptFailed(Object error) {
    return 'Error al descifrar: $error';
  }

  @override
  String get pendingMethodSignEvent => 'Firmar evento';

  @override
  String get pendingMethodGetPublicKey => 'Obtener clave pública';

  @override
  String get pendingMethodNip04Encrypt => 'Cifrar NIP-04';

  @override
  String get pendingMethodNip04Decrypt => 'Descifrar NIP-04';

  @override
  String get pendingMethodNip44Encrypt => 'Cifrar NIP-44';

  @override
  String get pendingMethodNip44Decrypt => 'Descifrar NIP-44';

  @override
  String get pendingMethodPing => 'Ping';

  @override
  String get pendingMethodConnect => 'Conectar';

  @override
  String pendingSecondsAgo(int count) {
    return 'hace ${count}s';
  }

  @override
  String pendingMinutesAgo(int count) {
    return 'hace ${count}m';
  }

  @override
  String pendingHoursAgo(int count) {
    return 'hace ${count}h';
  }

  @override
  String pendingEventKind(Object value) {
    return 'Tipo de evento: $value';
  }

  @override
  String pendingContent(Object value) {
    return 'Contenido: $value';
  }

  @override
  String pendingCounterparty(Object value) {
    return 'Contraparte: $value...';
  }

  @override
  String pendingPlaintext(Object value) {
    return 'Texto plano: $value';
  }

  @override
  String pendingCiphertext(Object value) {
    return 'Texto cifrado: $value...';
  }

  @override
  String pendingId(Object value) {
    return 'ID: $value';
  }

  @override
  String get cancel => 'Cancelar';
}
