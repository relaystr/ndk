/// Represents a filter for querying Nostr events.
///
/// This class encapsulates various criteria that can be used to filter
/// Nostr events when querying relays or local caches.
/// https://github.com/nostr-protocol/nips/blob/master/01.md#communication-between-clients-and-relays
class Filter {
  /// List of event IDs to filter by.
  List<String>? ids;

  /// List of author public keys to filter by.
  List<String>? authors;

  /// List of event kinds to filter by.
  List<int>? kinds;

  /// Text to search for in event content.
  String? search;

  /// List of event tags to filter by.
  List<String>? get eTags => getTag("e");

  /// List of pubkey tags to filter by.
  List<String>? get pTags => getTag("p");

  /// List of hashtag tags to filter by.
  List<String>? get tTags => getTag("t");

  /// List of replaceable event tags to filter by.
  List<String>? get aTags => getTag("a");

  /// ...
  List<String>? get dTags => getTag("d");

  /// other tags
  List<String>? get mTags => getTag("m");

  /// Unix timestamp to filter events created after this time.
  int? since;

  /// Unix timestamp to filter events created before this time.
  int? until;

  /// Maximum number of events to return.
  int? limit;

  Map<String, List<String>>? _tags;

  /// Tag filters, keyed by the bare tag name ('p', 'e', 'd', ...), value is a
  /// list of tag values.
  ///
  /// The NIP-01 '#' prefix is a wire-format detail only: [toMap] and [toJson]
  /// add it when a filter is serialized for a relay, everything else, cache
  /// reads above all, sees bare keys.
  Map<String, List<String>>? get tags => _tags;

  set tags(Map<String, List<String>>? value) {
    _tags = value == null
        ? null
        : {
            for (final entry in value.entries)
              _bareTagKey(entry.key): entry.value,
          };
  }

  Filter({
    this.ids,
    this.authors,
    this.kinds,
    this.search,
    Map<String, List<String>>? tags,
    List<String>? eTags,
    List<String>? pTags,
    List<String>? tTags,
    List<String>? aTags,
    List<String>? dTags,
    List<String>? mTags,
    this.since,
    this.until,
    this.limit,
  }) {
    this.tags = tags;
    if (eTags != null) setTag("e", eTags);
    if (pTags != null) setTag("p", pTags);
    if (tTags != null) setTag("t", tTags);
    if (aTags != null) setTag("a", aTags);
    if (dTags != null) setTag("d", dTags);
    if (mTags != null) setTag("m", mTags);
  }

  Filter.fromMap(Map<String, dynamic> map) {
    ids = map['ids'] == null ? null : List<String>.from(map['ids']);
    authors = map['authors'] == null ? null : List<String>.from(map['authors']);
    kinds = map['kinds'] == null ? null : List<int>.from(map['kinds']);
    search = map['search'];
    since = map['since'];
    until = map['until'];
    limit = map['limit'];

    // Handle arbitrary tags: relays serialize them '#'-prefixed, we store
    // them bare.
    final tagFilters = <String, List<String>>{};
    map.forEach((key, value) {
      if (key.startsWith('#') && key.length == 2) {
        tagFilters[key.substring(1)] = List<String>.from(value);
      }
    });
    tags = tagFilters.isEmpty ? null : tagFilters;
  }

  Map<String, dynamic> toMap() {
    var body = {
      "ids": ids,
      "authors": authors != null && authors!.isNotEmpty ? authors : null,
      "kinds": kinds,
      "since": since,
      "until": until,
      "search": search,
      "limit": limit,
    };

    // Add arbitrary tags to the map, NIP-01 wants them '#'-prefixed
    if (tags != null) {
      body.addAll({
        for (final entry in tags!.entries) _wireTagKey(entry.key): entry.value,
      });
    }

    // remove null values
    body.removeWhere((key, value) => value == null);

    return body;
  }

  Map<String, dynamic> toJson() => toMap();

  factory Filter.fromJson(Map<String, dynamic> json) => Filter.fromMap(json);

  // coverage:ignore-start
  @override
  String toString() {
    return toMap().toString();
  }
  // coverage:ignore-end

  /// Creates a new [Filter] with updated authors.
  ///
  /// [authors] The new list of authors to use in the filter.
  Filter cloneWithAuthors(List<String> authors) {
    Map<String, dynamic> map = toMap();
    map['authors'] = authors;
    return Filter.fromMap(map);
  }

  /// Creates a new [Filter] with updated pubkey tags.
  ///
  /// [pTags] The new list of pubkey tags to use in the filter.
  Filter cloneWithPTags(List<String> pTags) {
    Map<String, dynamic> map = toMap();
    map['#p'] = pTags;
    return Filter.fromMap(map);
  }

  /// Creates a new [Filter] by merging authors from two filters.
  ///
  /// [filter1] The first filter to merge.
  /// [filter2] The second filter to merge.
  ///
  /// Throws an exception if either filter doesn't contain authors.
  /// [filter1] is used as a basis
  static Filter mergeAuthors(Filter filter1, Filter filter2) {
    Map<String, dynamic> map = filter1.toMap();
    if (filter1.authors == null || filter2.authors == null) {
      throw Exception("Filter does not contain authors");
    }
    map['authors'] = [...filter1.authors!, ...filter2.authors!];
    // remove duplicates
    map['authors'] = map['authors'].toSet().toList();
    return Filter.fromMap(map);
  }

  Filter clone() {
    return Filter(
      ids: ids != null ? List<String>.from(ids!) : null,
      authors: authors != null && authors!.isNotEmpty
          ? List<String>.from(authors!)
          : null,
      kinds: kinds != null ? List<int>.from(kinds!) : null,
      search: search,
      since: since,
      until: until,
      limit: limit,
      tags: tags != null ? Map<String, List<String>>.from(tags!) : null,
    );
  }

  // set an arbitrary tag
  void setTag(String tagName, List<String> values) {
    if (tagName.length > 2) return;
    tags ??= {};
    tags![_bareTagKey(tagName)] = values;
  }

  // get an arbitrary tag
  List<String>? getTag(String tagName) {
    if (tags == null || tagName.length > 2) return null;
    return tags![_bareTagKey(tagName)];
  }

  /// Tag key without the NIP-01 '#', the form [tags] stores.
  static String _bareTagKey(String tagName) =>
      tagName.startsWith('#') ? tagName.substring(1) : tagName;

  /// Tag key as NIP-01 serializes it, '#' prefixed.
  static String _wireTagKey(String tagName) =>
      tagName.startsWith('#') ? tagName : '#$tagName';
}
