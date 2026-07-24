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

enum AccountKinds { nip07, nip55, bunker, pubkey, privkey }

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
    // Legacy: NIP-55 external-signer accounts were stored as 'amber' before
    // the rename to the protocol-generic 'nip55'.
    final kindName = json['kind'] == 'amber' ? 'nip55' : json['kind'];
    return NostrAccount(
      kind: AccountKinds.values.firstWhere(
        (e) => e.toString().split('.').last == kindName,
      ),
      pubkey: json['pubkey'],
      signerSeed: json['signerSeed'],
    );
  }
}
