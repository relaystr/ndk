class ConnectionSettings {
  String privateKey;
  String remotePubkey;
  List<String> relays;

  ConnectionSettings({
    required this.privateKey,
    required this.remotePubkey,
    required this.relays,
  });

  Map<String, dynamic> toJson() => {
    'privateKey': privateKey,
    'remotePubkey': remotePubkey,
    'relays': relays,
  };

  factory ConnectionSettings.fromJson(Map<String, dynamic> json) {
    return ConnectionSettings(
      privateKey: json['privateKey'] as String,
      remotePubkey: json['remotePubkey'] as String,
      relays: List<String>.from(json['relays'] as List),
    );
  }
}
