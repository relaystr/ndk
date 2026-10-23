import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

final ndk = Ndk.defaultConfig();
final provider = PlatformPasskeyProvider();

// Call from an explicit user action. Use your app's domain.
Future<PasskeyAccount> createAccount() => ndk.accounts.createPasskey(
  provider: provider,
  rpId: 'example.com',
  rpName: 'Example',
  userName: 'Alice',
);

// Discover a supported tagged passkey; requires access to the same RP.
Future<PasskeyAccount> signIn() =>
    ndk.accounts.loginWithPasskey(provider: provider, rpId: 'example.com');
