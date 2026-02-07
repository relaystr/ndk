import 'package:ndk/shared/helpers/url_normalizer.dart';

final RegExp relayUrlRegex = RegExp(
    r'^(wss?:\/\/)([a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?)*|[0-9]{1,3}(?:\.[0-9]{1,3}){3}):?([0-9]{1,5})?(\/[^\s]*)?$');

/// Matches extra slashes after protocol (e.g., wss:/// or wss:////)
final RegExp _extraSlashesRegex =
    RegExp(r'^(wss?:)\/{3,}', caseSensitive: false);

/// Normalizes a relay URL according to RFC 3986.
///
/// This function performs the following normalizations (RFC 3986 Section 6):
/// - Trims whitespace
/// - Fixes malformed protocols (e.g., wss:/// -> wss://)
/// - Case normalization: lowercases scheme and host (Section 6.2.2.1)
/// - Percent-encoding normalization (Section 6.2.2.2):
///   - Decodes percent-encoded unreserved characters
///   - Uppercases hex digits in percent-encodings
/// - Path segment normalization: removes dot segments (Section 6.2.2.3)
/// - Scheme-based normalization: removes default ports (Section 6.2.3)
/// - Removes trailing slashes
/// - Validates the URL format
///
/// Returns null if the URL is invalid.
String? cleanRelayUrl(String adr) {
  adr = adr.trim();

  if (adr.isEmpty) {
    return null;
  }

  // Remove extra slashes after protocol (e.g., wss:/// -> wss://)
  adr = adr.replaceFirstMapped(
      _extraSlashesRegex, (match) => '${match.group(1)}//');

  // Parse using Dart's Uri class for RFC 3986 compliance
  Uri uri;
  try {
    uri = Uri.parse(adr);
  } catch (_) {
    return null;
  }

  // Validate scheme (only ws and wss allowed)
  // RFC 3986 Section 6.2.2.1: Case normalization - scheme to lowercase
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'ws' && scheme != 'wss') {
    return null;
  }

  // Validate host
  // RFC 3986 Section 6.2.2.1: Case normalization - host to lowercase
  final host = uri.host.toLowerCase();
  if (host.isEmpty) {
    return null;
  }

  // Check for invalid host patterns (starting/ending with hyphen)
  if (host.startsWith('-') || host.endsWith('-')) {
    return null;
  }

  // RFC 3986 Section 6.2.3: Scheme-based normalization
  // Remove default ports (443 for wss, 80 for ws)
  int? port = uri.hasPort ? uri.port : null;
  if ((scheme == 'wss' && port == 443) || (scheme == 'ws' && port == 80)) {
    port = null;
  }

  // RFC 3986 Section 6.2.2.3: Path segment normalization
  // Remove dot segments using the algorithm from Section 5.2.4
  String path = removeDotSegments(uri.path);

  // Remove trailing slash from path
  if (path.length > 1 && path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }

  // Build normalized URL
  final buffer = StringBuffer('$scheme://$host');

  if (port != null) {
    buffer.write(':$port');
  }

  // Add normalized path
  if (path.isNotEmpty && path != '/') {
    buffer.write(normalizePercentEncoding(path));
  }

  // Preserve query string if present (with normalized percent-encoding)
  if (uri.hasQuery) {
    buffer.write('?${normalizePercentEncoding(uri.query)}');
  }

  // Preserve fragment if present (with normalized percent-encoding)
  if (uri.hasFragment) {
    buffer.write('#${normalizePercentEncoding(uri.fragment)}');
  }

  final normalizedUrl = buffer.toString();

  // Final validation with regex
  if (!normalizedUrl.contains(relayUrlRegex)) {
    return null;
  }

  return normalizedUrl;
}

List<String> cleanRelayUrls(List<String> urls) {
  return urls.map(cleanRelayUrl).whereType<String>().toList();
}
