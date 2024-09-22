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
  List<String>? eTags;

  /// List of pubkey tags to filter by.
  List<String>? pTags;

  /// List of hashtag tags to filter by.
  List<String>? tTags;

  /// List of replaceable event tags to filter by.
  List<String>? aTags;

  List<String>? dTags; // d tags

  /// Unix timestamp to filter events created after this time.
  int? since;

  /// Unix timestamp to filter events created before this time.
  int? until;

  /// Maximum number of events to return.
  int? limit;

  Filter({
    this.ids,
    this.authors,
    this.kinds,
    this.eTags,
    this.pTags,
    this.tTags,
    this.aTags,
    this.dTags,
    this.since,
    this.until,
    this.limit,
  });

  Filter.fromMap(Map<String, dynamic> map) {
    ids = map['ids'] == null ? null : List<String>.from(map['ids']);
    authors = map['authors'] == null ? null : List<String>.from(map['authors']);
    kinds = map['kinds'] == null ? null : List<int>.from(map['kinds']);
    eTags = map['#e'] == null ? null : List<String>.from(map['#e']);
    pTags = map['#p'] == null ? null : List<String>.from(map['#p']);
    tTags = map['#t'] == null ? null : List<String>.from(map['#t']);
    aTags = map['#a'] == null ? null : List<String>.from(map['#a']);
    dTags = map['#d'] == null ? null : List<String>.from(map['#d']);
    search = map['search'];
    since = map['since'];
    until = map['until'];
    limit = map['limit'];
  }

  Map<String, dynamic> toMap() {
    var body = {
      "ids": ids,
      "authors": authors,
      "kinds": kinds,
      "#e": eTags,
      "#p": pTags,
      "#t": tTags,
      "#d": dTags,
      "#a": aTags,
      "since": since,
      "until": until,
      "search": search,
      "limit": limit,
    };
    // remove null values
    body.removeWhere((key, value) => value == null);

    return body;
  }

  Map<String, dynamic> toJson() => toMap();

  factory Filter.fromJson(Map<String, dynamic> json) => Filter.fromMap(json);

  @override
  String toString() {
    return toMap().toString();
  }

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
  Filter.mergeAuthors(Filter filter1, Filter filter2) {
    Map<String, dynamic> map = filter1.toMap();
    if (filter1.authors == null || filter2.authors == null) {
      throw Exception("Filter does not contain authors");
    }
    map['authors'] = [...filter1.authors!, ...filter2.authors!];
    // remove duplicates
    map['authors'] = map['authors'].toSet().toList();
    Filter.fromMap(map);
  }
}
