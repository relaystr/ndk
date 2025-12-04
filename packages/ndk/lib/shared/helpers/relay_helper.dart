// ignore: public_member_api_docs, non_constant_identifier_names
final RegExp RELAY_URL_REGEX = RegExp(
    r'^(wss?:\/\/)([a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?)*|[0-9]{1,3}(?:\.[0-9]{1,3}){3}):?([0-9]{1,5})?(\/[^\s]*)?$');

String? cleanRelayUrl(String adr) {
  adr = adr.trim();
  if (adr.endsWith("/")) {
    adr = adr.substring(0, adr.length - 1);
  }
  if (adr.contains("%")) {
    adr = Uri.decodeComponent(adr);
  }
  // Remove extra slashes after protocol (e.g., wss:/// -> wss://)
  adr = adr.replaceFirstMapped(
      RegExp(r'^(wss?:)\/{3,}'), (match) => '${match.group(1)}//');
  if (!adr.contains(RELAY_URL_REGEX)) {
    return null;
  }
  return adr;
}

List<String> cleanRelayUrls(List<String> urls) {
  final List<String> cleanUrls = [];
  for (var url in urls) {
    String? cleanUrl = cleanRelayUrl(url);
    if (cleanUrl == null) {
      continue;
    }
    cleanUrls.add(cleanUrl);
  }
  return cleanUrls;
}
