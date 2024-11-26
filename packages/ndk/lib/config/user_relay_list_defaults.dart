// ignore_for_file: constant_identifier_names

/// if cached user relay list is older that now minus this duration that we should go refresh it,
/// otherwise we risk adding/removing relays to a list that is out of date and thus loosing relays other client has added/removed since.
const Duration REFRESH_USER_RELAY_DURATION = Duration(minutes: 10);
