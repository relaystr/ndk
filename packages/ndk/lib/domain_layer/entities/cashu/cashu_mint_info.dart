class CashuMintInfo {
  final String? name;
  final String? pubkey;
  final String? version;
  final String? description;
  final String? descriptionLong;
  final List<CashuMintContact> contact;
  final String? motd;
  final String? iconUrl;
  final List<String> urls;

  /// unix timestamp in seconds on the server
  final int? time;
  final String? tosUrl;
  final Map<int, CashuMintNut> nuts;

  CashuMintInfo({
    this.name,
    this.version,
    this.description,
    required this.nuts,
    this.pubkey,
    this.descriptionLong,
    this.contact = const [],
    this.motd,
    this.iconUrl,
    this.urls = const [],
    this.time,
    this.tosUrl,
  });

  bool isMintUrl(String url) {
    return urls.any((u) => u == url);
  }

  Set<String> get supportedUnits {
    final units = <String>{};
    for (final nut in nuts.values) {
      final all = <CashuMintPaymentMethod>[
        if (nut.methods != null) ...nut.methods!,
        if (nut.supportedMethods != null) ...nut.supportedMethods!,
      ];
      for (final pm in all) {
        final u = pm.unit?.trim();
        if (u != null && u.isNotEmpty) {
          units.add(u.toLowerCase());
        }
      }
    }
    return units;
  }

  /// [mintUrl] is used when json['urls'] is not present \
  factory CashuMintInfo.fromJson(
    Map<String, dynamic> json, {
    String? mintUrl,
  }) {
    final nutsJson = (json['nuts'] as Map?) ?? {};
    final parsedNuts = <int, CashuMintNut>{};
    nutsJson.forEach((k, v) {
      final key = int.tryParse(k.toString());
      if (key != null) {
        parsedNuts[key] =
            CashuMintNut.fromJson((v ?? {}) as Map<String, dynamic>);
      }
    });

    return CashuMintInfo(
      name: json['name'] as String?,
      pubkey: json['pubkey'] as String?,
      version: json['version'] as String?,
      description: json['description'] as String?,
      descriptionLong: json['description_long'] as String?,
      contact: ((json['contact'] as List?) ?? const [])
          .map((e) => CashuMintContact.fromJson(e as Map<String, dynamic>))
          .toList(),
      motd: json['motd'] as String?,
      iconUrl: json['icon_url'] as String?,
      urls: ((json['urls'] as List?) ?? [mintUrl])
          .map((e) => e.toString())
          .toList(),
      time: (json['time'] is num) ? (json['time'] as num).toInt() : null,
      tosUrl: json['tos_url'] as String?,
      nuts: parsedNuts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (pubkey != null) 'pubkey': pubkey,
      if (version != null) 'version': version,
      if (description != null) 'description': description,
      if (descriptionLong != null) 'description_long': descriptionLong,
      if (contact.isNotEmpty)
        'contact': contact.map((c) => c.toJson()).toList(),
      if (motd != null) 'motd': motd,
      if (iconUrl != null) 'icon_url': iconUrl,
      if (urls.isNotEmpty) 'urls': urls,
      if (time != null) 'time': time,
      if (tosUrl != null) 'tos_url': tosUrl,
      'nuts': nuts.map((k, v) => MapEntry(k.toString(), v.toJson())),
    };
  }
}

class CashuMintContact {
  final String method;
  final String info;

  CashuMintContact({
    required this.method,
    required this.info,
  });

  factory CashuMintContact.fromJson(Map<String, dynamic> json) {
    return CashuMintContact(
      method: (json['method'] ?? '') as String,
      info: (json['info'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'method': method,
        'info': info,
      };
}

class CashuMintNut {
  final List<CashuMintPaymentMethod>? methods;
  final bool? disabled;
  final bool? supported;

  // nut-17
  final List<CashuMintPaymentMethod>? supportedMethods;

  // nut-19
  final int? ttl;
  final List<CashuMintCachedEndpoint>? cachedEndpoints;

  CashuMintNut({
    this.methods,
    this.disabled,
    this.supported,
    this.supportedMethods,
    this.ttl,
    this.cachedEndpoints,
  });

  factory CashuMintNut.fromJson(Map<String, dynamic> json) {
    final methodsJson = json['methods'];
    List<CashuMintPaymentMethod>? parsedMethods;
    if (methodsJson is List) {
      parsedMethods = methodsJson
          .map(
              (e) => CashuMintPaymentMethod.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    bool? supportedBool;
    List<CashuMintPaymentMethod>? supportedList;
    final supportedJson = json['supported'];
    if (supportedJson is bool) {
      supportedBool = supportedJson;
    } else if (supportedJson is List) {
      supportedList = supportedJson
          .map(
              (e) => CashuMintPaymentMethod.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    List<CashuMintCachedEndpoint>? endpoints;
    final ce = json['cached_endpoints'];
    if (ce is List) {
      endpoints = ce
          .map((e) =>
              CashuMintCachedEndpoint.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return CashuMintNut(
      methods: parsedMethods,
      disabled: json['disabled'] is bool ? json['disabled'] as bool : null,
      supported: supportedBool,
      supportedMethods: supportedList,
      ttl: (json['ttl'] is num) ? (json['ttl'] as num).toInt() : null,
      cachedEndpoints: endpoints,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (methods != null) 'methods': methods!.map((m) => m.toJson()).toList(),
      if (disabled != null) 'disabled': disabled,
      if (supported != null) 'supported': supported,
      if (supportedMethods != null)
        'supported': supportedMethods!.map((m) => m.toJson()).toList(),
      if (ttl != null) 'ttl': ttl,
      if (cachedEndpoints != null)
        'cached_endpoints': cachedEndpoints!.map((e) => e.toJson()).toList(),
    };
  }
}

class CashuMintPaymentMethod {
  /// e.g. bolt11
  final String method;

  /// e.g. sat
  final String? unit;
  final int? minAmount;
  final int? maxAmount;
  final bool? description;

  /// nut-17
  final List<String>? commands;

  const CashuMintPaymentMethod({
    required this.method,
    this.unit,
    this.minAmount,
    this.maxAmount,
    this.description,
    this.commands,
  });

  factory CashuMintPaymentMethod.fromJson(Map<String, dynamic> json) {
    return CashuMintPaymentMethod(
      method: (json['method'] ?? '') as String,
      unit: json['unit'] as String?,
      minAmount: (json['min_amount'] is num)
          ? (json['min_amount'] as num).toInt()
          : null,
      maxAmount: (json['max_amount'] is num)
          ? (json['max_amount'] as num).toInt()
          : null,
      description:
          json['description'] is bool ? json['description'] as bool : null,
      commands: (json['commands'] is List)
          ? (json['commands'] as List).map((e) => e.toString()).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'method': method,
      if (unit != null) 'unit': unit,
      if (minAmount != null) 'min_amount': minAmount,
      if (maxAmount != null) 'max_amount': maxAmount,
      if (description != null) 'description': description,
      if (commands != null) 'commands': commands,
    };
  }
}

class CashuMintCachedEndpoint {
  /// e.g. post
  final String method;

  /// e.g. /v1/mint/bolt11
  final String path;

  CashuMintCachedEndpoint({required this.method, required this.path});

  factory CashuMintCachedEndpoint.fromJson(Map<String, dynamic> json) {
    return CashuMintCachedEndpoint(
      method: (json['method'] ?? '') as String,
      path: (json['path'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'method': method,
        'path': path,
      };
}
