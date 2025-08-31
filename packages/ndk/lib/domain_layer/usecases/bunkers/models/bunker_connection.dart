class BunkerConnection {
  String privateKey;
  String remotePubkey;
  List<String> relays;

  BunkerConnection({
    required this.privateKey,
    required this.remotePubkey,
    required this.relays,
  });

  Map<String, dynamic> toJson() => {
        'privateKey': privateKey,
        'remotePubkey': remotePubkey,
        'relays': relays,
      };

  factory BunkerConnection.fromJson(Map<String, dynamic> json) {
    return BunkerConnection(
      privateKey: json['privateKey'] as String,
      remotePubkey: json['remotePubkey'] as String,
      relays: List<String>.from(json['relays'] as List),
    );
  }
}
