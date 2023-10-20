class Filter {
  List<String>? ids;
  List<String>? authors;
  List<int>? kinds;

  List<String>? eTags; // event tags
  List<String>? pTags; // pubKey tags
  List<String>? tTags; // # tags

  int? since;
  int? until;
  int? limit;

  Filter({this.ids, this.authors, this.kinds, this.eTags, this.pTags, this.tTags, this.since, this.until, this.limit});

  Filter.fromMap(Map<String, dynamic> map) {
    ids = map['ids'] == null ? null : List<String>.from(map['ids']);
    authors = map['authors'] == null ? null : List<String>.from(map['authors']);
    kinds = map['kinds'] == null ? null : List<int>.from(map['kinds']);
    eTags = map['#e'] == null ? null : List<String>.from(map['#e']);
    pTags = map['#p'] == null ? null : List<String>.from(map['#p']);
    tTags = map['#t'] == null ? null : List<String>.from(map['#t']);
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
      "since": since,
      "until": until,
      "limit": limit,
    };
    // remove null values
    body.removeWhere((key, value) => value == null);

    return body;
  }

  @override
  String toString() {
    return toMap().toString();
  }

  Filter cloneWithAuthors(List<String> authors) {
    Map<String, dynamic> map = toMap();
    map['authors'] = authors;
    return Filter.fromMap(map);
  }

  Filter cloneWithPTags(List<String> pTags) {
    Map<String, dynamic> map = toMap();
    map['#p'] = pTags;
    return Filter.fromMap(map);
  }
}
