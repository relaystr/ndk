import 'account.dart';
import 'relay_connection_key.dart';

/// Which identity a request may be attributed to on a relay (NIP-42).
///
/// A connection carries at most one identity, chosen when it is opened and
/// immutable for its whole lifetime ([RelayConnectionKey]), so asking for an
/// identity is really asking for a connection.
sealed class RelayAuth {
  const RelayAuth();

  /// Stays on the anonymous connection and never sends AUTH. A relay that
  /// refuses the request without an identity simply does not serve it.
  const factory RelayAuth.never() = RelayAuthNever;

  /// Starts anonymous and moves to a connection bound to [account] only once a
  /// relay refused the request without an identity.
  const factory RelayAuth.allow(Account account) = RelayAuthAllow;

  /// Goes out on a connection bound to [account] from the start; it is never
  /// sent on the anonymous one.
  const factory RelayAuth.require(Account account) = RelayAuthRequire;

  /// identity this may authenticate as, null when it never authenticates
  Account? get account;

  /// stable representation, for logs and for telling two requests apart
  String get canonical;

  /// The connection a request under [auth] must use towards [url].
  ///
  /// Null means no connection can satisfy it and nothing may be sent to that
  /// relay: falling back to the anonymous one is exactly what the caller ruled
  /// out. A null [auth] keeps the historical default.
  static RelayConnectionKey? keyFor(String url, RelayAuth? auth) =>
      switch (auth) {
        RelayAuthRequire(:final account) => account.signer.canSign()
            ? RelayConnectionKey.authenticated(url, account.pubkey)
            : null,
        null ||
        RelayAuthNever() ||
        RelayAuthAllow() =>
          RelayConnectionKey.anonymous(url),
      };

  /// The policy the deprecated `authenticateAs` list stands for: the first
  /// account it names that can sign, and nobody when none can.
  static RelayAuth? fromDeprecatedAccounts(List<Account>? accounts) {
    if (accounts == null || accounts.isEmpty) {
      return null;
    }
    for (final account in accounts) {
      if (account.signer.canSign()) {
        return RelayAuth.allow(account);
      }
    }
    return const RelayAuth.never();
  }
}

/// Never authenticates, see [RelayAuth.never].
class RelayAuthNever extends RelayAuth {
  /// never authenticates
  const RelayAuthNever();

  @override
  Account? get account => null;

  @override
  String get canonical => 'never';

  @override
  bool operator ==(Object other) => other is RelayAuthNever;

  @override
  int get hashCode => canonical.hashCode;

  @override
  String toString() => canonical;
}

/// Authenticates as [account] once refused, see [RelayAuth.allow].
class RelayAuthAllow extends RelayAuth {
  @override
  final Account account;

  /// authenticates as [account] once refused
  const RelayAuthAllow(this.account);

  @override
  String get canonical => 'allow:${account.pubkey}';

  @override
  bool operator ==(Object other) =>
      other is RelayAuthAllow && other.account.pubkey == account.pubkey;

  @override
  int get hashCode => canonical.hashCode;

  @override
  String toString() => canonical;
}

/// Authenticates as [account] from the start, see [RelayAuth.require].
class RelayAuthRequire extends RelayAuth {
  @override
  final Account account;

  /// authenticates as [account] from the start
  const RelayAuthRequire(this.account);

  @override
  String get canonical => 'require:${account.pubkey}';

  @override
  bool operator ==(Object other) =>
      other is RelayAuthRequire && other.account.pubkey == account.pubkey;

  @override
  int get hashCode => canonical.hashCode;

  @override
  String toString() => canonical;
}
