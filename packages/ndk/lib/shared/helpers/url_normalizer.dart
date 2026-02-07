/// RFC 3986 compliant URL normalization utilities.
///
/// This library provides functions for normalizing URLs according to RFC 3986,
/// including case normalization, percent-encoding normalization, and path
/// segment normalization.
library;

/// Unreserved characters per RFC 3986 section 2.3
/// ALPHA / DIGIT / "-" / "." / "_" / "~"
final RegExp _unreservedCharRegex = RegExp(r'^[A-Za-z0-9\-._~]$');

/// Matches valid hexadecimal digit pairs for percent-encoding
final RegExp _hexPairRegex = RegExp(r'^[0-9A-Fa-f]{2}$');

/// RFC 3986 Section 5.2.4: Remove Dot Segments
///
/// This algorithm removes "." and ".." segments from a path.
String removeDotSegments(String path) {
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
String normalizePercentEncoding(String input) {
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
