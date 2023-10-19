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

  Filter(
      {this.ids,
      this.authors,
      this.kinds,
      this.eTags,
      this.pTags,
      this.tTags,
      this.since,
      this.until,
      this.limit});

  Filter.fromJson(Map<String, dynamic> json) {
    ids = json['ids'] == null ? null : List<String>.from(json['ids']);
    authors =
        json['authors'] == null ? null : List<String>.from(json['authors']);
    kinds = json['kinds'] == null ? null : List<int>.from(json['kinds']);
    eTags = json['#e'] == null ? null : List<String>.from(json['#e']);
    pTags = json['#p'] == null ? null : List<String>.from(json['#p']);
    tTags = json['#t'] == null ? null : List<String>.from(json['#t']);
    since = json['since'];
    until = json['until'];
    limit = json['limit'];
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
    return Filter.fromJson(map);
  }
  Filter cloneWithPTags(List<String> pTags) {
    Map<String, dynamic> map = toMap();
    map['#p'] = pTags;
    return Filter.fromJson(map);
  }
}
