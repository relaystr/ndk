class NostrWidgetsAccounts {
  String? loggedAccount;
  List<NostrAccount> accounts;

  NostrWidgetsAccounts({this.loggedAccount, required this.accounts});

  Map<String, dynamic> toJson() {
    return {
      'loggedAccount': loggedAccount,
      'accounts': accounts.map((account) => account.toJson()).toList(),
    };
  }

  factory NostrWidgetsAccounts.fromJson(Map<String, dynamic> json) {
    return NostrWidgetsAccounts(
      loggedAccount: json['loggedAccount'],
      accounts:
          (json['accounts'] as List<dynamic>?)
              ?.map((accountJson) => NostrAccount.fromJson(accountJson))
              .toList() ??
          [],
    );
  }
}

enum AccountKinds { nip07, amber, bunker, pubkey, privkey }

class NostrAccount {
  AccountKinds kind;
  String pubkey;
  String? signerSeed;

  NostrAccount({required this.kind, required this.pubkey, this.signerSeed});

  Map<String, dynamic> toJson() {
    return {
      'kind': kind.toString().split('.').last,
      'pubkey': pubkey,
      'signerSeed': signerSeed,
    };
  }

  factory NostrAccount.fromJson(Map<String, dynamic> json) {
    return NostrAccount(
      kind: AccountKinds.values.firstWhere(
        (e) => e.toString().split('.').last == json['kind'],
      ),
      pubkey: json['pubkey'],
      signerSeed: json['signerSeed'],
    );
  }
}
