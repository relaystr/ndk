final RegExp relayUrlRegex = RegExp(
    r'^(wss?:\/\/)([a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?)*|[0-9]{1,3}(?:\.[0-9]{1,3}){3}):?([0-9]{1,5})?(\/[^\s]*)?$');

/// Unreserved characters per RFC 3986 section 2.3
/// ALPHA / DIGIT / "-" / "." / "_" / "~"
final RegExp _unreservedCharRegex = RegExp(r'^[A-Za-z0-9\-._~]$');

/// Matches valid hexadecimal digit pairs for percent-encoding
final RegExp _hexPairRegex = RegExp(r'^[0-9A-Fa-f]{2}$');

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
  String path = _removeDotSegments(uri.path);

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
    buffer.write(_normalizePercentEncoding(path));
  }

  // Preserve query string if present (with normalized percent-encoding)
  if (uri.hasQuery) {
    buffer.write('?${_normalizePercentEncoding(uri.query)}');
  }

  // Preserve fragment if present (with normalized percent-encoding)
  if (uri.hasFragment) {
    buffer.write('#${_normalizePercentEncoding(uri.fragment)}');
  }

  final normalizedUrl = buffer.toString();

  // Final validation with regex
  if (!normalizedUrl.contains(relayUrlRegex)) {
    return null;
  }

  return normalizedUrl;
}

/// RFC 3986 Section 5.2.4: Remove Dot Segments
///
/// This algorithm removes "." and ".." segments from a path.
String _removeDotSegments(String path) {
  if (path.isEmpty) return path;

  final input = path.split('/');
  final output = <String>[];

  for (final segment in input) {
    if (segment == '.') {
      // Skip "." segments
      continue;
    } else if (segment == '..') {
      // Go up one level for ".." segments
      if (output.isNotEmpty && output.last != '') {
        output.removeLast();
      }
    } else {
      output.add(segment);
    }
  }

  // Reconstruct path
  if (path.startsWith('/') && (output.isEmpty || output.first != '')) {
    return '/${output.join('/')}';
  }
  return output.join('/');
}

/// RFC 3986 Section 6.2.2.2: Percent-Encoding Normalization
///
/// - Decodes percent-encoded unreserved characters (A-Z, a-z, 0-9, -, ., _, ~)
/// - Uppercases hex digits in remaining percent-encodings
String _normalizePercentEncoding(String input) {
  final result = StringBuffer();
  int i = 0;

  while (i < input.length) {
    if (input[i] == '%' && i + 2 < input.length) {
      final hex = input.substring(i + 1, i + 3);
      // Validate hex digits
      if (_hexPairRegex.hasMatch(hex)) {
        final charCode = int.parse(hex, radix: 16);
        final char = String.fromCharCode(charCode);

        // Decode if it's an unreserved character
        if (_unreservedCharRegex.hasMatch(char)) {
          result.write(char);
        } else {
          // Keep percent-encoded but uppercase the hex digits
          result.write('%${hex.toUpperCase()}');
        }
        i += 3;
        continue;
      }
    }
    result.write(input[i]);
    i++;
  }

  return result.toString();
}

List<String> cleanRelayUrls(List<String> urls) {
  return urls.map(cleanRelayUrl).whereType<String>().toList();
}
