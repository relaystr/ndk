import 'package:nip46_event_signer/src/models/connection_settings.dart';

sealed class BunkerEvent {
  Map<String, dynamic> toJson();
}

class AuthRequired extends BunkerEvent {
  final String url;
  AuthRequired(this.url);
  
  @override
  Map<String, dynamic> toJson() => {
    'type': 'AuthRequired',
    'url': url,
  };
}

class Connected extends BunkerEvent {
  final ConnectionSettings settings;
  Connected(this.settings);
  
  @override
  Map<String, dynamic> toJson() => {
    'type': 'Connected',
    'settings': settings.toJson(),
  };
}