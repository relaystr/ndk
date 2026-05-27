# Widgets

All widgets are exported from `package:ndk_flutter/ndk_flutter.dart`.

By default widgets use the currently logged-in account. Override by passing `pubkey` param where available.

## User / Profile widgets

| Widget | File | Description |
| ------ | ---- | ----------- |
| `NBanner` | `widgets/banner/` | User banner image |
| `NPicture` | `widgets/picture/` | User avatar/picture |
| `NName` | `widgets/name/` | User display name |
| `NUserProfile` | `widgets/user_profile/n_user_profile.dart` | Full profile card |

```dart
NBanner(ndk: ndk);
NPicture(ndk: ndk);
NName(ndk: ndk);
NUserProfile(ndk: ndk);

// Override logged-in user:
NPicture(ndk: ndk, pubkey: '<hex-pubkey>');
```

## Auth widgets

| Widget | File | Description |
| ------ | ---- | ----------- |
| `NLogin` | `widgets/login/n_login.dart` | Login flow (nsec, NIP-07, Amber, Bunker) |
| `NSwitchAccount` | `widgets/switch_account/` | Switch between saved accounts |

```dart
NLogin(ndk: ndk, ndkFlutter: ndkFlutter);
NSwitchAccount(ndk: ndk, ndkFlutter: ndkFlutter);
```

## Wallet widgets

| Widget | File | Description |
| ------ | ---- | ----------- |
| `NWallets` | `widgets/wallets/n_wallets.dart` | Full wallet management UI |
| `NWalletCard` | `widgets/wallets/n_wallet_card.dart` | Single wallet card |
| `NWalletCardList` | `widgets/wallets/n_wallet_card_list.dart` | List of wallet cards |
| `NWalletActions` | `widgets/wallets/n_wallet_actions.dart` | Send/receive actions |
| `NPendingTransactions` | `widgets/wallets/n_pending_transactions.dart` | Pending tx list |
| `NRecentTransactions` | `widgets/wallets/n_recent_transactions.dart` | Recent tx list |

```dart
NWallets(ndk: ndk);
NWalletCard(ndk: ndk, wallet: wallet);
NWalletCardList(ndk: ndk);
NWalletActions(ndk: ndk);
```

## Utility widgets

| Widget | File | Description |
| ------ | ---- | ----------- |
| `NPendingRequests` | `widgets/pending_requests/` | Show pending NIP-46 bunker requests |
| `NLocaleSwitcher` | `widgets/locale_switcher/` | Language/locale picker |
