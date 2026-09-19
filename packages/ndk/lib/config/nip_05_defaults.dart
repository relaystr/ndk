// ignore_for_file: non_constant_identifier_names, constant_identifier_names

/// marks the duration in seconds for which a NIP05 is considered valid
final NIP_05_VALID_DURATION = Duration(hours: 24);

/// how long to wait for a nostr.json response before giving up
const NIP_05_REQUEST_TIMEOUT = Duration(seconds: 5);
