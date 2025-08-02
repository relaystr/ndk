import 'dart:math';

String generateRandomString({int length = 16}) {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random();
  return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
}

class BunkerUrlData {
  final String remotePubkey;
  final List<String> relays;
  final String? secret;
  
  BunkerUrlData({
    required this.remotePubkey,
    required this.relays,
    this.secret,
  });
}

// class NostrConnectUrlData {
//   final String pubkey;
//   final List<String> relays;
//   final String? secret;
//   final List<String>? perms;
//   final String? name;
//   final String? url;
//   final String? image;
  
//   NostrConnectUrlData({
//     required this.pubkey,
//     required this.relays,
//     this.secret,
//     this.perms,
//     this.name,
//     this.url,
//     this.image,
//   });
// }

BunkerUrlData parseBunkerUrl(String url) {
  final uri = Uri.parse(url);
  
  if (uri.scheme != 'bunker') {
    throw ArgumentError('Invalid bunker URL scheme: ${uri.scheme}');
  }
  
  final remotePubkey = uri.host;
  if (remotePubkey.isEmpty) {
    throw ArgumentError('Bunker URL must contain a public key');
  }
  
  final relays = uri.queryParametersAll['relay'] ?? [];
  if (relays.isEmpty) {
    throw ArgumentError('At least one relay is required in bunker URL');
  }
  
  final secret = uri.queryParameters['secret'];
  if (secret == null || secret.isEmpty) {
    throw ArgumentError('Secret parameter is required in bunker URL');
  }
  
  return BunkerUrlData(
    remotePubkey: remotePubkey,
    relays: relays,
    secret: secret,
  );
}

// NostrConnectUrlData parseNostrConnectUrl(String url) {
//   final uri = Uri.parse(url);
  
//   if (uri.scheme != 'nostrconnect') {
//     throw ArgumentError('Invalid nostrconnect URL scheme: ${uri.scheme}');
//   }
  
//   final pubkey = uri.host;
//   if (pubkey.isEmpty) {
//     throw ArgumentError('NostrConnect URL must contain a public key');
//   }
  
//   final relays = uri.queryParametersAll['relay'] ?? [];
//   if (relays.isEmpty) {
//     throw ArgumentError('At least one relay is required in nostrconnect URL');
//   }
  
//   final secret = uri.queryParameters['secret'];
//   final permsParam = uri.queryParameters['perms'];
//   final perms = permsParam?.split(',').where((p) => p.isNotEmpty).toList();
//   final name = uri.queryParameters['name'];
//   final urlParam = uri.queryParameters['url'];
//   final image = uri.queryParameters['image'];
  
//   return NostrConnectUrlData(
//     pubkey: pubkey,
//     relays: relays,
//     secret: secret,
//     perms: perms,
//     name: name,
//     url: urlParam,
//     image: image,
//   );
// }
