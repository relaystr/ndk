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
}
