class Nip46ClientMetadata {
  final String? name;
  final String? url;
  final String? image;
  final List<String>? perms;

  const Nip46ClientMetadata({this.name, this.url, this.image, this.perms});

  /// NIP-46 `optional_client_metadata`, keys shared with `nostrconnect://`
  Map<String, String> get displayInfo => {
        'name': ?name,
        'url': ?url,
        'image': ?image,
      };
}
