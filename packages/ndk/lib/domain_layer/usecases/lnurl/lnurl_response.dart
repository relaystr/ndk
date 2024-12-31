class LnurlResponse {
  String? callback;
  int? maxSendable;
  int? minSendable;
  String? metadata;
  int? commentAllowed;
  String? tag;
  bool? allowsNostr;
  String? nostrPubkey;

  LnurlResponse.fromJson(Map<String, dynamic> json) {
    callback = json['callback'];
    maxSendable = json['maxSendable'];
    minSendable = json['minSendable'];
    metadata = json['metadata'];
    commentAllowed = json['commentAllowed'];
    tag = json['tag'];
    allowsNostr = json['allowsNostr'];
    nostrPubkey = json['nostrPubkey'];
  }

  bool get doesAllowsNostr => allowsNostr != null && allowsNostr!;
}
